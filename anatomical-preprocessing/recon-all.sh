#!/usr/bin/env bash
# Daniel Gomez Sept 11 2019

## Meta config
# Email to notify when recon-all completes
MAILADDRESS="dgomez1@mgh.harvard.edu"
# Expert file with advanced configuration
EXPERT_FILE="/cluster/visuo/users/anna/scripts/expert_075.txt"

## Project config
# The freesurfer output directory
SUBJECTS_DIR="/cluster/osc/data/fhr-osc/freesurfer"

## Subject specific config
SUBJID=$1
COMBINED_MEMPRAGE="/cluster/osc/data/fhr-osc/experiment-datasets/${SUBJID}/anat/memprage_acq-520v_preproc-bico_T1w.nii.gz"

## RECON-ALL
recon-all -sd ${SUBJECTS_DIR} -subjid $SUBJID -i ${COMBINED_MEMPRAGE} -openmp 8 -hires -mail $MAILADDRESS -expert ${EXPERT_FILE}  -all
send-sms.py "Recon-all just finished for subject $SUBJID." 
