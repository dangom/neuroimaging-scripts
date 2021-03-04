#!/usr/bin/bash

# Safety precautions
# Using a variable that is not set will raise an error
set -o nounset
# Exit if a command fails.
set -o errexit

function echo_help {
    echo "Humane wrapper to ANTs Motion Correction"
    echo "Usage: concat_moco_affine.sh input mocowarp affine reference"
    echo "Outputs the input with a suffix space-fov.nii.gz"
    echo "Concatanates and applies motion correction and affine in a single step."
}

if (($# < 1))
then
    echo_help
    exit 0
fi

fmri=$1
mocowarp=$2
affine=$3
ref=$4

tr=$(PrintHeader $fmri | grep "Voxel Spac" | cut -d ',' -f 4 | cut -d ']' -f 1)
nvols="$(($(fslnvols $fmri)-1))"

tmpfmri=$(mktemp -d)
fslsplit $fmri ${tmpfmri}/ -t

tmpwarp=$(mktemp -d)
fslsplit $mocowarp ${tmpwarp}/ -t

tmpout=$(mktemp -d)
parallel -j 4 antsApplyTransforms -d 3 -r $ref \
         -o $tmpout/{1}.nii.gz -n LanczosWindowedSinc -i $tmpfmri/{1}.nii.gz \
         -t $tmpwarp/{1}.nii.gz -t $affine -v 1 ::: $(seq -f "%04g" $nvols)


fslmerge -tr ${fmri/.nii.gz/space-fov.nii.gz} ${tmpout}/* $tr
exit 0

