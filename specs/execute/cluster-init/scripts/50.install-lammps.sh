#!/bin/bash
# Copyright (c) 2019-2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=lammps
echo "starting 50.install-${SW}.sh"

# checking OS version
OS_VERSION=$(cat /etc/redhat-release | cut -d " " -f 4)
CENTOS_VERSION=${OS_VERSION:0:1}
if [[ ${OS_VERSION} = 8.?.???? ]]; then
  exit 0
fi

# run this script or not
LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
if [[ ${LAMMPS_VERSION} = None ]]; then
  exit 0
fi

# disabling selinux
echo "disabling selinux"
setenforce 0
sed -i -e "s/^SELINUX=enforcing$/SELINUX=disabled/g" /etc/selinux/config

CUSER=$(grep "Added user" /opt/cycle/jetpack/logs/jetpackd.log | awk '{print $6}')
CUSER=${CUSER//\'/}
CUSER=${CUSER//\`/}
# After CycleCloud 7.9 and later 
if [[ -z $CUSER ]]; then 
  CUSER=$(grep "Added user" /opt/cycle/jetpack/logs/initialize.log | awk '{print $6}' | head -1)
  CUSER=${CUSER//\`/}
fi
echo ${CUSER} > /shared/CUSER
HOMEDIR=/shared/home/${CUSER}
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/QCMD/execute

# check kokkos requirement
set +eu
jetpack config LAMMPS_VERSION > /shared/KOKKOS_TMP
grep kokkos /shared/KOKKOS_TMP > /shared/KOKKOS && true
rm /shared/KOKKOS_TMP && true
KOKKOS=$(cat /shared/KOKKOS)

# check intel build requirement
set +eu
jetpack config LAMMPS_VERSION > /shared/IMPI_TMP
grep impi /shared/IMPI_TMP > /shared/IMPI && true
rm /shared/IMPI_TMP && true
IMPI=$(cat /shared/IMPI)

if [ -n ${KOKKOS} ]; then
  # KOKKOS 使っている場合
  echo $KOKKOS > /shared/KOKKOS
  LAMMPS_VERSION_TMP=$(jetpack config LAMMPS_VERSION)
  LAMMPS_VERSION=${LAMMPS_VERSION_TMP%_kokkos*}
else
  # get LAMMPS version
  LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
fi
LAMMPS_DL_URL=https://github.com/lammps/lammps/archive/${LAMMPS_VERSION}.tar.gz
LAMMPS_DIR=lammps-${LAMMPS_VERSION}
set -eu

CORES=$(($(grep cpu.cores /proc/cpuinfo | wc -l) + 1))

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# Download LAMMPS
if [[ ! -f ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz ]]; then
  wget -nv https://github.com/lammps/lammps/archive/${LAMMPS_VERSION}.tar.gz -O ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz
  chown ${CUSER}:${CUSER} ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz
fi
if [[ ! -d ${HOMEDIR}/${LAMMPS_DIR} ]]; then
  tar zxfp ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz -C ${HOMEDIR}
  chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${LAMMPS_DIR}
fi

# build setting
## OPENMPI
### need "set +/-" setting for parameter proceesing
set +eu
jetpack config LAMMPS_BUILD_OPTION > /shared/GPU
LAMMPS_BUILD_OPTION=$(cat /shared/GPU)
if [ -z "$LAMMPS_BUILD_OPTION" ]; then
  LAMMPS_BUILD_OPTION=Default
fi
OPENMPI_PATH=$(ls /opt/ | grep openmpi)
export PATH=/opt/${OPENMPI_PATH}/bin:${HOMEDIR}/${LAMMPS_DIR}/src:$PATH
export LD_LIBRARY_PATH=/opt/${OPENMPI_PATH}/lib:$LD_LIBRARY_PATH
set -eu

## GCC
GCC_PATH=$(ls /opt/ | grep ^gcc-)
GCC_VERSION=920
if [ -z $GCC_PATH ]; then
   GCC_VERSION=485
fi

# remove package cmake
yum remove -y cmake
# cmake version
set +eu
#echo $CMAKE_VERSION > /shared/CMAKE_VERSION
CMAKE_VERSION=$(cat /shared/CMAKE_VERSION)
if [ -z $CMAKE_VERSION ]; then
  CMAKE_VERSION=3.21.4
fi
set -eu

# CMake build
if [[ ! -f ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake ]]; then
  if [[ ! -d ${HOMEDIR}/CMake-${CMAKE_VERSION} ]]; then
    rm -rf  ${HOMEDIR}/${CMAKE_VERSION}.tar.gz | exit 0
    wget -nv -q https://github.com/Kitware/CMake/archive/refs/tags/v${CMAKE_VERSION}.tar.gz -O ${HOMEDIR}/${CMAKE_VERSION}.tar.gz
    chown ${CUSER}:${CUSER} ${HOMEDIR}/${CMAKE_VERSION}.tar.gz
    tar zxfp ${HOMEDIR}/${CMAKE_VERSION}.tar.gz -C ${HOMEDIR} 
  fi 
  chown ${CUSER}:${CUSER} -R ${HOMEDIR}/CMake-${CMAKE_VERSION} 
  yum -y -q install openssl-devel
  pushd ${HOMEDIR}/CMake-${CMAKE_VERSION}
  sudo -u ${CUSER} ${HOMEDIR}/CMake-${CMAKE_VERSION}/bootstrap && sudo -u ${CUSER} /bin/make -j ${CORES} && /bin/make install
  popd
  mkdir -p /usr/local/CMake-${CMAKE_VERSION}/bin
  cp ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake /usr/local/CMake-${CMAKE_VERSION}/bin/ && true
  chown ${CUSER}:${CUSER} -R /usr/local/CMake-${CMAKE_VERSION} && true
fi

# リンカ作成
ln -s ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake /usr/local/bin/cmake && true

# required packages: FFTW fftw3.hのために fftw fftw-devel も必要
yum --enablerepo=epel,rpmfusion-free-updates install -y -q ffmpeg ffmpeg-devel fftw fftw-devel fftw3

# git
yum remove  -y -q git
yum install -y -q https://repo.ius.io/ius-release-el7.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && true
yum install -y -q git224 --enablerepo=ius --disablerepo=base,epel,extras,updates || \
	yum install -y -q git236 --enablerepo=ius --disablerepo=base,epel,extras,updates
yum install -y -q gcc gcc-c++

# checking build options
case ${LAMMPS_BUILD_OPTION} in 
  Default )
    set +u
    # 追加 KOKKOS 変数再読み込み
    KOKKOS=$(cat /shared/KOKKOS)
    echo "KOKKOS: $KOKKOS"
    if [ -z ${KOKKOS} ]; then      
      # check lmp build and installed
      if [[ ! -f ${HOMEDIR}/${LAMMPS_DIR}/bin/lmp ]]; then
        echo "LAMMPS normal building...."
        rm -rf ${HOMEDIR}/${LAMMPS_DIR}/build | exit 0
        mkdir -p ${HOMEDIR}/${LAMMPS_DIR}/build | exit 0
        cd ${HOMEDIR}/${LAMMPS_DIR}/build
        pushd ${HOMEDIR}/${LAMMPS_DIR}/build
        if [[ -f ${HOMEDIR}/${LAMMPS_DIR}/build/*.txt ]]; then
          /bin/make clean && true
        fi
        # default
        #/usr/local/bin/cmake ${HOMEDIR}/${LAMMPS_DIR}/cmake -DBUILD_MPI=on -DBUILD_OMP=on \
	#	-DCMAKE_C_COMPILER=/opt/${OPENMPI_PATH}/bin/mpicc -DCMAKE_CXX_COMPILER=/opt/${OPENMPI_PATH}/bin/mpicxx \
	#-DCMAKE_Fortran_COMPILER=mpif90 -DPKG_MOLECULE=on -DPKG_KSPACE=on -DMULTITHREADED_BUILD=${CORES}
        # custom
        #/usr/local/bin/cmake ${HOMEDIR}/${LAMMPS_DIR}/cmake -DBUILD_MPI=on -DMPI_CXX_COMPILER=/opt/${OPENMPI_PATH}/bin/mpicxx \
	#	-DPKG_MOLECULE=on -DPKG_KSPACE=on -DPKG_REAXFF=on -DMULTITHREADED_BUILD=${CORES}
        #/usr/local/bin/cmake --build ${HOMEDIR}/${LAMMPS_DIR}/build
        
	# custom #2
        /usr/local/bin/cmake ${HOMEDIR}/${LAMMPS_DIR}/cmake -DBUILD_MPI=on -DMPI_CXX_COMPILER=/opt/${OPENMPI_PATH}/bin/mpicxx \
		-DPKG_MOLECULE=on -DPKG_KSPACE=on -DPKG_REAXFF=on -DPKG_MANYBODY=on -DPKG_MEAM=on -DPKG_MC=on -DPKG_QMMM=on 
        make -j ${CORES}	
        mkdir -p ${HOMEDIR}/${LAMMPS_DIR}/bin 
        cp ${HOMEDIR}/${LAMMPS_DIR}/build/lmp ${HOMEDIR}/${LAMMPS_DIR}/bin/
      fi
      # 追加 IMPI 変数再読み込み
      IMPI=$(cat /shared/IMPI)
      echo "IMPI: $IMPI"
      if [ -z ${IMPI} ]; then
        echo "building impi settings...."
	IMPI_PATH=/opt/intel/impi/2018.4.274/bin64
	MPI_ROOT=$IMPI_PATH
        # Download LAMMPS
        if [[ ! -d ${HOMEDIR}/${LAMMPS_DIR}-intel ]]; then
          tar zxfp ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz -C /tmp/
          mv /tmp/${LAMMPS_DIR} ${HOMEDIR}/${LAMMPS_DIR}-intel
          chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${LAMMPS_DIR}-intel
        fi

        # check lmp-intel -f -e does not work
      	if [[ ! -c ${HOMEDIR}/${LAMMPS_DIR}-intel/bin/lmp-intel ]]; then
          # intel mpi build
          rm -rf ${HOMEDIR}/${LAMMPS_DIR}-intel/build && true
          mkdir -p ${HOMEDIR}/${LAMMPS_DIR}-intel/build && true
          chown ${CUSER}:${CUSER} ${HOMEDIR}/${LAMMPS_DIR}-intel/build
	  # build
          pushd ${HOMEDIR}/${LAMMPS_DIR}-intel/build

          time dnf install -y -q intel-basekit
          time dnf install -y -q intel-hpckit

	  time ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake ${HOMEDIR}/${LAMMPS_DIR}-intel/cmake/ -DCMAKE_C_COMPILER=${MPI_ROOT}/icpc \
		  -DCMAKE_CXX_COMPILER=${MPI_ROOT}/icpx -DBUILD_MPI=on -DBUILD_OMP=on -DPKG_MOLECULE=on \
		  -DPKG_KSPACE=on -DPKG_REAXFF=on
          time make -j ${CORES}
          mkdir -p ${HOMEDIR}/${LAMMPS_DIR}-intel/bin
          cp ${HOMEDIR}/${LAMMPS_DIR}-intel/build/lmp ${HOMEDIR}/${LAMMPS_DIR}-intel/bin/lmp-intel
	  chown ${CUSER}:${CUSER} -R ${HOMEDIR}/${LAMMPS_DIR}-intel/bin
          popd 
        fi
      fi 
    else
      # check kokkos custom  build and installed
      if [[ ! -f ${HOMEDIR}/${LAMMPS_DIR}/bin/lmp-kokkos ]]; then
        echo "LAMMPS kokkos building...."
        time ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake ../cmake -DCMAKE_BUILD_TYPE=Debug -DPKG_KOKKOS=on \
		-DKokkos_ENABLE_OPENMP=yes -DBUILD_MPI=on -DBUILD_OMP=on -DCMAKE_CXX_COMPILER=/opt/${GCC_PATH}/bin/g++ \
		-DMPI_CXX_COMPILER=/opt/${OPENMPI_PATH}/bin/mpicxx -DPKG_MOLECULE=on -DPKG_KSPACE=on -DPKG_REAXFF=on \
		-DPKG_MANYBODY=on -DPKG_MEAM=on -DPKG_MC=on -DPKG_QMMM=on -DMULTITHREADED_BUILD=${CORES}
        /usr/local/bin/cmake --build ${HOMEDIR}/${LAMMPS_DIR}/build
        mkdir -p ${HOMEDIR}/${LAMMPS_DIR}/bin && true
        cp ${HOMEDIR}/${LAMMPS_DIR}/build/lmp ${HOMEDIR}/${LAMMPS_DIR}/bin/lmp-kokkos
      fi
      # gcc
      if [[ -f ${HOMEDIR}/${LAMMPS_DIR}/bin/lmp-kokkos ]]; then
        rm /usr/lib64/libstdc++.so.6
        cp /opt/gcc-9.2.0/lib64/libstdc++.so.6.0.27 /usr/lib64/
        ln -s /usr/lib64/libstdc++.so.6.0.27 /usr/lib64/libstdc++.so.6
      fi
    fi
    set -u
    
    popd 
    ;;

  GPU )
    if [[ ! -f ${HOMEDIR}/${LAMMPS_DIR}/bin/lmp-gpu ]]; then
      rm -rf ${HOMEDIR}/${LAMMPS_DIR}/build && true
      mkdir -p ${HOMEDIR}/${LAMMPS_DIR}/build && true
      cd ${HOMEDIR}/${LAMMPS_DIR}/build
      pushd ${HOMEDIR}/${LAMMPS_DIR}/build
      if [[ -f ${HOMEDIR}/${LAMMPS_DIR}/build/*.txt ]]; then
        /bin/make clean && true
      fi

      # build
      /usr/local/bin/cmake ../cmake -DBUILD_MPI=on -DBUILD_OMP=on -DCMAKE_CXX_COMPILER=/bin/g++ \
	      -DMPI_CXX_COMPILER=/opt/${OPENMPI_PATH}/bin/mpicxx -DPKG_MOLECULE=on -DPKG_KSPACE=on -DPKG_REAXFF=on \
	      -DPKG_MANYBODY=on -DPKG_MEAM=on -DPKG_MC=on -DPKG_QMMM=on -DPKG_GPU=on -DGPU_API=cuda -DGPU_ARCH=sm_80 \
	      -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs -DBIN2C=/usr/local/cuda-11.6/bin/bin2c
      /usr/local/bin/cmake --build ${HOMEDIR}/${LAMMPS_DIR}/build
      mkdir -p ${HOMEDIR}/${LAMMPS_DIR}/bin | exit 0
      cp ${HOMEDIR}/${LAMMPS_DIR}/build/lmp ${HOMEDIR}/${LAMMPS_DIR}/bin/lmp-gpu && true
      popd
      chown ${CUSER}:${CUSER} -R ${HOMEDIR}/${LAMMPS_DIR}/build
    else
      echo "It has already GPU built and installed."
    fi
  ;;
esac

# copy test script 
if [[ ! -f  ${HOMEDIR}/lammpsrun.sh ]]; then
  cp ${CYCLECLOUD_SPEC_PATH}/files/lammpsrun.sh ${HOMEDIR}/
  chown ${CUSER}:${CUSER} ${HOMEDIR}/lammpsrun.sh 
  chmod +x ${HOMEDIR}/lammpsrun.sh
fi

# local file settings
CMD=$(ls -al ${HOMEDIR}/${LAMMPS_DIR} | sed -n 2p | cut -d " " -f 3)
if [[ -n ${CMD} ]]; then
  chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${LAMMPS_DIR}
fi

# log file settings
mkdir -p ${HOMEDIR}/logs
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/50.install-${SW}.sh.out ${HOMEDIR}/logs/
chown ${CUSER}:${CUSER} ${HOMEDIR}/logs/50.install-${SW}.sh.out

#clean up
#popd
rm -rf $tmpdir


echo "end of 50.install-${SW}.sh"
