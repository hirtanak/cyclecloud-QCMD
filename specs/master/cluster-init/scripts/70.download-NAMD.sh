#!/bin/bash
# Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=NAMD
echo "starting 70.download-${SW}.sh"

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
NAMD_VERSION=$(jetpack config NAMD_VERSION)
NAMD_FILENAME="NAMD_2.14b1_Linux-x86_64-multicore.tar.gz"

# get GAMESS version
if [[ ${NAMD_VERSION} = None ]]; then
   exit 0
fi


# Don't run if we've already expanded the GAMESS tarball. Download GAMESS
if [[ ! -f ${HOMEDIR}/apps/${NAMD_FILENAME} ]]; then
   jetpack download ${NAMD_FILENAME} ${HOMEDIR}/apps/
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/${NAMD_FILENAME}
fi
if [[ ! -f ${HOMEDIR}/apps/${NAMD_FILENAME%%.tar.gz*} ]]; then
   tar zxfp ${HOMEDIR}/apps/${NAMD_FILENAME} -C ${HOMEDIR}/apps
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/${NAMD_FILENAME%%.tar.gz*}
fi


echo "end of 70.download-${SW}.sh"
