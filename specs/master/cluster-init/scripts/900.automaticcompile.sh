#!/bin/bash
# Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

echo "starting 900.automaticcompile.sh"

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

# get Quantum ESPRESSO vers
AUTOMATIC_COMPILE=$(jetpack config AUTOMATIC_COMPILE)

if [[ ${AUTOMATIC_COMPILE} = "True" ]]; then
   echo "sleep 180" > ${HOMEDIR}/sleep.sh
   chown ${CUSER}:${CUSER} ${HOMEDIR}/sleep.sh
   sudo -u ${CUSER} /opt/pbs/bin/qsub -l select=1:ncpus=44 ${HOMEDIR}/sleep.sh
fi

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# file settings
chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps 
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/master/scripts/900.automaticcompile.sh.out ${HOMEDIR}/ 
chown ${CUSER}:${CUSER} ${HOMEDIR}/900.automaticcompile.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 900.automaticcompile.sh"
