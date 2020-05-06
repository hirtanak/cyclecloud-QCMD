#!/bin/bash
# Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=GAMESS
echo "starting 60.install-${SW}.sh"

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
GAMESS_FILENAME=$(jetpack config GAMESS_FILENAME)
GAMESS_CONFIG=https://raw.githubusercontent.com/hirtanak/cyclecloud-QCMD/master/specs/master/cluster-init/files/gemessconfig00
GAMESS_DL_URL=https://www.msg.chem.iastate.edu/GAMESS/download/dist.source.shtml
GAMESS_DL_PASSWORD=None
GAMESS_DL_PASSWORD=$(jetpack config GAMESS_DOWNLOAD_PASSWORD)

# get GAMESS version
if [[ ${GAMESS_FILENAME} = None ]]; then
   exit 0
fi

CORES=$(($(grep cpu.cores /proc/cpuinfo | wc -l) + 1))

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

yum install -y epel-release atlas-devel
yum install remove -y cmake

# build setting
alias gcc=/opt/gcc-9.2.0/bin/gcc
alias c++=/opt/gcc-9.2.0/bin/c++
# need "set +/-" setting for parameter proceesing
set +u
#export PATH=${HOMEDIR}/apps/${LAMMPS_DIR}/src/:/opt/openmpi-4.0.2/bin:$PATH
export PATH=/opt/${OPENMPI_PATH}/bin:$PATH

export MKLROOT=/opt/intel/mkl
export MPIROOT=/opt/intel/impi/2019.5.281

# check files and directory
if [[ ! -d ${HOMEDIR}/apps/gamess ]]; then
   tar zxfp ${HOMEDIR}/apps/${GAMESS_FILENAME} -C ${HOMEDIR}/apps
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/gamess
fi

# file settings
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/60.install-${SW}.sh.out ${HOMEDIR}/
chown ${CUSER}:${CUSER} ${HOMEDIR}/60.install-${SW}.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 60.install-${SW}.sh"
