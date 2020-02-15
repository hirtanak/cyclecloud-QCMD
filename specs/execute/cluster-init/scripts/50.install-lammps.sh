#!/bin/bash
# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=lammps
echo "starting 50.install-${SW}.sh"

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
LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
LAMMPS_DL_URL=https://github.com/lammps/lammps/archive/${LAMMPS_VERSION}.tar.gz
LAMMPS_DIR=lammps-${LAMMPS_VERSION}

# get LAMMPS version
LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
if [[ ${LAMMPS_VERSION} = None ]]; then
   exit 0
fi

CORES=$(($(grep cpu.cores /proc/cpuinfo | wc -l) + 1))

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# yum install -y cmake
yum install remove -y cmake

# Don't run if we've already expanded the LAMMPS tarball. Download LAMMPS
if [[ ! -f ${HOMEDIR}/apps/${LAMMPS_VERSION}.tar.gz ]]; then
   wget -nv https://github.com/lammps/lammps/archive/${LAMMPS_VERSION}.tar.gz -O ${HOMEDIR}/apps/${LAMMPS_VERSION}.tar.gz
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/${LAMMPS_VERSION}.tar.gz
fi
if [[ ! -d ${HOMEDIR}/apps/${LAMMPS_DIR} ]]; then
   tar zxfp ${HOMEDIR}/apps/${LAMMPS_VERSION}.tar.gz -C ${HOMEDIR}/apps
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/apps/${LAMMPS_DIR}
fi

# build setting
alias gcc=/opt/gcc-9.2.0/bin/gcc
alias c++=/opt/gcc-9.2.0/bin/c++
export PATH=${HOMEDIR}/apps/${LAMMPS_DIR}/src/:/opt/openmpi-4.0.2/bin:$PATH

# build and install
if [[ ! -f ${HOMEDIR}/apps/${LAMMPS_DIR}/bin/lmp_mpi ]]; then 
   mkdir -p ${HOMEDIR}/apps/${LAMMPS_DIR}/build | exit 0
   chown ${CUSER}:${CUSER} ${HOMEDIR}/apps/${LAMMPS_DIR}/build
   # MPI setting 
   sed -i -e "44c\MPI_LIB =       -lmpi"  ${HOMEDIR}/apps/${LAMMPS_DIR}/src/MAKE/Makefile.mpi
   cd ${HOMEDIR}/apps/${LAMMPS_DIR}/src/
   sudo -u ${CUSER} make mpi -j ${CORES}
   mkdir -p ${HOMEDIR}/apps/${LAMMPS_DIR}/bin/ | exit 0
   cp ${HOMEDIR}/apps/${LAMMPS_DIR}/src/lmp_mpi ${HOMEDIR}/apps/${LAMMPS_DIR}/bin/ | exit 0
fi

# need "set +" setting for parameter proceesing
set +u
CMD=$(grep "cmake" ${HOMEDIR}/.bashrc | head -1)
if [[ -z ${CMD} ]]; then
   CMD1=$(grep '^export PATH' ${HOMEDIR}/.bashrc | head -1)
   CMD2=${CMD1#export PATH=}
   #echo $CMD2
   if [[ -n ${CMD2} ]]; then
      sed -i -e "s!^export PATH!export PATH=export PATH=${HOMEDIR}\/apps\/${LAMMPS_DIR}\/bin:${CMD2}!g" ${HOMEDIR}/.bashrc
   fi
   if [[ -z ${CMD2} ]]; then
      (echo "export PATH=export PATH=${HOMEDIR}\/apps\/${LAMMPS_DIR}\/bin:$PATH") >> ${HOMEDIR}/.bashrc
   fi
fi
# need "set +" setting for parameter proceesing
set -u

# file settings
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/50.install-${SW}.sh.out ${HOMEDIR}/
chown ${CUSER}:${CUSER} ${HOMEDIR}/50.install-${SW}.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 50.install-${SW}.sh"
