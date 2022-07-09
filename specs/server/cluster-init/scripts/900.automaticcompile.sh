#!/bin/bash
# Copyright (c) 2021 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
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
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/QCMD/server

# get config parameters from template
AUTOMATIC_COMPILE=$(jetpack config AUTOMATIC_COMPILE)
CORES=1 #$(jetpack config COMPILE_CORES)

# QuantumESPRESSO: pw.xがなければコンパイル。バイナリチェックは not -f, -e

# get Quantum ESPRESSO version
QE_VERSION=$(jetpack config QE_VERSION)
QE_DL_URL1=https://github.com/QEF/q-e/archive/refs/tags/qe-${QE_VERSION}/qe-${QE_VERSION}.tar.gz
QE_DL_URL2=https://github.com/QEF/q-e/releases/download/qe-${QE_VERSION}/qe-${QE_VERSION}-ReleasePack.tgz
set +e
wget -nv ${QE_DL_URL1} >> /dev/null
set -e
if [ "$?" -eq 0 ]; then
  QE_DL_URL=${QE_DL_URL1} && echo "using QE_DL_URL1"
else
  QE_DL_URL=${QE_DL_URL2} && echo "using QE_DL_URL2"
fi
declare QE_DIR
# get qe directory
QE_DIR_FULL=$(ls -d ${HOMEDIR}/* | grep qe-${QE_VERSION})
QE_DIR=${QE_DIR_FULL##*/}
echo "QE_DIR: $QE_DIR"

## check binary..
if [[ ! -e ${HOMEDIR}/${QE_DIR}/bin/pw.x ]]; then
  # no defined time for compiling...
  echo "sleep 180" > ${HOMEDIR}/sleep.sh
  chmod +x ${HOMEDIR}/sleep.sh
  chown ${CUSER}:${CUSER} ${HOMEDIR}/sleep.sh
  sudo -u ${CUSER} /opt/pbs/bin/qsub -l select=1:ncpus=${CORES} ${HOMEDIR}/sleep.sh
fi

# LAMMPS: lmpコンパイルの有無をチェック
if [[ ${AUTOMATIC_COMPILE} = "True" ]]; then
   # check kokkos requirement
   set +xu
   jetpack config LAMMPS_VERSION > /shared/KOKKOS_TMP
   grep kokkos /shared/KOKKOS_TMP > /shared/KOKKOS | exit 0
   rm /shared/KOKKOS_TMP
   KOKKOS=$(cat /shared/KOKKOS)
   set -x

   if [ -n ${KOKKOS} ]; then
      # KOKKOS 使っている場合
      echo $KOKKOS > /shared/KOKKOS
      LAMMPS_VERSION_TMP=$(jetpack config LAMMPS_VERSION)
      LAMMPS_VERSION=${LAMMPS_VERSION_TMP%_kokkos*}

      # check kokkos requirement
      set +xu
      jetpack config LAMMPS_VERSION > /shared/KOKKOS_TMP
      grep kokkos /shared/KOKKOS_TMP > /shared/KOKKOS | exit 0
      rm /shared/KOKKOS_TMP
      KOKKOS=$(cat /shared/KOKKOS)
      set -x

   else
      # get LAMMPS version
      LAMMPS_VERSION=$(jetpack config LAMMPS_VERSION)
   fi
   set -u
   LAMMPS_DIR=lammps-${LAMMPS_VERSION}

   # lmpがなければコンパイル。バイナリチェックは not -f, -e
   if [[ ! -e ${HOMEDIR}/${LAMMPS_DIR}/bin/lmp || ${HOMEDIR}/${LAMMPS_DIR}/bin/lmp-kokkos ]]; then
      # no defined time for compiling...
      echo "sleep 180" > ${HOMEDIR}/sleep.sh
      chmod +x ${HOMEDIR}/sleep.sh
      chown ${CUSER}:${CUSER} ${HOMEDIR}/sleep.sh
      sudo -u ${CUSER} /opt/pbs/bin/qsub -l select=1:ncpus=${CORES} ${HOMEDIR}/sleep.sh
   fi
fi

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# file settings
mkdir -p  ${HOMEDIR}/logs
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/server/scripts/900.automaticcompile.sh.out ${HOMEDIR}/logs/ 
chown ${CUSER}:${CUSER} ${HOMEDIR}/logs/900.automaticcompile.sh.out

#clean up
popd
rm -rf $tmpdir


echo "end of 900.automaticcompile.sh"
