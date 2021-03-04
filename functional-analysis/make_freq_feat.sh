#!/usr/bin/env bash
# Usage: make_freq_feat.sh 0.16 file.nii.gz

calc(){ awk "BEGIN { print "$*" }"; }

FREQ=$1

PERIOD=$(calc "1/${FREQ}")
PHASESIN=$(calc "-3*${PERIOD}/4")
PHASECOS=$(calc "-${PERIOD}/2")

INPUTFILE=$2
INPUTSANSEXT=${INPUTFILE/d.nii.gz/d}


TRms=$(mri_info --tr ${INPUTFILE})
TR=$(calc "${TRms}/1000")
NVOLS=$(fslnvols $INPUTFILE)
TOTALVOXELS=$(fslstats $INPUTFILE -v | awk '{print $1}')


OUTDIR="${INPUTSANSEXT}_${FREQ}".feat

sed -e 's@INPUTFILE@'$INPUTFILE'@g' \
    -e 's@PERIOD@'$PERIOD'@g' \
    -e 's@PHASESIN@'$PHASESIN'@g' \
    -e 's@PHASECOS@'$PHASECOS'@g' \
    -e 's@TRINSEC@'$TR'@g' \
    -e 's@NVOLUMES@'$NVOLS'@g' \
    -e 's@TOTALVOXELS@'$TOTALVOXELS'@g' \
    -e 's@OUTPUTDIR@'$OUTDIR'@g' \
< /cluster/osc/data/fhr-osc/code/template0p16.fsf > ${INPUTSANSEXT}_${FREQ}.fsf
