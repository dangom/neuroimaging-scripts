#!/bin/bash

# Safety precautions
# Using a variable that is not set will raise an error
set -o nounset
# Exit if a command fails.
set -o errexit

# runbatchfsl
FSLDATADIR=/cluster/osc/data/fhr-osc/analysis/ica
mkdir -p $FSLDATADIR



for INPUTFILE in $(ls /cluster/osc/data/fhr-osc/experiment-datasets/*/func/task*antsmcf.nii.gz);
do
    case $INPUTFILE in
        *0p05*)
            PERIOD=20
            PHASESIN=-15
            PHASECOS=-10
            ;;
        *0p10*|*0p1_*)
            PERIOD=10
            PHASESIN=-7.5
            PHASECOS=-5
            ;;
        *0p16*)
            PERIOD=6.25
            PHASESIN=-4.6875
            PHASECOS=-3.125
            ;;
        *0p20*|0p2_*)
            PERIOD=5
            PHASESIN=-3.75
            PHASECOS=-2.5
            ;;
    esac

    case $INPUTFILE in
        *fhr-osc01*)
            SUBJECT=sub-01
            ;;
        *fhr-osc02*)
            SUBJECT=sub-02
            ;;
        *fhr-osc03*)
            SUBJECT=sub-03
            ;;
	*fhr-osc04*)
	    SUBJECT=sub-04
	    ;;
    esac

    OUTFSF=${FSLDATADIR}/${SUBJECT}_$(basename $INPUTFILE).fsf

        sed -e 's@INPUTFILE@'$INPUTFILE'@g' \
     < /cluster/osc/data/fhr-osc/code/template-ica.fsf > "$OUTFSF"


  echo Running Feat on ${INPUTFILE}
  # feat "$OUTFSF" &
done
