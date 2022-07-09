#!/bin/bash
#PBS -j oe
#PBS -l select=12:ncpus=60
NP=720

NUM=03

FILE=runccm.sh
JAVA=run.java
INPUT1=XT2E_SDN_WJ.sim #5WJ_test.sim

# set up input files
#cp /mnt/share01/40hr.zip /shared/home/azureuser/input/40hr.zip
#unzip /shared/home/azureuser/input/40hr.zip -d /shared/home/azureuser/

LOGFILE=${NUM}-${NP}-${PBS_JOBID%%.*}-`date +%Y%m%d_%H%M`.log

# MPI settings
HPCX=/opt/hpcx-v2.8.3-gcc-MLNX_OFED_LINUX-5.2-2.2.3.0-redhat7.7-x86_64/ompi

#source ${HPCX}/../hpcx-init.sh
#module use ${HPCX}/../modulefiles
#module load ${HPCX}/../modulefiles/hpcx
#env | grep HPCX

STARCCMPLUS_VERSION=15.06.008
PRECISION=-R8 #-R8 double precision
INSTALL_DIR=/shared/home/azureuser
export DISPLAY=0:0

mkdir -p ${INSTALL_DIR}/${PBS_JOBID%%.*}
cp ${INSTALL_DIR}/${FILE} ${INSTALL_DIR}/${PBS_JOBID%%.*}/
cd ${INSTALL_DIR}/${PBS_JOBID%%.*}/

#MPI_ROOT="/shared/home/azureuser/15.04.010-R8/STAR-CCM+15.04.010-R8/mpi/openmpi/4.0.2-cda-002/linux-x86_64-2.12/gnu7.1"
#MPI_ROOT=${HPCX}
MPI_ROOT="/shared/home/azureuser/15.06.008-R8/STAR-CCM+15.06.008/mpi/openmpi/4.0.3-cda-002/linux-x86_64-2.12/gnu7.1"
export PATH=${MPI_ROOT}/bin:$PATH
export LD_LIBRARY_PATH=${MPI_ROOT}/lib:${LD_LIBRARY_PATH}

export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com
PODKEY=ZeFZLC0+ryq4YS89k6GcPA

echo STARTTIME `date` >> TIMELOG

time ${INSTALL_DIR}/${STARCCMPLUS_VERSION}${PRECISION}/STAR-CCM+${STARCCMPLUS_VERSION}${PRECISION}/star/bin/starccm+ -np ${NP} -machinefile ${PBS_NODEFILE} -licpath ${CDLMD_LICENSE_FILE} -power -podkey ${PODKEY} -mpi openmpi -rsh ssh -batch ${INSTALL_DIR}/${JAVA} ${INSTALL_DIR}/${INPUT1} >> ${LOGFILE}

echo ENDTIME `date` >> TIMELOG

#module unload ${HPCX}/../modulefiles/hpcx

# copy files to job directry
echo "${FILE}.o${PBS_JOBID%%.*}" > ${INSTALL_DIR}/${PBS_JOBID%%.*}/PBSLOGFILE
mv ${INSTALL_DIR}/Tate_temp ${INSTALL_DIR}/${PBS_JOBID%%.*}/
mv ${INSTALL_DIR}/temp_danmen2 ${INSTALL_DIR}/${PBS_JOBID%%.*}/
mv ${INSTALL_DIR}/temp_danmen3 ${INSTALL_DIR}/${PBS_JOBID%%.*}/
mv ${INSTALL_DIR}/velocity_danmen ${INSTALL_DIR}/${PBS_JOBID%%.*}/
mv ${INSTALL_DIR}/velocity_danmen3 ${INSTALL_DIR}/${PBS_JOBID%%.*}/
mv ${INSTALL_DIR}/Modue_temp ${INSTALL_DIR}/${PBS_JOBID%%.*}/
mv ${INSTALL_DIR}/Yoko_temp ${INSTALL_DIR}/${PBS_JOBID%%.*}/
mv ${INSTALL_DIR}/Tamb ${INSTALL_DIR}/${PBS_JOBID%%.*}/
mv ${INSTALL_DIR}/temp_danmen ${INSTALL_DIR}/${PBS_JOBID%%.*}/

# compress job directry
echo "Compress PBS_JOBID....: ${PBS_JOBID%%.*}"
echo "${PBS_JOBID%%.*}" > ${INSTALL_DIR}/JOBID

/opt/pbs/bin/qsub ${INSTALL_DIR}/compress.sh

echo "end of script"
