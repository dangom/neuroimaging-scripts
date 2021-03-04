#!/bin/bash
# Usage motion-correct.sh input

set -e

# Use mc-afni2 to motion correct a dataset.
input=$1
inputdir=$(dirname $input)
inputfile=$(basename $input)
if [[ $inputfile == *"preproc-stc"* ]]; then
    output=${inputdir/experiment-datasets/derivatives}/${inputfile/preproc-stc/preproc-stcmcf}
else
    output=${inputdir/experiment-datasets/derivatives}/${inputfile/bold/preproc-mcf_bold}
fi

# echo $input $output
mc-afni2 --i "${input}" --frame $(( $(fslnvols "${input}")/2 )) --o "${output}"
