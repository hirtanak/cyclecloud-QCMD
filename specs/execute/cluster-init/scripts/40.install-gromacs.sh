#!/bin/bash
# Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=gromacs
echo "starting 40.install-${SW}.sh"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

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
echo ${CUSER} > /mnt/exports/shared/CUSER
HOMEDIR=/shared/home/${CUSER}
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/QCMD/execute

# get GROMACS version
GROMACS_VERSION=$(jetpack config GROMACS_VERSION)
if [[ ${GROMACS_VERSION} = None ]]; then
   exit 0
fi
CMAKE_VERSION=3.16.4

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

yum install -y openssl-devel libgcrypt-devel
yum remove -y cmake gcc


# build setting
# need "set +" setting for parameter proceesing
set +u
alias gcc=/opt/gcc-9.2.0/bin/gcc
alias c++=/opt/gcc-9.2.0/bin/c++
# PATH settings
export PATH=/opt/gcc-9.2.0/bin/:$PATH
export PATH=${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64/bin:$PATH
export PATH=/opt/openmpi-4.0.2/bin:$PATH
export LD_LIBRARY_PATH=/opt/gcc-9.2.0/lib64:$LD_LIBRARY_PATH
CMD=$(grep "cmake" ${HOMEDIR}/.bashrc | head -1)
if [[ -z ${CMD} ]]; then
   CMD1=$(grep '^export PATH' ${HOMEDIR}/.bashrc | head -1)
   CMD2=${CMD1#export PATH=}
   #echo $CMD2
   if [[ -n ${CMD2} ]]; then
      sed -i -e "s!^export PATH!export PATH=${HOMEDIR}\/apps\/cmake-${CMAKE_VERSION}-Linux-x86_64\/bin:${CMD2}!g" ${HOMEDIR}/.bashrc
   fi
   if [[ -z ${CMD2} ]]; then 
      (echo "export PATH=${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64/bin:$PATH") >> ${HOMEDIR}/.bashrc
   fi
fi
# getting compile setting
VMSKU=`cat /proc/cpuinfo | grep "model name" | head -1 | awk '{print $7}'`
CORES=$(grep cpu.cores /proc/cpuinfo | wc -l) 
PLATFORM=0
case "$CORES" in
  "44" ) PLATFORM=$(echo "-DGMX_SIMD=AVX_512") ;;
esac
echo $PLATFORM
# need "set +" setting for parameter proceesing
set -u

# gromacs build and install
if [[ ! -d ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}/bin ]]; then 
   rm -rf ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}/build && mkdir -p ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}/build
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}/build
   # check cmake version
   if [[ -f ${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64/bin/cmake ]]; then
      cd ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}/build && sudo -u ${CUSER} ${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64/bin/cmake ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION} -DGMX_BUILD_OWN_FFTW=ON -DREGRESSIONTEST_DOWNLOAD=ON -DCMAKE_C_COMPILER="/opt/openmpi-4.0.2/bin/mpicc" -DCMAKE_CXX_COMPILER="/opt/openmpi-4.0.2/bin/mpicxx" -DCMAKE_INSTALL_PREFIX="${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}" ${PLATFORM} -DGMX_MPI=on
      make install
      chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}
   fi
fi

# gromacs ui setting
(echo "source {HOMEDIR}/apps/gromacs-${GROMACS_VERSION}/bin/GMXRC") > /etc/profile.d/gmx.sh
chmod a+x /etc/profile.d/gmx.sh
chown ${CUSER}:${CUSER} /etc/profile.d/gmx.sh

# log file settings
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/40.install-${SW}.sh.out ${HOMEDIR}/
chown ${CUSER}:${CUSER} ${HOMEDIR}/40.install-${SW}.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 40.install-${SW}.sh"
