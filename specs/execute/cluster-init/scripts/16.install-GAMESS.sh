#!/bin/bash
# Copyright (c) 2020 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
set -exuv

SW=GAMESS
echo "starting 16.install-${SW}.sh"

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
GAMESS_BUILD=$(jetpack config GAMESS_BUILD)
GAMESS_DIR=${HOMEDIR}/apps/${GAMESS_BUILD}

# get GAMESS version
if [[ ${GAMESS_BUILD} = None ]]; then
   exit 0
fi

# check files and directory
if [[ ! -d ${GAMESS_DIR} ]]; then
   tar zxfp ${HOMEDIR}/apps/${GAMESS_FILENAME} -C ${HOMEDIR}/apps
   mv ${HOMEDIR}/apps/gamess ${GAMESS_DIR}
   chown -R ${CUSER}:${CUSER} ${GAMESS_DIR}
fi

# set up for building
tmpdir=$(mktemp -d)
pushd $tmpdir
CORES=$(grep cpu.cores /proc/cpuinfo | wc -l)
yum install -y expect

# building gamess us
if [[ ${GAMESS_BUILD} = "gamess-sockets" ]]; then
   if [[ ! -f ${GAMESS_BUILD}/gamess.00.x ]]; then
      sed -i -e "s/MAXCPUS=32/MAXCPUS=${CORES}/" ${GAMESS_DIR}/ddi/compddi
      cd ${GAMESS_DIR} && sudo -u ${CUSER} /usr/bin/make clean | exit 0
      /usr/bin/csh /mnt/cluster-init/QCMD/execute/files/expect-sockets
      cd ${GAMESS_DIR} && sudo -u ${CUSER} /usr/bin/make -j ${CORES}
      sed -i -e "s:set\ SCR=\/scr1\/\$USER\/:SCR=${HOMEDIR}/scr:" ${GAMESS_DIR}/rungms
      sed -i -e "s:set\ USERSCR=\~\/gamess-devv:set USERSCR=${HOMEDIR}/scr:" ${GAMESS_DIR}/rungms
      sed -i -e "s:set\ GMSPATH=\~\/gamess-devv:set GMSPATH=${GAMESS_DIR}:" ${GAMESS_DIR}/rungms
   fi
fi

if [[ ${GAMESS_BUILD} = "gamess-impi" ]]; then
   if [[ ! -f ${GAMESS_BUILD}/gamess.00.x ]]; then
      sed -i -e "s/MAXCPUS=32/MAXCPUS=${CORES}/" ${GAMESS_DIR}/ddi/compddi
      cd ${GAMESS_DIR} && sudo -u ${CUSER} /usr/bin/make clean | exit 0
      # set up files
      sed -i -e "s:set\ work=/shared/home/azureuser/apps/:set work=${HOMEDIR}/apps/:" ${CYCLECLOUD_SPEC_PATH}/files/expect-impi
      sed -i -e "s:set\ prefix=/shared/home/azureuser/apps/\$gamess/:set prefix=${GAMESS_DIR}:" ${CYCLECLOUD_SPEC_PATH}/files/expect-impi
      /usr/bin/csh /mnt/cluster-init/QCMD/execute/files/expect-impi
      # buils settings
      declare I_MPI_ROOT
      declare CLASSPATH
      declare LD_LIBRARY_PATH
      export PATH=/opt/intel/compilers_and_libraries_2018.5.274/linux/bin/intel64:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin:$PATH
      export LD_LIBRARY_PATH=/opt/intel/compilers_and_libraries_2018.5.274/linux/compiler/lib/intel64:/opt/intel/compilers_and_libraries_2018.5.274/linux/compiler/lib/intel64_lin:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/lib:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/mic/lib:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/lib:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/mic/lib
      export I_MPI_ROOT=/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi
      export CLASSPATH=/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/lib/mpi.jar:/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/lib/mpi.jar
      cd ${GAMESS_DIR} && sudo -u ${CUSER} /usr/bin/make -j ${CORES}
      sed -i -e "s:set\ TARGET=*:set TARGET=mp:" ${GAMESS_DIR}/rungms
      sed -i -e "s:set\ SCR=\/scr1\/\$USER\/:SCR=${HOMEDIR}/scr:" ${GAMESS_DIR}/rungms
      sed -i -e "s:set\ USERSCR=\~\/gamess-devv:set USERSCR=${HOMEDIR}/scr:" ${GAMESS_DIR}/rungms
      sed -i -e "s:set\ GMSPATH=\~\/gamess-devv:set GMSPATH=${GAMESS_DIR}:" ${GAMESS_DIR}/rungms
   fi
fi

# GAMESS file settings
if [[ ! -d ${HOMEDIR}/scr ]]; then
   mkdir -p ${HOMEDIR}/scr
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/scr
fi
cp ${CYCLECLOUD_SPEC_PATH}/files/jobgamessimpi.sh ${HOMEDIR}/scr
chown -R ${CUSER}:${CUSER} ${GAMESS_DIR}/scr

# general file settings
if [[ ! -d ${HOMEDIR}/logs ]]; then
   mkdir -p ${HOMEDIR}/logs
   chown -R ${CUSER}:${CUSER} ${HOMEDIR}/logs
fi
cp /opt/cycle/jetpack/logs/cluster-init/QCMD/execute/scripts/16.install-${SW}.sh.out ${HOMEDIR}/logs/
chown ${CUSER}:${CUSER} ${HOMEDIR}/logs/16.install-${SW}.sh.out

#clean up
popd
popd


echo "end of 16.install-${SW}.sh"
