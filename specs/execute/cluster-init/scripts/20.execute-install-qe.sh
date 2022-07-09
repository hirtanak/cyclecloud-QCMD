#!/bin/bash
# Copyright (c) 2019-2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=qe
echo "starting 20.execute-install-${SW}.sh"

# checking OS version
OS_VERSION=$(cat /etc/redhat-release | cut -d " " -f 4)
CENTOS_VERSION=${OS_VERSION:0:1}
if [[ ${OS_VERSION} = 8.?.???? ]]; then 
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

# get Quantum ESPRESSO version
set +ue
QE_VERSION=$(jetpack config QE_VERSION)
QE_DL_URL1=https://github.com/QEF/q-e/archive/refs/tags/qe-${QE_VERSION}/qe-${QE_VERSION}.tar.gz
QE_DL_URL2=https://github.com/QEF/q-e/releases/download/qe-${QE_VERSION}/qe-${QE_VERSION}-ReleasePack.tgz
CMD=$(ls -d ${HOMEDIR}/*qe-${QE_VERSION})
if [ "$?" -eq 0 ]; then
  QE_DL_URL=${QE_DL_URL1} && echo "using QE_DL_URL1"
else
  if [[ ${QE_VERSION} == "6.7" ]] || [[ ${QE_VERSION} == "6.7.0" ]]; then
    QE_DL_URL2=https://github.com/QEF/q-e/releases/download/qe-${QE_VERSION}.0/qe-${QE_VERSION}-ReleasePack.tgz
    QE_DL_URL=${QE_DL_URL2} && echo "using QE_DL_URL2"
  else
    QE_DL_URL=${QE_DL_URL2} && echo "using QE_DL_URL2"
  fi
fi
QE_DIR=qe-${QE_VERSION}
set -ue

# check build or not
if [[ ${QE_VERSION} = None ]]; then
  exit 0
fi

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# install packages
yum install -y -q openssl-devel libgcrypt-devel gcc gcc-c++

# build setting
### need "set +/-" setting for parameter proceesing
set +eu
jetpack config QE_BUILD_OPTION > /shared/QE_BUILD_OPTION
QE_BUILD_OPTION=$(cat /shared/QE_BUILD_OPTION)
if [ -z "$QE_BUILD_OPTION" ]; then
  QE_BUILD_OPTION=Default
fi
OPENMPI_PATH=$(ls -d /opt/openmpi*)
set -eu

## GCC
set +eu
GCC_PATH=$(ls -d /opt/gcc-*)
GCC_VERSION=920
if [ -z $GCC_PATH ]; then 
   GCC_VERSION=485
   GCC_PATH=/bin/
fi
set -eu

CORES=$(($(grep cpu.cores /proc/cpuinfo | wc -l) + 1))

# Download QuantumESPRESSO installer into tempdir and unpack it into the home directory
if [[ ${QE_VERSION} == "7.0" ]] || [[ ${QE_VERSION} == "6.8" ]] || [[ ${QE_VERSION} == "6.7.0" ]] || [[ ${QE_VERSION} == "6.?" ]]; then 
  if [[ ! -s ${HOMEDIR}/qe-${QE_VERSION}.tar.gz ]]; then
    rm ${HOMEDIR}/qe-${QE_VERSION}.tar.gz && true
  fi
  if [[ ! -f ${HOMEDIR}/qe-${QE_VERSION}.tar.gz ]]; then
    wget -nv ${QE_DL_URL} -O ${HOMEDIR}/qe-${QE_VERSION}.tar.gz
    chown ${CUSER}:${CUSER} ${HOMEDIR}/qe-${QE_VERSION}.tar.gz
    if [[ ! -d ${HOMEDIR}/qe-${QE_VERSION} ]] || [[ ! -d ${HOMEDIR}/q-e-qe-${QE_VERSION} ]]; then 
      rm -rf ${HOMEDIR}/qe-${QE_VERSION} ${HOMEDIR}/q-e-qe-${QE_VERSION} && true
      tar zxfp ${HOMEDIR}/qe-${QE_VERSION}.tar.gz -C ${HOMEDIR}/
      chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DIR}
    fi
  else 
    echo "valid file and no tar.gz download"
    if [[ ! -f "${HOMEDIR}/${QE_DIR}/configure" ]]; then
      tar zxfp ${HOMEDIR}/qe-${QE_VERSION}.tar.gz -C ${HOMEDIR}/
      chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DIR}
    fi
  fi
else 
  if [[ ! -s ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz ]]; then
    rm ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz && true
  fi
  if [[ ! -f ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz ]]; then
    wget -nv ${QE_DL_URL} -O ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz
    chown ${CUSER}:${CUSER} ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz
    if [[ ! -d ${HOMEDIR}/qe-${QE_VERSION} ]] || [[ ! -d ${HOMEDIR}/q-e-qe-${QE_VERSION} ]]; then 
      rm -rf ${HOMEDIR}/qe-${QE_VERSION} ${HOMEDIR}/q-e-qe-${QE_VERSION} && true
      tar zxfp ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz -C ${HOMEDIR}/
      chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DIR}
    fi
  else 
    echo "valid file and no tgz download"
    if [[ ! -f "${HOMEDIR}/${QE_DIR}/configure" ]]; then
      tar zxfp ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz -C ${HOMEDIR}/
      chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DIR}
    fi
  fi
fi

# get qe directory
#QE_DIR_FULL=$(ls -d ${HOMEDIR}/* | grep qe-${QE_VERSION})
#QE_DIR=${QE_DIR_FULL##*/}
echo "QE_DIR: $QE_DIR"

