#!/bin/bash
# Copyright (c) 2019-2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=cmake
echo "starting 12.${SW}.sh"

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
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/QCMD/server

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

## GCC
GCC_PATH=$(ls /opt/ | grep ^gcc-)
GCC_VERSION=920
if [ -z $GCC_PATH ]; then 
   GCC_VERSION=485
fi

# CentOS8.xでの必須パッケージ
# checking OS version
OS_VERSION=$(cat /etc/redhat-release | cut -d " " -f 4)
CENTOS_VERSION=${OS_VERSION:0:1}
if [[ ${OS_VERSION} = 8.?.???? ]]; then
  dnf install -y -q openssl openssl-devel #openssh  
fi

# remove package cmake
yum remove -y -q cmake
# cmake version
CMAKE_VERSION=3.23.2 #3.21.4
echo $CMAKE_VERSION > /shared/CMAKE_VERSION
CMAKE_VERSION=$(cat /shared/CMAKE_VERSION)

CORES=3

# CMake build
if [[ ! -f ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake ]]; then
  if [[ ! -d ${HOMEDIR}/CMake-${CMAKE_VERSION} ]]; then
    rm -rf  ${HOMEDIR}/${CMAKE_VERSION}.tar.gz && true
    wget -nv -q https://github.com/Kitware/CMake/archive/refs/tags/v${CMAKE_VERSION}.tar.gz -O ${HOMEDIR}/${CMAKE_VERSION}.tar.gz
    chown ${CUSER}:${CUSER} ${HOMEDIR}/${CMAKE_VERSION}.tar.gz
    tar zxfp ${HOMEDIR}/${CMAKE_VERSION}.tar.gz -C ${HOMEDIR}/
  fi
  chown ${CUSER}:${CUSER} -R ${HOMEDIR}/CMake-${CMAKE_VERSION}
  pushd ${HOMEDIR}/CMake-${CMAKE_VERSION}
  sudo -u ${CUSER} ${HOMEDIR}/CMake-${CMAKE_VERSION}/bootstrap && sudo -u ${CUSER} time /bin/make -j ${CORES} && /bin/make install
  popd
  cp ${HOMEDIR}/CMake-${CMAKE_VERSION}/bin/cmake /usr/local/bin/ && true
fi

#clean up
popd
rm -rf $tmpdir


echo "end of 20.${SW}.sh"
