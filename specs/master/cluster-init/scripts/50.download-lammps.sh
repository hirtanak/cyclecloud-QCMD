#!/bin/bash
# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=lammps
echo "starting 50.download-${SW}.sh"

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
LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
LAMMPS_DL_URL=https://github.com/lammps/lammps/archive/${LAMMPS_VERSION}.tar.gz
LAMMPS_DIR=lammps-${LAMMPS_VERSION}

# get LAMMPS version
LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
if [[ ${LAMMPS_VERSION} = None ]]; then
   exit 0
fi


# Don't run if we've already expanded the LAMMPS tarball. Download LAMMPS
if [[ ! -f ${HOMEDIR}/apps/${LAMMPS_VERSION}.tar.gz ]]; then
   wget -nv https://github.com/lammps/lammps/archive/${LAMMPS_VERSION}.tar.gz -O ${HOMEDIR}/apps/${LAMMPS_VERSION}.tar.gz
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/${LAMMPS_VERSION}.tar.gz
fi
if [[ ! -d ${HOMEDIR}/apps/${LAMMPS_DIR} ]]; then
   tar zxfp ${HOMEDIR}/apps/${LAMMPS_VERSION}.tar.gz -C ${HOMEDIR}/apps
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/${LAMMPS_DIR}
fi


echo "end of 50.download-${SW}.sh"
