#!/bin/bash

# Safety precautions
# Using a variable that is not set will raise an error
set -o nounset
# Exit if a command fails.
set -o errexit

# runbatchfsl
FSLDATADIR=/cluster/osc/data/fhr-osc/analysis/artefact0p16
mkdir -p $FSLDATADIR



for INPUTFILE in $(ls /cluster/osc/data/fhr-osc/experiment-datasets/*/func/task*antsmcf.nii.gz);
do
    PERIOD=6.25
    PHASESIN=-4.6875
    PHASECOS=-3.125

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
            -e 's@PERIOD@'$PERIOD'@g' \
            -e 's@PHASESIN@'$PHASESIN'@g' \
            -e 's@PHASECOS@'$PHASECOS'@g' \
     < /cluster/osc/data/fhr-osc/code/template.fsf > "$OUTFSF"


  echo Running Feat on ${INPUTFILE}
  # feat "$OUTFSF" &
done
