#!/bin/bash
#PBS -j oe
#PBS -l select=1:ncpus=120

LAMMPS_DIR=lammps-stable_29Sec2021_update2
MPI_ROOT=/opt/openmpi-4.1.0
cp ~/${LAMMPS_DIR}/examples/melt/in.* ~/

time ${MPI_ROOT}/bin/mpirun --hostfile ${PBS_NODEFILE} -n 120  ~/${LAMMPS_DIR}/bin/lmp < ~/in.melt | tee inmelt-$(date "+%Y%m%d_%H%M").log

# hpcx and kokkos
#HPCX_HOME=/opt/hpcx-v2.8.3-gcc-MLNX_OFED_LINUX-5.2-2.2.3.0-redhat7.7-x86_64
#INPUT=/shared/home/azureuser/try5-hpcx/in.tutorial_1_chon
#MODEL=tutorial_1_chon

#source ${HPCX_HOME}/hpcx-init.sh
#hpcx_load
#LD_LIBRARY_PATH=/opt/gcc-9.2.0/lib:${LD_LIBRARY_PATH}

#time ${HPCX_HOME}/ompi/bin/mpirun --hostfile ${PBS_NODEFILE} -n $NP --bind-to core ~/${LAMMPS_DIR}/bin/lmp-kokkos -k on t 4 -sf kk -in ${INPUT} | tee ~/${MODEL}-$(date "+%Y%m%d_%H%M").log

#hpcx_unload

# gpu

#time ${MPI_ROOT}/bin/mpirun --hostfile ${PBS_NODEFILE} -n 1  ~/${LAMMPS_DIR}/bin/lmp-gpu -in ~/in.melt -sf gpu -pk gpu 1 | tee inmelt-$(date "+%Y%m%d_%H%M").log

