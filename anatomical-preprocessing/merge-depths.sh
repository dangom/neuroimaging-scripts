#!/usr/bin/env bash

# Usage merge-depths.sh lh
for file in sub-*/func/*_lh.nii; do fslmaths $file -max ${file/lh/rh} ${file/_tmean.nii.gz_lh.nii/depth.nii.gz}& ; done
