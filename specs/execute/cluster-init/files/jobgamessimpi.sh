#!/usr/bin/bash 
#PBS -j oe
#PBS -l select=2:ncpus=42

cd scr
cp ~/apps/gamess-impi/tests/standard/exam01.inp .
~/apps/gamess-impi/rungms exam01.inp 00 44 44 >& exam01.out

