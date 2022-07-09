#!/bin/bash
# Copyright (c) 2021-2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=gpu
echo "starting 11.execute-${SW}.sh"

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

# checking OS version
OS_VERSION=$(cat /etc/redhat-release | cut -d " " -f 4)
CENTOS_VERSION=${OS_VERSION:0:1}

# CUDA settings
CUDA_DRIVER=515.48.07-1
CUDA_VERSION=11-7

# NVHPC: QE7.0 reauires NVHPC
NVHPC_VERSION=22.5 #22.5

# check GPU or no GPU
set +e
lspci -v | grep NVIDIA > /shared/NVIDIA
NVIDIA=$(cat /shared/NVIDIA | head -1 | cut -d " " -f 8)
echo $NVIDIA > /shared/GPU && echo $NVIDIA
set -e

# check GPU hardware 
if [ -e /bin/nvidia-smi ];then
  echo "nvidia-smi command exists"
  set +e
  /bin/nvidia-smi > /shared/NVIDIA-SMI
  /usr/local/cuda/bin/nvcc --version > /shared/NVCC
  set -e

  ## Checking VM SKU and Cores
  VMSKU=`cat /proc/cpuinfo | grep "model name" | head -1 | awk '{print $7}'`
  CORES=$(grep cpu.cores /proc/cpuinfo | wc -l)

  if [[ ${CORES} = 4 ]]; then
    echo "Proccesing 4 core GPU"
    grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
  elif [[ ${CORES} = 48 ]]; then
    echo "Proccesing 48 core GPU"
    grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
  fi

  if [[ ${CORES} = 6 ]]; then
    echo "Proccesing 6 core GPU"
    grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
  elif [[ ${CORES} = 32 ]]; then
    echo "Proccesing 32 core GPU"
    grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
  fi

  if [[ ${CORES} = 12 ]]; then
    echo "Proccesing 12 core GPU"
    grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
  elif [[ ${CORES} = 24 ]]; then
    echo "Proccesing 24 core GPU"
    grep "vm.zone_reclaim_mode = 1" /etc/sysctl.conf || echo "vm.zone_reclaim_mode = 1" >> /etc/sysctl.conf sysctl -p
  fi
else
  # GPU installation
  if [ -n "$NVIDIA" ]; then
    # checking OS version
    OS_VERSION=$(cat /etc/redhat-release | cut -d " " -f 4)
    CENTOS_VERSION=${OS_VERSION:0:1}

    # CentOS 7.xの処理
    if [[ ${OS_VERSION} = 7.?.???? ]]; then
      yum install -y -q deltarpm
      yum install -y -q kernel kernel-tools kernel-headers kernel-devel && true
      yum install -y -q dkms

      # NVIDIA repository 
      BASEURL="https://developer.download.nvidia.com/compute/cuda/repos"
      yum-config-manager --add-repo $BASEURL/rhel7/x86_64/cuda-rhel7.repo
      ## NVIDIA HPC SDK for QuamtumESPRESSO
      yum-config-manager --add-repo https://developer.download.nvidia.com/hpc-sdk/rhel/nvhpc.repo
      #|| yum install -y -q $BASEURL/rhel7/x86_64/${CUDA_REPO_PKG} 
      yum update -y -q
      # driver 
      # yum install -y -q cuda-drivers
      yum install -y -q nvidia-driver-latest-dkms
      # cuda
      yum install -y -q cuda-${CUDA_VERSION}
      ## Bundled with the newest CUDA version (11.7): NVIDIA HPC SDK for QuamtumESPRESSO
      ## NVHPC compiler is mandatory when CUDA is enabled due QE is based on CUDA: Fortran language
      yum install -y -q nvhpc-${NVHPC_VERSION}

      set +e
      /bin/nvidia-smi > /shared/NVIDIA-SMI
      /usr/local/cuda/bin/nvcc --version > /shared/NVCC
      set -e
    fi
    
    # CentOS 8.xの処理
    if [[ ${OS_VERSION} = 8.?.???? ]]; then
      ## NVIDIA HPC SDK for QuamtumESPRESSO
      yum-config-manager --add-repo https://developer.download.nvidia.com/hpc-sdk/rhel/nvhpc.repo
      # driver
      dnf install -y -q epel-next-release
      dnf --enablerepo=epel-next install -y -q kernel-devel-$(uname -r) kernel-headers-$(uname -r) dkms
      dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo 
      
      time dnf module install -y -q nvidia-driver:latest-dkms

      nvidia-modprobe && nvidia-modprobe -u

      # cuda
      time dnf install -y -q cuda-${CUDA_VERSION}
      ## Bundled with the newest CUDA version (11.7): NVIDIA HPC SDK for QuamtumESPRESSO
      ## NVHPC compiler is mandatory when CUDA is enabled due QE is based on CUDA: Fortran language
      time dnf install -y -q nvhpc-${NVHPC_VERSION}

      set +e
      /bin/nvidia-smi > /shared/NVIDIA-SMI
      /usr/local/cuda/bin/nvcc --version > /shared/NVCC
      set -e
    fi
  else 
    echo "no GPU found"
  fi
fi


echo "end of 11.execute-${SW}.sh"
