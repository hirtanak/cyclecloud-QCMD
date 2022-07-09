#!/bin/bash
# Copyright (c) 2019-2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=lammps
echo "starting 50.download-${SW}.sh"

#export LC_ALL=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LANGUAGE=en_US.UTF-8

# run this script or not
LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
if [[ ${LAMMPS_VERSION} = None ]]; then
   exit 0
fi

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

# check kokkos requirement
set +xu
jetpack config LAMMPS_VERSION > /shared/KOKKOS_TMP
grep kokkos /shared/KOKKOS_TMP > /shared/KOKKOS | exit 0
rm /shared/KOKKOS_TMP
KOKKOS=$(cat /shared/KOKKOS)
echo "KOKKOS: $KOKKOS"
set -x

# ""が必要
if [ -n "${KOKKOS}" ]; then 
  # KOKKOS 使っている場合
  echo "proccesingg kokkos..."
  echo $KOKKOS > /mnt/exports/shared/KOKKOS
  LAMMPS_VERSION_TMP=$(jetpack config LAMMPS_VERSION)
  LAMMPS_VERSION=${LAMMPS_VERSION_TMP%_kokkos*}
else
  # get LAMMPS version
  echo "proccesing normal and intel/openmpi..."
  LAMMPS_VERSION_TMP=$(jetpack config LAMMPS_VERSION)
  LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
  set +u
  if [[ ${LAMMPS_VERSION_TMP} == "stable_29Sep2021_update2_impi_ompi" ]]; then
    LAMMPS_VERSION=stable_29Sep2021_update2
    IMPI_PATH=/opt/intel/impi/2018.4.274/bin64
  fi
fi
LAMMPS_DL_URL=https://github.com/lammps/lammps/archive/${LAMMPS_VERSION}.tar.gz
LAMMPS_DIR=lammps-${LAMMPS_VERSION}
set -u

# Don't run if we've already expanded the LAMMPS tarball. Download LAMMPS
if [[ ! -f ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz ]]; then
   wget -nv https://github.com/lammps/lammps/archive/${LAMMPS_VERSION}.tar.gz -O ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz
   chown ${CUSER}:${CUSER} ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz
fi
if [[ ! -d ${HOMEDIR}/${LAMMPS_DIR} ]]; then
   tar zxfp ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz -C ${HOMEDIR}
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${LAMMPS_DIR}
fi
# for intel mpi
set +eu
if [[ -n "$IMPI_PATH" ]]; then
  if [[ ! -d ${HOMEDIR}/${LAMMPS_DIR}-intel ]]; then
    tar zxfp ${HOMEDIR}/${LAMMPS_VERSION}.tar.gz -C /tmp/
    mv /tmp/${LAMMPS_VERSION} ${HOMEDIR}/${LAMMPS_VERSION}-intel
    chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${LAMMPS_DIR}-intel
  fi
fi


echo "end of 50.download-${SW}.sh"
