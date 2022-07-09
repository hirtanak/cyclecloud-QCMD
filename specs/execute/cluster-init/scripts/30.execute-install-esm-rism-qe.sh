#!/bin/bash
# Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=esm-rism-qe
echo "starting 30.execute-install-${SW}.sh"

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
QE_VERSION=$(jetpack config QE_VERSION)
# get esm-rism-qe parameters
QE_DL_URL=$(jetpack config QE_DL_URL)
QE_DL_VER=${QE_DL_URL##*/}

# get Quantum ESPRESSO version
if [[ ${QE_DL_URL} = None ]]; then
   exit 0
fi

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# install packages
yum install -y -q openssl-devel libgcrypt-devel
yum remove -y -q cmake gcc

# build setting
# need "set +" setting for parameter proceesing
set +u
alias gcc=/opt/gcc-9.2.0/bin/gcc
alias c++=/opt/gcc-9.2.0/bin/c++
# PATH settings
export PATH=/opt/gcc-9.2.0/bin/:$PATH
export PATH=/opt/openmpi-4.0.2/bin:$PATH
export LD_LIBRARY_PATH=/opt/gcc-9.2.0/lib64:$LD_LIBRARY_PATH
set -u

## GCC
GCC_PATH=$(ls /opt/ | grep ^gcc-)
GCC_VERSION=920
if [ -z $GCC_PATH ]; then
   GCC_VERSION=485
fi

# cmake version
set +eu
#echo $CMAKE_VERSION > /shared/CMAKE_VERSION
CMAKE_VERSION=$(cat /shared/CMAKE_VERSION)
if [ -z $CMAKE_VERSION ]; then
  CMAKE_VERSION=3.21.4
fi
set -eu

# download ESM RISM QuantumESPRESOO
if [[ ! -f ${HOMEDIR}/${QE_DL_VER} ]]; then
   wget -nv ${QE_DL_URL} -O ${HOMEDIR}/${QE_DL_VER}
   chown ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DL_VER}
fi
if [[ ! -d ${HOMEDIR}/${QE_DL_VER%%.*} ]]; then
   tar zxfp ${HOMEDIR}/${QE_DL_VER} -C ${HOMEDIR}
   chown ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DL_VER}
fi

# build and install
if [[ ! -f ${HOMEDIR}/${QE_DL_VER%%.*}/bin/pw.x ]]; then 
   alias gcc=/opt/gcc-9.2.0/bin/gcc
   export PATH=/opt/gcc-9.2.0/bin:$PATH
   make clean all | exit 0 
   ${HOMEDIR}/${QE_DL_VER%%.*}/configure --with-internal-blas --with-internal-lapack
   chown ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DL_VER%%.*}/make.inc | exit 0
   #CORES=$(($(grep cpu.cores /proc/cpuinfo | wc -l) + 1))
   cd ${HOMEDIR}/${QE_DL_VER%%.*} && make all #${CORES}
fi

# License File Setting
LICENSE=$(jetpack config LICENSE)
KEY=$(jetpack config KEY)
(echo "export LICENSE_FILE=${LICENSE}"; echo "export KEY=${KEY}") > /etc/profile.d/qe.sh
chmod a+x /etc/profile.d/qe.sh
chown ${CUSER}:${CUSER} /etc/profile.d/qe.sh

# need set +u setting for parameter prcessing
set +u
CMD=$(grep ${QE_DL_VER%%.*} ${HOMEDIR}/.bashrc | head -1) | exit 0
if [[ -n ${CMD} ]]; then
   (echo "export PATH=${HOMEDIR}/${QE_DL_VER%%.*}/bin:$PATH") >> ${HOMEDIR}/.bashrc
fi
unset CMD && CMD=$(ls -la ${HOMEDIR} | grep ${QE_DL_VER%%.*} | awk '{print $3}'| head -1)
if [[ -z ${CMD} ]]; then
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DL_VER%%.*} | exit 0
fi
chmod -R 755 ${HOMEDIR}/${QE_DL_VER%%.*}
# need set +u setting for parameter prcessing
set -u

# file settings
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/30.execute-install-${SW}.sh.out ${HOMEDIR}/logs/
chown ${CUSER}:${CUSER} ${HOMEDIR}/logs/30.execute-install-${SW}.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 30.execute-install-${SW}.sh"
