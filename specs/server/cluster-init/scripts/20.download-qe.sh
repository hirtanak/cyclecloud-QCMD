#!/bin/bash
# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=qe
echo "starting 20.execute-${SW}.sh"

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
QE_VERSION=$(jetpack config QE_VERSION)
QE_DL_URL1=https://github.com/QEF/q-e/archive/refs/tags/qe-${QE_VERSION}/qe-${QE_VERSION}.tar.gz
QE_DL_URL2=https://github.com/QEF/q-e/releases/download/qe-${QE_VERSION}/qe-${QE_VERSION}-ReleasePack.tgz
set +e
wget -nv ${QE_DL_URL1} >> /dev/null
if [ "$?" -eq 0 ]; then
  QE_DL_URL=${QE_DL_URL1} && echo "using QE_DL_URL1"
else
  if [[ ${QE_VERSION} == "6.7" ]] || [[ ${QE_VERSION} == "6.7.0" ]]; then
    QE_DL_URL2=https://github.com/QEF/q-e/releases/download/qe-${QE_VERSION}.0/qe-${QE_VERSION}-ReleasePack.tgz
    QE_DL_URL=${QE_DL_URL2} && echo "using QE_DL_URL2"
  else
    QE_DL_URL=${QE_DL_URL2} && echo "using QE_DL_URL2"
  fi
fi
QE_DIR=qe-${QE_VERSION}

if [[ ${QE_VERSION} = None ]]; then 
  exit 0 
fi
set -e

# Create tempdir
tmpdir=$(mktemp -d)
pushd $tmpdir

# Download QuantumESPRESSO installer into tempdir and unpack it into the home directory
if [[ ${QE_VERSION} == "7.0" ]] || [[ ${QE_VERSION} == "6.8" ]] || [[ ${QE_VERSION} == "6.7.0" ]] || [[ ${QE_VERSION} == "6.?" ]]; then 
  if [[ ! -s ${HOMEDIR}/qe-${QE_VERSION}.tar.gz ]]; then
    rm ${HOMEDIR}/qe-${QE_VERSION}.tar.gz && true
  fi
  if [[ ! -f ${HOMEDIR}/qe-${QE_VERSION}.tar.gz ]]; then
    wget -nv ${QE_DL_URL} -O ${HOMEDIR}/qe-${QE_VERSION}.tar.gz
    chown ${CUSER}:${CUSER} ${HOMEDIR}/qe-${QE_VERSION}.tar.gz
    if [[ ! -d ${HOMEDIR}/qe-${QE_VERSION} ]] || [[ ! -d ${HOMEDIR}/q-e-qe-${QE_VERSION} ]]; then 
      rm -rf ${HOMEDIR}/qe-${QE_VERSION} ${HOMEDIR}/q-e-qe-${QE_VERSION} && true
      tar zxfp ${HOMEDIR}/qe-${QE_VERSION}.tar.gz -C ${HOMEDIR}/
    fi
  else 
    echo "valid file and no tar.gz download"
  fi
else 
  if [[ ! -s ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz ]]; then
    rm ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz && true
  fi
  if [[ ! -f ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz ]]; then
    wget -nv ${QE_DL_URL} -O ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz
    chown ${CUSER}:${CUSER} ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz
    if [[ ! -d ${HOMEDIR}/qe-${QE_VERSION} ]] || [[ ! -d ${HOMEDIR}/q-e-qe-${QE_VERSION} ]]; then 
      rm -rf ${HOMEDIR}/qe-${QE_VERSION} ${HOMEDIR}/q-e-qe-${QE_VERSION} && true
      tar zxfp ${HOMEDIR}/qe-${QE_VERSION}-ReleasePack.tgz -C ${HOMEDIR}
    fi
  else 
    echo "valid file and no tgz download"
  fi
fi

# get qe directory
QE_DIR_FULL=$(ls -d ${HOMEDIR}/* | grep qe-${QE_VERSION})
QE_DIR=${QE_DIR_FULL##*/}
echo "QE_DIR: $QE_DIR"

# file permission
CMD=$(ls -la ${HOMEDIR} | grep ${QE_DIR} | awk '{print $3}'| head -1)
if [[ ${CMD} != ${CUSER} ]]; then
  chown -R ${CUSER}:${CUSER} ${HOMEDIR}/${QE_DIR} && true
fi

#clean up
popd
rm -rf $tmpdir


echo "end of 20.download-${SW}.sh"
