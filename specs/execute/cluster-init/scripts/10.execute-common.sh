#!/bin/bash
# Copyright (c) 2021-2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=common
echo "starting 10.execute-${SW}.sh"

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
echo ${CUSER} > /shared/CUSER
HOMEDIR=/shared/home/${CUSER}
CYCLECLOUD_SPEC_PATH=/mnt/cluster-init/QCMD/execute

# installation packages
yum install -y -q epel-release
yum install -y -q htop pigz parallel

# cmake version
CMAKE_VERSION=3.23.2 #3.21.4
echo $CMAKE_VERSION > /shared/CMAKE_VERSION
CMAKE_VERSION=$(cat /shared/CMAKE_VERSION)

# increase user process, threads
sed -i -e "s/4096/65535/" /etc/security/limits.d/20-nproc.conf ||
	sed -i -e "s/4096/65535/" /etc/security/limits.conf

## Checking VM SKU and Cores
VMSKU=`cat /proc/cpuinfo | grep "model name" | head -1 | awk '{print $7}'`
CORES=$(grep cpu.cores /proc/cpuinfo | wc -l)

## H16r or H16r_Promo
if [[ ${CORES} = 16 ]] ; then
  echo "Proccesing H16r"
  grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
fi

## HC/HB set up
if [[ ${CORES} = 44 ]] ; then
  echo "Proccesing HC44rs"
  grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
fi

if  [[ ${CORES} = 32 ]] || [[ ${CORES} = 64 ]] || [[ ${CORES} = 96 ]] || [[ ${CORES} = 60 ]] || [[ ${CORES} = 120 ]]; then
  echo "Proccesing HB60rs"
  grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
fi

# clear GPU settings
rm -rf /shared/GPU
rm -rf /shared/NVIDIA
rm -rf /shared/NVIDIA-SMI


echo "end of 10.execute-${SW}.sh"
