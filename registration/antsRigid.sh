#!/usr/bin/env bash
target=$1
moving=$2
output=$3

antsRegistration --dimensionality 3 --float 0 --verbose 1 \
  --output [$output,${output}.nii.gz] \
  --interpolation LanczosWindowedSinc \
  --winsorize-image-intensities [0.005,0.995] \
  --use-histogram-matching 0 \
  --initial-moving-transform [$target,$moving,1] \
  --transform Rigid[0.1] \
  --restrict-deformation 1x1x1x1x1x1 \
  --metric MI[ ${target},${moving},1,64, None ] \
  --convergence [ 500x500x500x500x500x500x500x500x500x225x75x25,1e-6,10 ] \
--shrink-factors 5x5x5x5x5x5x5x5x4x3x2x1 \
--smoothing-sigmas 5.078205771322212x4.651927085986457x4.225322606736783x3.798282560433022x3.370641399941647x2.942137020149432x2.5123277660148595x2.0804050381276458x1.6447045940431997x1.2011224087864498x0.735534255037358x0.0mm \
