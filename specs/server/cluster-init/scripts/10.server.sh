#!/bin/bash
# Copyright (c) 2019-2021 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

echo "starting 10.server.sh"

#export LC_ALL=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LANGUAGE=en_US.UTF-8

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

# get Quantum ESPRESSO version
QE_VERSION=$(jetpack config QE_VERSION)
# set parameters
QE_DL_URL=$(jetpack config QE_DL_URL)
QE_DL_VER=${QE_DL_URL##*/}

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# package set up
yum install -y -q epel-release
yum install -y -q htop
# submit compile job
if [[ ! -f ${HOMEDIR}/azcopy ]]; then
   jetpack download azcopy ${HOMEDIR} --project QCMD
   chown ${CUSER}:${CUSER} ${HOMEDIR}/azcopy
   chmod +x ${HOMEDIR}/azcopy
fi

# file settings
mkdir -p ${HOMEDIR}/logs
chown ${CUSER}:${CUSER} ${HOMEDIR}/logs
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/server/scripts/10.server.sh.out ${HOMEDIR}/logs/
chown ${CUSER}:${CUSER} ${HOMEDIR}/logs/10.server.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 10.server.sh"
