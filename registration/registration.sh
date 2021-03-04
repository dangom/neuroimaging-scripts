#!/bin/bash
# Register moving file to anatomical via a whole brain reference image.
# Usage: registration.sh $moving $wbref

# Safety precautions
# Using a variable that is not set will raise an error
set -o nounset
# Exit if a command fails.
set -o errexit

# Assumes that the FreeSurfer recon follows the same name as the initials of the input file.
# And also assumes that SUBJECTS_DIR is set correctly.

usage() {
    echo "Register BOLD to anatomical using bbregister."
    echo "Does not perform resampling - only outputs the transformation files."
    echo ""
    echo "Usage: registration.sh bold"
    echo ""
    echo ""
    echo "Assumes:"
    echo ""
    echo "0. FreeSurfer surfaces have already been reconstructed via recon-all."
    echo "1. SUBJECTS_DIR is correctly set before this command is called."
    echo "2. Moving dataset has been motion corrected and is named according to BIDS."
    echo "3. Fixed is a large FOV BOLD reference image."
}

if [ $# -lt 1 ] ; then
    usage
    exit 0
fi

# Check that we did change freesurfer dir
if [[ $SUBJECTS_DIR == *"/usr/local/freesurfer"* ]]; then
    echo "SUBJECTS DIR seems to point to freesurfer. This looks wrong. Bailing out."
    exit 1
fi

moving=$1

# 0. Check that files exist and are OK.
moving=$1
if ! test -f "$moving"; then
    echo "moving does not exist."
    exit 1
fi


# 0a. Files must be BOLD and motion corrected, because we will compute the registration on the mean.
if [[ $moving != *"bold"* ]]; then
    echo "The moving image is not a bold image. That's not good."
    exit 1
fi


if [[ $moving != *"mcf"* ]]; then
    echo "The moving EPI target was not motion corrected. Do that first."
    exit 1
fi


# 1. Get the subject ID
movingbasename=$(basename "$moving")
subjectid=${movingbasename:0:6}

# 2. Generate a temporary mean file from moving.
meanfile=$(mktemp).nii.gz

# Posix way of substituting in string
regname=$(echo "$moving" | sed "s/bold.nii.gz/from-BOLD_to-T1w_xfm.dat/")
# bash for my own personal reference. String substitution
# regname=${moving/bold.nii.gz/from-BOLD_to-T1w.xfm}

# echo "moving is " $moving
# echo "fixed is " $fixed
# echo "movingbasename is " $movingbasename
# echo "subjectid is " $subjectid
# echo "regname is " $regname
# echo "meanfile is" $meanfile
# echo "meanwbref is" $meanwbref

fslmaths "$moving" -Tmean "$meanfile"
bbregister --s "$subjectid" --mov "$meanfile" --reg "$regname" --bold
