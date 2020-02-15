#!/bin/bash
# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=gromacs
echo "starting 40.install_${SW}.sh"

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
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/QCMD/master

# get GROMACS version
GROMACS_VERSION=$(jetpack config GROMACS_VERSION)
if [[ ${GROMACS_VERSION} = None ]]; then
   exit 0
fi
CMAKE_VERSION=3.16.4

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

yum install -y cmake

# Don't run if we've already expanded the GROMACS tarball. Download GROMACS
if [[ ! -f ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}.tar.gz ]]; then
   wget -nv http://ftp.gromacs.org/pub/gromacs/gromacs-${GROMACS_VERSION}.tar.gz -O ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}.tar.gz
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}.tar.gz
fi
if [[ ! -d ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION} ]]; then
   tar zxfp ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}.tar.gz -C ${HOMEDIR}/apps
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/gromacs-${GROMACS_VERSION}
fi

# cmake donwload
if [[ ! -f ${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz ]]; then
   wget -nv https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz -O ${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz
fi
# cmake build
if [[ ! -d ${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64 ]]; then 
   tar zxfp ${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz -C ${HOMEDIR}/apps/
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/cmake-${CMAKE_VERSION}-Linux-x86_64
fi

#clean up
popd
rm -rf $tmpdir


echo "end of 40.download-gromacs.sh"