# ディレクトリ決定してからの変更
#chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DIR}

# remove package cmake
yum remove -y -q cmake
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
    rm -rf  ${HOMEDIR}/${CMAKE_VERSION}.tar.gz && true
    wget -nv -q https://github.com/Kitware/CMake/archive/refs/tags/v${CMAKE_VERSION}.tar.gz -O ${HOMEDIR}/${CMAKE_VERSION}.tar.gz
    chown ${CUSER}:${CUSER} ${HOMEDIR}/${CMAKE_VERSION}.tar.gz
    tar zxfp ${HOMEDIR}/${CMAKE_VERSION}.tar.gz -C ${HOMEDIR}
  fi
  chown ${CUSER}:${CUSER} -R ${HOMEDIR}/CMake-${CMAKE_VERSION}
  pushd ${HOMEDIR}/CMake-${CMAKE_VERSION}
  sudo -u ${CUSER} ${HOMEDIR}/CMake-${CMAKE_VERSION}/bootstrap && sudo -u ${CUSER} time /bin/make -j ${CORES} && /bin/make install
  popd
  cp ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake /usr/local/bin/ && true
fi
if [[ ! -f "/usr/local/bin/cmake" ]]; then
  cp ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake /usr/local/bin/
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
git version

# required packages: BLAS LAPACK
yum install -y -q blas lapack lapack-devel
## link
rm -rf /usr/lib64/liblapack.so
ln -s /usr/lib64/liblapack.so.3 /usr/lib64/liblapack.so && true
rm -rf /usr/lib64/libblas.so
ln -s /usr/lib64/libblas.so.3 /usr/lib64/libblas.so && true

# libfortran5: /usr/bin/ld: warning: libgfortran.so.3, needed by /usr/lib64/liblapack.so, may conflict with libgfortran.so.5
yum install -y -q libgfortran5

# gcc fotran
yum remove -y -q gcc gcc-c++ gcc-gfortran
# QE7.0 need gcc 4.9 and higher CMake Error at cmake/GNUFortranCompiler.cmake:3 (message): Requires GCC 4.9 or higher
yum install -y -q centos-release-scl
yum install -y -q devtoolset-9

# NVHPC: QE7.0 reauires NVHPC
NVHPC_VERSION=22.5 #22.5

