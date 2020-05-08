#!/bin/bash
# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

echo "starting 10.master.sh"

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

# get Quantum ESPRESSO version
QE_VERSION=$(jetpack config QE_VERSION)
# set parameters
QE_DL_URL=$(jetpack config QE_DL_URL)
QE_DL_VER=${QE_DL_URL##*/}

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# Azure VMs that have ephemeral storage mounted at /mnt/exports.
if [ ! -d ${HOMEDIR}/apps ]; then
   sudo -u ${CUSER} ln -s /mnt/exports/apps ${HOMEDIR}/apps
   chown ${CUSER}:${CUSER} /mnt/exports/apps
fi
chown -R ${CUSER}:${CUSER} /mnt/exports/apps | exit 0

# package set up
yum install -y htop
# submit compile job
if [[ ! -f ${HOMEDIR}/azcopy ]]; then
   jetpack download azcopy ${HOMEDIR} --project QCMD
   chown ${CUSER}:${CUSER} ${HOMEDIR}/azcopy
fi

# file settings
chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps 
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/master/scripts/10.master.sh.out ${HOMEDIR}/ 
chown ${CUSER}:${CUSER} ${HOMEDIR}/10.master.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 10.master.sh"
