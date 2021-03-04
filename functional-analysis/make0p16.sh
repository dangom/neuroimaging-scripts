#!/usr/bin/env bash

INPUTFILE=$1
INPUTSANSEXT=${INPUTFILE/d.nii.gz/d}

PERIOD=6.25
PHASESIN=-4.6875
PHASECOS=-3.125

calc(){ awk "BEGIN { print "$*" }"; }
TRms=$(mri_info --tr ${INPUTFILE})
TR=$(calc "${TRms}/1000")
NVOLS=$(fslnvols $INPUTFILE)
TOTALVOXELS=$(fslstats $INPUTFILE -v | awk '{print $1}')

echo $TR $NVOLS $TOTALVOXELS
echo $INPUTSANSEXT

# This could be accomplished with setFEAT as well.
sed -e 's@INPUTFILE@'$INPUTFILE'@g' \
    -e 's@PERIOD@'$PERIOD'@g' \
    -e 's@PHASESIN@'$PHASESIN'@g' \
    -e 's@PHASECOS@'$PHASECOS'@g' \
    -e 's@TRINSEC@'$TR'@g' \
    -e 's@NVOLUMES@'$NVOLS'@g' \
    -e 's@TOTALVOXELS@'$TOTALVOXELS'@g' \
< /cluster/osc/data/fhr-osc/code/template0p16.fsf > ${INPUTSANSEXT}.fsf
