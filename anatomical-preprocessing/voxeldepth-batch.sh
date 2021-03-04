#!/usr/bin/env bash
# Run the script voxeldepth on all functional files and save them as depth files.
# Usage: voxeldepth-batch.sh &
# Strict mode
set -euo pipefail
IFS=$'\n\t'


function get_registration_for_functional (){
    local functional=${1:-}
    reg=${functional/bold_tmean.nii.gz/from-BOLD_to-T1w_xfm.dat}
    echo "$reg"
}

SUBJECTS_DIR=/cluster/osc/data/pilot-oscm/derivatives/freesurfer
test -d $SUBJECTS_DIR


DERIV_DIR=/cluster/osc/data/pilot-oscm/derivatives

for subject in {01..04}; do
    subject_id="sub-${subject}"
    for functional in ${DERIV_DIR}/sub-${subject}/func/*preproc-stcmcf_bold_tmean.nii.gz; do
        funcdir=$(dirname $functional)
        funcname=$(basename $functional)
        outstem=${funcname/preproc-mcf_bold_tmean.nii.gz/depth}
        registration=$(get_registration_for_functional $functional)
        test -d $SUBJECTS_DIR || echo "$SUBJECTS_DIR does not exist."
        test -f $functional || echo "$functional does not exist."
        test -f $registration || (echo "$registration does not exist." && continue)

        test -f ${funcdir}/${outstem/depth/depth_lh.nii} && (echo "DATASET ALREADY PROCESSED." && continue)

        # Compute the relative voxel depth for this particular functional run.
        mris_voxeldepth $SUBJECTS_DIR $subject_id $functional $registration $outstem &
        # Now merge the left and right hemispheres.
        # fslmaths ${funcdir}/${outstem/depth/depth_lh.nii} -add ${funcdir}/${outstem/depth/depth_lh.nii} ${funcdir}/${outstem}
        # imrm ${funcdir}/${outstem/depth/depth_lh.nii} ${funcdir}/${outstem/depth/depth_lh.nii}
    done
done


