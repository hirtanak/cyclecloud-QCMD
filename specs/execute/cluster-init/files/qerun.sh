# Sample script for QuantumESPRESSO
# Copyright (c) 2019-2022 Hiroshi Tanaka, hirtanak@gmail.com @hirtanak
# Licensed under the MIT License.

#!/bin/bash
#PBS -j oe
#PBS -l select=2:ncpus=15
NP=30

QE_DIR=q-e-qe-7.0
MPI=$(ls -d /opt/openmpi*)
MPI_ROOT=${MPI}

# モデルダウンロード
# http://www.cmpt.phys.tohoku.ac.jp/~koretsune/SATL_qe_tutorial/graphene_banddos.html
rm ~/test/C.pz-van_ak.UPF
wget -P ~/test http://www.cmpt.phys.tohoku.ac.jp/~koretsune/SATL_qe_tutorial/files/C.pz-van_ak.UPF
wget -P ~/test http://www.cmpt.phys.tohoku.ac.jp/~koretsune/SATL_qe_tutorial/files/graphene_band/graphene.scf.in

mkdir -p ~/test
cd ~/test/
time ${MPI_ROOT}/bin/mpirun --hostfile ${PBS_NODEFILE} -n $NP ~/${QE_DIR}/bin/pw.x < ~/test/graphene.scf.in | tee graphene-scf-$(date "+%Y%m%d_%H%M").log

# band
#wget -P ~/test http://www.cmpt.phys.tohoku.ac.jp/~koretsune/SATL_qe_tutorial/files/graphene_band/graphene.nscf.in
#time ${MPI_ROOT}/bin/mpirun --hostfile ${PBS_NODEFILE} -n $NP ~/${QE_DIR}/bin/pw.x < ~/test/graphene.nscf.in | tee graphene-nscf-$(date "+%Y%m%d_%H%M").log
#wget -P ~/test http://www.cmpt.phys.tohoku.ac.jp/~koretsune/SATL_qe_tutorial/files/graphene_band/graphene.band.in
#time ${MPI_ROOT}/bin/mpirun --hostfile ${PBS_NODEFILE} -n $NP ~/${QE_DIR}/bin/bands.x < ~/test/graphene.band.in | tee graphene-band-$(date "+%Y%m%d_%H%M").log

###-----------GPU 
# download https://gitlab.com/QEF/q-e/-/issues/461#note_835837071
#wget -P ~/test https://gitlab.com/QEF/q-e/uploads/3fb967d55efc426a4053cfa84e5568b2/C_ONCV_PBE-1.2.upf
#wget -P ~/test https://gitlab.com/QEF/q-e/uploads/511c917cffef1948c37a5f79388e817c/Si_ONCV_PBE-1.2.upf
#wget -P ~/test https://gitlab.com/QEF/q-e/uploads/692a5896147c46a5631ee4f1fde96db3/pw.in

#time ${MPI_ROOT}/bin/mpirun --hostfile ${PBS_NODEFILE} -n $NP ~/${QE_DIR}/bin/pw.x -i ~/pw.in | tee pw-$(date "+%Y%m%d_%H%M").log


# download https://gitlab.com/QEF/q-e/-/issues/478

#time ${MPI_ROOT}/bin/mpirun --hostfile ${PBS_NODEFILE} -n $NP ~/${QE_DIR}/bin/pw.x -i ~/cp_test.in | tee cptest-$(date "+%Y%m%d_%H%M").log

