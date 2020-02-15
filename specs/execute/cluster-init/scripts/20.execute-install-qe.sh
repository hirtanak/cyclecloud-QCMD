#!/bin/bash
# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=qe
echo "starting 20.execute-install-${SW}.sh"

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

# get Quantum ESPRESSO version
QE_VERSION=$(jetpack config QE_VERSION)
QE_DL_URL=https://github.com/QEF/q-e/releases/download/qe-${QE_VERSION}/qe-${QE_VERSION}-ReleasePack.tgz
QE_DIR=qe-${QE_VERSION}

if [[ ${QE_VERSION} = None ]]; then 
   exit 0 
fi

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# Azure VMs that have ephemeral storage mounted at /mnt/exports.
if [ ! -d ${HOMEDIR}/apps ]; then
   sudo -u ${CUSER} ln -s /mnt/exports/apps ${HOMEDIR}/apps
   chown ${CUSER}:${CUSER} /mnt/exports/apps
fi
chown ${CUSER}:${CUSER} /mnt/exports/apps | exit 0

# install packages
yum install -y perl-Digest-MD5.x86_64 redhat-lsb-core centos-release-scl
#yum install -y devtoolset-8-gcc devtoolset-8-gcc-c++ devtoolset-8-gcc-gfortran

# License File Setting
#LICENSE=$(jetpack config LICENSE)
#KEY=$(jetpack config KEY)
#(echo "export LICENSE_FILE=${LICENSE}"; echo "export KEY=${KEY}") > /etc/profile.d/qe.sh
#chmod a+x /etc/profile.d/qe.sh
#chown ${CUSER}:${CUSER} /etc/profile.d/qe.sh

# Don't run if we've already expanded the QuantumESPRESSO file.
if [[ ! -f ${HOMEDIR}/apps/qe-${QE_VERSION}-ReleasePack.tgz ]]; then
   wget -nv ${QE_DL_URL} -O ${HOMEDIR}/apps/qe-${QE_VERSION}-ReleasePack.tgz
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/qe-${QE_VERSION}-ReleasePack.tgz
fi
if [[ ! -d ${HOMEDIR}/apps/${QE_DIR} ]]; then
   tar zxfp ${HOMEDIR}/apps/qe-${QE_VERSION}-ReleasePack.tgz -C ${HOMEDIR}/apps
fi
CMD=$(ls -la ${HOMEDIR}/apps/ | grep ${QE_DIR} | awk '{print $3}'| head -1)
if [[ -z ${CMD} ]]; then
  chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/${QE_DIR} | exit 0
fi

# build and install
#set +u
#CMD1=$(grep devtoolset-8 ${HOMEDIR}/.bashrc | head -1) | exit 0
##if [[ -n ${CMD1} ]]; then
#   (echo "export PATH=$PATH:/opt/rh/devtoolset-8/root/bin") >> ${HOMEDIR}/.bashrc
#fi
if [[ ! -f ${HOMEDIR}/apps/${QE_DIR}/bin/pw.x ]]; then 
#   export PATH=$PATH:/opt/rh/devtoolset-8/root/bin
   alias gcc=/opt/gcc-9.2.0/bin/gcc
   make clean all | exit 0 
   ${HOMEDIR}/apps/${QE_DIR}/configure --with-internal-blas --with-internal-lapack
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/${QE_DIR}/make.inc | exit 0
   cd ${HOMEDIR}/apps/${QE_DIR}
   CORES=$(($(grep cpu.cores /proc/cpuinfo | wc -l) + 1))
   make all -j ${CORES}
fi
CMD2=$(grep ${QE_DIR} ${HOMEDIR}/.bashrc | head -1) | exit 0
if [[ -n ${CMD2} ]]; then
   (echo "export PATH=${HOMEDIR}/apps/${QE_DIR}/bin:$PATH") >> ${HOMEDIR}/.bashrc
fi
set -u

# local file settings
if [[ ! -f ${HOMEDIR}/qerun.sh ]]; then
   cp ${CYCLECLOUD_SPEC_PATH}/files/qerun.sh ${HOMEDIR}/
   chmod a+rx ${HOMEDIR}/qerun.sh
   chown ${CUSER}:${CUSER} ${HOMEDIR}/qerun.sh
fi
chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/${QE_DIR}
chmod -R 775 ${HOMEDIR}/apps/${QE_DIR}

# file settings
chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps 
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/20.execute-install-${SW}.sh.out ${HOMEDIR}/
chown ${CUSER}:${CUSER} ${HOMEDIR}/20.execute-install-${SW}.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 20.execute-install-${SW}.sh"
