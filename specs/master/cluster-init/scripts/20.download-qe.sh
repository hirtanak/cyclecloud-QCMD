#!/bin/bash
# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=qe
echo "starting 20.execute-${SW}.sh"

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

# Don't run if we've already expanded the QuantumESPRESSO tarball. Download QuantumESPRESSO installer into tempdir and unpack it into the apps directory
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

#clean up
popd
rm -rf $tmpdir


echo "end of 20.download-${SW}.sh"
