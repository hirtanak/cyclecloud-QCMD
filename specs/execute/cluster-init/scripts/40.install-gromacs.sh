#!/bin/bash
# Copyright (c) 2020,2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=gromacs
echo "starting 40.install-${SW}.sh"

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

# get GROMACS version
GROMACS_VERSION=$(jetpack config GROMACS_VERSION)
if [[ ${GROMACS_VERSION} = None ]]; then
  exit 0
fi

OPENMPI_PATH=$(ls -d /opt/openmpi*)

# cmake version
set +eu
CMAKE_VERSION=$(cat /shared/CMAKE_VERSION)
if [ -z $CMAKE_VERSION ]; then
  CMAKE_VERSION=3.21.4
fi
set -eu

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

yum install -y -q openssl-devel libgcrypt-devel

## GCC
set +eu
GCC_PATH=$(ls -d /opt/gcc-*)
GCC_VERSION=920
if [ -z $GCC_PATH ]; then
   GCC_VERSION=485
   GCC_PATH=/bin/
fi
set -eu

# getting compile setting
set +u
VMSKU=`cat /proc/cpuinfo | grep "model name" | head -1 | awk '{print $6}'`
CORES=$(($(grep cpu.cores /proc/cpuinfo | wc -l) + 1))
declare -l PLATFORM
case "$CORES" in
  "44","45" ) PLATFORM=$(echo "-DGMX_SIMD=AVX_512") ;;
esac
echo "PLATFORM: $PLATFORM"
set -u

# Don't run if we've already expanded the GROMACS tarball. Download GROMACS
if [[ ! -f ${HOMEDIR}/gromacs-${GROMACS_VERSION}.tar.gz ]]; then
   wget --no-check-certificate -nv -q https://ftp.gromacs.org/gromacs/gromacs-${GROMACS_VERSION}.tar.gz \
           -O ${HOMEDIR}/gromacs-${GROMACS_VERSION}.tar.gz
   chown ${CUSER}:${CUSER} ${HOMEDIR}/gromacs-${GROMACS_VERSION}.tar.gz
fi
if [[ ! -f ${HOMEDIR}/gromacs-${GROMACS_VERSION}/src/CMakeLists.txt ]]; then
   tar zxfp ${HOMEDIR}/gromacs-${GROMACS_VERSION}.tar.gz -C ${HOMEDIR}/
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/gromacs-${GROMACS_VERSION}
fi

# gromacs build and install
if [[ ! -d ${HOMEDIR}/gromacs-${GROMACS_VERSION}/bin ]]; then 
  rm -rf ${HOMEDIR}/gromacs-${GROMACS_VERSION}/build && mkdir -p ${HOMEDIR}/gromacs-${GROMACS_VERSION}/build
  chown ${CUSER}:${CUSER} ${HOMEDIR}/gromacs-${GROMACS_VERSION}/build
  # check cmake version
  if [[ ! -f  ${HOMEDIR}/gromacs-${GROMACS_VERSION}/bin/gmx_mpi ]]; then
    ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake -C ${HOMEDIR}/gromacs-${GROMACS_VERSION}/ clean | exit 0
    dnf install -y -q sphinx 
    dnf module install -y -q python38
    # Intel Platform
    set +u
    if [[ -n $PLATFORM ]]; then
      cd ${HOMEDIR}/gromacs-${GROMACS_VERSION}/build && sudo -u ${CUSER} time ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake \
	      ${HOMEDIR}/gromacs-${GROMACS_VERSION} -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON \
	      -DCMAKE_C_COMPILER="${OPENMPI_PATH}/bin/mpicc" -DCMAKE_CXX_COMPILER="${OPENMPI_PATH}/bin/mpicxx" \
	      -DCAMKE_Fortran_COMPILER="${OPENMPI_PATH}/bin/gfortran" -DCMAKE_INSTALL_PREFIX="${HOMEDIR}/gromacs-${GROMACS_VERSION}" \
	      -DGMX_MPI=on ${PLATFORM} -DMPI_HOME="${OPENMPI_PATH}" -DMPIEXEC_EXECUTABLE="${OPENMPI_PATH}/bin/mpiexec"
    else
      # AMD platform
      cd ${HOMEDIR}/gromacs-${GROMACS_VERSION}/build && sudo -u ${CUSER} time ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake \
              ${HOMEDIR}/gromacs-${GROMACS_VERSION} -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON \
              -DCMAKE_C_COMPILER="${OPENMPI_PATH}/bin/mpicc" -DCMAKE_CXX_COMPILER="${OPENMPI_PATH}/bin/mpicxx" \
              -DCAMKE_Fortran_COMPILER="${OPENMPI_PATH}/bin/gfortran" -DCMAKE_INSTALL_PREFIX="${HOMEDIR}/gromacs-${GROMACS_VERSION}" \
	      -DGMX_MPI=on -DMPI_HOME="${OPENMPI_PATH}" -DMPIEXEC_EXECUTABLE="${OPENMPI_PATH}/bin/mpiexec"
    fi
    set -u
    /bin/make -j $CORES install
    chown -R ${CUSER}:${CUSER} ${HOMEDIR}/gromacs-${GROMACS_VERSION}
  fi
fi

# gromacs ui setting
(echo "source {HOMEDIR}/gromacs-${GROMACS_VERSION}/bin/GMXRC") > /etc/profile.d/gmx.sh
chmod +x /etc/profile.d/gmx.sh
chown ${CUSER}:${CUSER} /etc/profile.d/gmx.sh

# log file settings
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/40.install-${SW}.sh.out ${HOMEDIR}/logs/
chown ${CUSER}:${CUSER} ${HOMEDIR}/logs/40.install-${SW}.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 40.install-${SW}.sh"
