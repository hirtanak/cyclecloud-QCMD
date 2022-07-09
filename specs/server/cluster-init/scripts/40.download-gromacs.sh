#!/bin/bash
# Copyright (c) 2019,2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=gromacs
echo "starting 40.install_${SW}.sh"

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
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/QCMD/server

# get GROMACS version
GROMACS_VERSION=$(jetpack config GROMACS_VERSION)
if [[ ${GROMACS_VERSION} = None ]]; then
   exit 0
fi

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# Don't run if we've already expanded the GROMACS tarball. Download GROMACS
if [[ ! -f ${HOMEDIR}/gromacs-${GROMACS_VERSION}.tar.gz ]]; then
   wget --no-check-certificate -nv -q https://ftp.gromacs.org/gromacs/gromacs-${GROMACS_VERSION}.tar.gz \
	   -O ${HOMEDIR}/gromacs-${GROMACS_VERSION}.tar.gz
   chown ${CUSER}:${CUSER} ${HOMEDIR}/gromacs-${GROMACS_VERSION}.tar.gz
fi
if [[ ! -d ${HOMEDIR}/gromacs-${GROMACS_VERSION} ]]; then
   tar zxfp ${HOMEDIR}/gromacs-${GROMACS_VERSION}.tar.gz -C ${HOMEDIR}
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/gromacs-${GROMACS_VERSION}
fi

#clean up
popd
rm -rf $tmpdir


echo "end of 40.download_$SW.sh"
