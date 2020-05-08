#!/bin/bash
# Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=GAMESS
echo "starting 60.download-${SW}.sh"

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
GAMESS_FILENAME=$(jetpack config GAMESS_FILENAME)
GAMESS_CONFIG=https://raw.githubusercontent.com/hirtanak/cyclecloud-QCMD/master/specs/master/cluster-init/files/gemessconfig00
GAMESS_DL_URL=https://www.msg.chem.iastate.edu/GAMESS/download/dist.source.shtml
GAMESS_DL_PASSWORD=$(jetpack config GAMESS_DOWNLOAD_PASSWORD)

# get GAMESS version
if [[ ${GAMESS_FILENAME} = None ]]; then
   exit 0
fi


# Don't run if we've already expanded the GAMESS tarball. Download GAMESS
if [[ ! -f ${HOMEDIR}/apps/${GAMESS_FILENAME} ]]; then
   jetpack download ${GAMESS_FILENAME} ${HOMEDIR}/apps/
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/${GAMESS_FILENAME}
fi
if [[ ! -f ${HOMEDIR}/apps/${GAMESS_FILENAME} ]]; then
   wget -nv ${GAMESS_DL_URL} -O ${HOMEDIR}/apps/
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/${GAMESS_FILENAME}
fi

if [[ ! -d ${HOMEDIR}/apps/gamess ]]; then
   tar zxfp ${HOMEDIR}/apps/${GAMESS_FILENAME} -C ${HOMEDIR}/apps
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/gamess
fi


echo "end of 60.download-${SW}.sh"
