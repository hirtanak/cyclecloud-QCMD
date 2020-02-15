# Sample script for QuantumESPRESSO
# Copyright (c) 2019 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
# Licensed under the MIT License. 

#!/bin/bash
#PBS -j oe
#PBS -l select=2:ncpus=1
NP=2

source /etc/profile.d/qe.sh

INSTALL_DIR=/shared/home/azureuser/apps
HOSTDIR=/shared/home/azureuser

export I_MPI_FABRICS=shm:ofa # for 2019, use I_MPI_FABRICS=shm:ofi
source /opt/intel/impi/2019.5.281/intel64/bin/mpivars.sh

# you spin up execute node and create hosts file on home directory.

# pingpong
#/opt/intel/impi/2018.4.274/intel64/bin/mpirun -machinefile ${PBS_NODEFILE} hostname
#/opt/intel/impi/2018.4.274/intel64/bin/mpirun -machinefile ${PBS_NODEFILE} IMB-MPI1 pingpong