echo "QE_BUILD_OPTION: $QE_BUILD_OPTION"
case ${QE_BUILD_OPTION} in
  Default )
    echo "CPU build and install...."
    # build and install
    if [[ ! -f ${HOMEDIR}/${QE_DIR}/bin/pw.x ]]; then 
      if [[ -d ${HOMEDIR}/${QE_DIR}/build ]]; then
        rm -rf ${HOMEDIR}/${QE_DIR}/build && true
      fi
      mkdir -p ${HOMEDIR}/${QE_DIR}/build
      chown ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DIR}/build 
      cd ${HOMEDIR}/${QE_DIR}/build && pushd ${HOMEDIR}/${QE_DIR}/build

      # cmake
      ln -s ${HOMEDIR}/CMake-3.23.2/bin/cmake /usr/local/bin/cmake && true

      # fox error
      mv /usr/bin/cmake /usr/bin/cmake.old | exit 0
      ln -s ${HOMEDIR}/CMake-3.23.2/bin/cmake /usr/bin/cmake && true
 
      export CMAKE_ROOT=${HOMEDIR}/CMake-3.23.2/bin/cmake 
      CMAKE_ROOT=${HOMEDIR}/CMake-3.23.2/bin/cmake

      # QE 7.0
      if [[ ${QE_VERSION} == 7.0 ]]; then 
        # 環境変数が必要: Requirement
	/usr/local/bin/cmake -C ${HOMEDIR}/${QE_DIR}/ clean | exit 0
	make -C ${HOMEDIR}/${QE_DIR}/ clean | exit 0
	yum install -y -q blas lapack lapack-devel
        set +u
        #source /opt/rh/devtoolset-9/enable #scl enable devtoolset-9 bash
        #gfortran --version
        #export PATH=${OPENMPI_PATH}/bin:${GCC_PATH}/lib64:$PATH
        #export LD_LIBRARY_PATH=${OPENMPI_PATH}/lib:${GCC_PATH}/lib64:$LD_LIBRARY_PATH
        #export PATH=${OPENMPI_PATH}/bin:/opt/rh/devtoolset-9/root/usr/bin/:$PATH
        #export LD_LIBRARY_PATH=${OPENMPI_PATH}/lib:/opt/rh/devtoolset-9/root/usr/lib64:$LD_LIBRARY_PATH
	rm -rf /usr/bin/gfortran && true
	ln -s /opt/rh/devtoolset-9/root/usr/bin/gfortran /usr/bin/gfortran && true
	rm -rf /bin/gcc && true
        ln -s /opt/rh/devtoolset-9/root/usr/bin/gcc /bin/gcc && true
	set -u

	#---------------------CMAKE-------------------------
        #scl enable devtoolset-9 bash && 
	#F90=/opt/rh/devtoolset-9/root/usr/bin/gfortran MPIF90=/opt/rh/devtoolset-9/root/usr/bin/gfortran \
       	#CC=/opt/rh/devtoolset-9/root/usr/bin/gcc /usr/local/bin/cmake \
	#	${HOMEDIR}/${QE_DIR}/ LAPACK_LIBS='/lib64/liblapack.so' \
	#	BLAS_LIBS='/lib64/libblas.so' FFTW3_LIBS='/opt/amd/lib/libfftw3_mpi.so'
        #/usr/local/bin/cmake \
        #       ${HOMEDIR}/${QE_DIR}/ LAPACK_LIBS='/lib64/liblapack.so' \
        #       BLAS_LIBS='/lib64/libblas.so' FFTW3_LIBS='/opt/amd/lib/libfftw3_mpi.so'

        #---------------------make--------------------------
	F77=/opt/rh/devtoolset-9/root/usr/bin/gfortran ${HOMEDIR}/${QE_DIR}/configure LAPACK_LIBS='/lib64/liblapack.so' \
                BLAS_LIBS='/lib64/libblas.so' FFT_LIBS='/opt/amd/lib/libfftw3_mpi.so'

	make -j ${CORES} -C ${HOMEDIR}/${QE_DIR}/ all #pw cp ph
	

      # QE 6.8
      elif [[ ${QE_VERSION} == 6.8 ]]; then
        # 環境変数が必要: Requirement
        /usr/local/bin/cmake -C ${HOMEDIR}/${QE_DIR}/ clean | exit 0
        make -C ${HOMEDIR}/${QE_DIR}/ clean | exit 0
        yum install -y -q blas lapack lapack-devel
        set +u
        rm -rf /usr/bin/gfortran && true
        ln -s /opt/rh/devtoolset-9/root/usr/bin/gfortran /usr/bin/gfortran && true
        rm -rf /bin/gcc && true
        ln -s /opt/rh/devtoolset-9/root/usr/bin/gcc /bin/gcc && true
        set -u

        #---------------------CMAKE-------------------------
        /usr/local/bin/cmake ${HOMEDIR}/${QE_DIR}/ LAPACK_LIBS='/lib64/liblapack.so' \
                BLAS_LIBS='/lib64/libblas.so' FFT_LIBS='/opt/amd/lib/libfftw3_mpi.so'

	make -j ${CORES} -C ${HOMEDIR}/${QE_DIR}/ all #pw cp ph


      else
        if [[ ${QE_VERSION} = 6.? ]]; then
          # 環境変数が必要: Requirement
          /usr/local/bin/cmake -C ${HOMEDIR}/${QE_DIR}/ clean | exit 0
          make -C ${HOMEDIR}/${QE_DIR}/ clean | exit 0
          yum install -y -q blas lapack lapack-devel
          set +u
          rm -rf /usr/bin/gfortran && true
          ln -s /opt/rh/devtoolset-9/root/usr/bin/gfortran /usr/bin/gfortran && true
          rm -rf /bin/gcc && true
          ln -s /opt/rh/devtoolset-9/root/usr/bin/gcc /bin/gcc && true
          set -u

          #---------------------CMAKE-------------------------
          /usr/local/bin/cmake ${HOMEDIR}/${QE_DIR}/ LAPACK_LIBS='/lib64/liblapack.so' \
		  BLAS_LIBS='/lib64/libblas.so' FFT_LIBS='/opt/amd/lib/libfftw3_mpi.so'

          make -j ${CORES} -C ${HOMEDIR}/${QE_DIR}/ all #pw cp ph
	
	fi
      fi
    fi
    popd
    ;;

  GPU )
    echo "Building GPU compile"
    CUDA_HOME=/usr/local/cuda
    
    if [[ ! -f ${HOMEDIR}/${QE_DIR}/bin/pw-gpu.x ]]; then
      if [[ -f ${HOMEDIR}/${QE_DIR}/build ]]; then
        rm -rf ${HOMEDIR}/${QE_DIR}/build && true
      fi
      mkdir -p ${HOMEDIR}/${QE_DIR}/build
      cd ${HOMEDIR}/${QE_DIR}/build/
      pushd ${HOMEDIR}/${QE_DIR}/build
     
      yum install -y -q nvidia-driver-latest-dkms
      yum install -y -q cuda-11-7
      yum install -y -q nvhpc-22.5

        # QE 6.x with GPU
        if [[ ${QE_VERSION} == 6.? ]]; then
          make clean | exit 0
          #---------------------make--------------------------
          # configure
          #./configure --enable-signals --enable-openmp --with-scalapack=no --with-cuda=$CUDA_HOME --with-cuda-cc=70 --with-cuda-runtime=10.1
          #sed -i -e 's%-D__MPI%-D__MPI -D__GPU_MPI%' make.in

          # normal settings:  --with-cuda-cc=70
          #${HOMEDIR}/${QE_DIR}/configure F90=/opt/${GCC_PATH}/bin/gfortran F77=/opt/${GCC_PATH}/bin/gfortran CC=/opt/${GCC_PATH}/bin/gcc CXX=/opt/${GCC_PATH}/bin/gcc-c++ MPIF90=/opt/${OPENMPI_PATH}/bin/mpif90 --enable-openmp --with-cuda=$CUDA_HOME --with-cuda-runtime=11.6
          #--with-internal-blas --with-internal-lapack
          #sed -i -e 's%-D__MPI%-D__MPI -D__GPU_MPI%' ${HOMEDIR}/${QE_DIR}/EPW/src/make.inc
 
          ${HOMEDIR}/${QE_DIR}/configure --enable-parallel --with-cuda=/usr/local/cuda --with-cuda-cc=70 \
            --with-cuda-runtime=11.7 --with-scalapack=no
	  make -j ${CORES} -C ${HOMEDIR}/${QE_DIR}/ all # pw cp ph

          #---------------------CMAKE-------------------------
	  #/usr/local/bin/cmake ${HOMEDIR}/${QE_DIR}/cmake -DCMAKE_C_COMPILER=/opt/${OPENMPI_PATH}/bin/mpicc -DCMAKE_Fortran_COMPILER=/opt/${OPENMPI_PATH}/bin/mpif90 --enable-openmp --with-scalapack=no --with-cuda=$CUDA_HOME --with-cuda-cc=80 --with-cuda-runtime=11.6
	  #/usr/local/bin/cmake ${HOMEDIR}/${QE_DIR}/ -DCMAKE_C_COMPILER=/opt/${GCC_PATH}/bin/gcc -DQE_LAPACK_INTERNAL=ON -DQE_ENABLE_CUDA=on -DQE_ENABLE_MPI_GPU_AWARE=on -DQE_LAPACK_INTERNAL=ON
          # -DCMAKE_Fortran_COMPILER=/opt/${GCC_PATH}/bin/gfortran

          # GPUバイナリファイル処理
          #mkdir -p ${HOMEDIR}/${QE_DIR}/bin/
          touch ${HOMEDIR}/${QE_DIR}/bin/GPU-COMPILED
          cp ${HOMEDIR}/${QE_DIR}/build/pw.x ${HOMEDIR}/${QE_DIR}/bin/pw-gpu.x && true
          cp ${HOMEDIR}/${QE_DIR}/build/*.x ${HOMEDIR}/${QE_DIR}/bin/ && true
        fi

	# QE 7.x with GPU
        if [[ ${QE_VERSION} == 7.0 ]]; then
          # current 2022/7/1 | QE7.0, NVHPC 22.5, CMAKE 3.23.4
	  source /etc/profile.d/modules.sh
	  # requires cyclecloud environement
          module load /opt/nvidia/hpc_sdk/modulefiles/nvhpc/${NVHPC_VERSION}
          /usr/local/cuda/bin/nvcc --version

          export CC="/opt/nvidia/hpc_sdk/Linux_x86_64/${NVHPC_VERSION}/compilers/bin/nvc"
          export CXX="/opt/nvidia/hpc_sdk/Linux_x86_64/${NVHPC_VERSION}/compilers/bin/nvc++"
          export LDFLAGS="-L/opt/nvidia/hpc_sdk/Linux_x86_64/${NVHPC_VERSION}/compilers/lib"
          export CPPFLAGS="-I/opt/nvidia/hpc_sdk/Linux_x86_64/${NVHPC_VERSION}/compilers/include"

          NVHPC_PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/${NVHPC_VERSION}/compilers/bin/

	  cd ${HOMEDIR}/${QE_DIR}/build/ && pushd ${HOMEDIR}/${QE_DIR}/build/
	  #---------------------make-------------------------------
	  make clean | exit 0
	  
	  # 2022 / 7 / 1 : ok 
	  #LANG=C ${HOMEDIR}/${QE_DIR}/configure --enable-openmp --with-cuda=/usr/local/cuda --with-cuda-cc=70 --with-cuda-runtime=11.7 --with-scalapack=no 
          ${HOMEDIR}/${QE_DIR}/configure --enable-parallel --with-cuda=/usr/local/cuda --with-cuda-cc=70 \ 
            --with-cuda-runtime=11.7 --with-scalapack=no --enable-openacc
	  make -j ${CORES} -C ${HOMEDIR}/${QE_DIR}/ all # pw cp ph
	  #make install

          #---------------------CMAKE------------------------------
          # QE7.0, NVHPC 22.5, CMAKE 3.24.0rc2の時点ではエラーが修正できず。make利用へ再変更 
          # set +u
          # export PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/22.5/compilers/bin:/opt/${OPENMPI_PATH}/bin:${GCC_PATH}/lib64:$PATH
          # export LD_LIBRARY_PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/22.5/compilers/lib:/opt/${OPENMPI_PATH}/lib:${GCC_PATH}/lib64:$LD_LIBRARY_PATH
          # set -u
          #yum-config-manager --add-repo https://developer.download.nvidia.com/hpc-sdk/rhel/nvhpc.repo
          #yum install -y -q nvhpc-22.2 #nvhpc-cuda-multi-22.2

          #/usr/local/bin/cmake ${HOMEDIR}/${QE_DIR}/ -DQE_LAPACK_INTERNAL=ON -DQE_ENABLE_CUDA=on -DQE_ENABLE_MPI_GPU_AWARE=on -DCMAKE_Fortran_COMPILER_ID=/opt/nvidia/hpc_sdk/Linux_x86_64/22.5/compilers/bin/nvfortran
	  #yum install -y -q lapack-devel
	  #yum remove -y -q openblas*
	  #set +u
	  # /usr/local/bin/cmake $cmake --build ${HOMEDIR}/${QE_DIR}/ --target clean && exit 0
	  #/usr/local/bin/cmake ${HOMEDIR}/${QE_DIR}/ -DQE_CPP_FULL_PATH:FILEPATH=${NVHPC_PATH}/nvc++ -DCMAKE_C_COMPILER=${NVHPC_PATH}/nvc -DCMAKE_Fortran_COMPILER=${NVHPC_PATH}/nvfortran -DQE_ENABLE_MPI=OFF -DQE_ENABLE_OPENMP=OFF -DQE_ENABLE_CUDA=ON -DQE_FFTW_VENDOR=Internal -DBLAS_LIBRARIES='/lib64/libblas64_.so' -DLAPACK_LIBS='/lib64/liblapack.so' 
	  #BLAS_LIBS='/lib64/libopenblas64_.so' 
	  #LAPACK_LIBS='/lib64/liblapack.so' 
          #make -j ${CORES} pw 
          #make pw ph cp -j ${CORES}
	  #set -u

	  # バリナリ処理: /bin/pw.xが作成される
	  touch ${HOMEDIR}/${QE_DIR}/bin/GPU-COMPILED
	  cp ${HOMEDIR}/${QE_DIR}/bin/pw.x ${HOMEDIR}/${QE_DIR}/bin/pw-gpu.x
        fi
    fi
    popd    
    ;;
esac

# QuantumESPRESSO パーミッション処理
CMD=$(ls -al ${HOMEDIR} | sed -n 2p | cut -d " " -f 3)
if [ $CMD != ${CUSER} ]; then 
  chown ${CUSER}:${CUSER} -R ${HOMEDIR}/${QE_DIR}
fi

# .bashrc settings
set +u
CMD2=$(grep ${QE_DIR} ${HOMEDIR}/.bashrc | head -1) | exit 0
if [[ -n ${CMD2} ]]; then
  (echo "export PATH=${HOMEDIR}/${QE_DIR}/bin:$PATH") >> ${HOMEDIR}/.bashrc
fi
set -u

# local file settings
if [[ ! -f ${HOMEDIR}/qerun.sh ]]; then
  cp ${CYCLECLOUD_SPEC_PATH}/files/qerun.sh ${HOMEDIR}/
  chmod +x ${HOMEDIR}/qerun.sh
  chown ${CUSER}:${CUSER} ${HOMEDIR}/qerun.sh
fi
CMD3=$(ls -al ${HOMEDIR}/${QE_DIR} | sed -n 2p | cut -d " " -f 3)
if [[  -n ${CMD3} ]]; then
  chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DIR}
fi

# log file settings
FILEDATE=$(date +"%Y%m%d%h%m")
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/20.execute-install-${SW}.sh.out \
	${HOMEDIR}/logs/20.execute-install-${SW}.sh.$FILEDATE.out
chown ${CUSER}:${CUSER} ${HOMEDIR}/logs/20.execute-install-${SW}.sh.$FILEDATE.out

#clean up
#popd
rm -rf $tmpdir
scl disable devtoolset-9 bash

echo "end of 20.execute-install-${SW}.sh"
