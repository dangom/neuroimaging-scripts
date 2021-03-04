#!/bin/bash -p

# jonathan polimeni <jonp@nmr.mgh.harvard.edu>
# Thursday, September 12, 2013 21:17:37 -0400
# Tuesday, September 24, 2013 21:09:48 -0400
# Friday, January 31, 2014 18:42:53 -0500
# Sunday, November  2, 2014 22:40:57 -0500
# Friday, May 15, 2015 14:36:44 -0400

# sms_slicetime_correct.sh

# requires FreeSurfer tools "stc.fsl" and "mri_info",
# and FSL tools "fslsplit" and "fslmerge"

# *assumes* FSLOUTPUTTYPE is 'NIFTI_GZ'

version="0.6"

if [ $# -eq 0 ]; then
    echo "  usage:  `basename $0` MB instem outstem"
    exit 0
fi

# field "MosaicRefAcqTimes" in DICOM header field (0019,1029)

# dcmdump +L +C +P 0019,1029 dicomfile

# /usr/local/freesurfer/dev/bin/slicedelay:
#
##   if(order == "up"):   AnatSliceOrder = range(1,nslicespg+1,+1);
##   if(order == "down"): AnatSliceOrder = range(nslicespg,0,-1);
##   if(order == "odd"):  AnatSliceOrder = range(1,nslicespg+1,+2) + range(2,nslicespg+1,+2);
##   if(order == "even"): AnatSliceOrder = range(2,nslicespg+1,+2) + range(1,nslicespg+1,+2);
##   if(order == "siemens"):
##     if(nslicespg%2==1): # siemens-odd
##       AnatSliceOrder = range(1,nslicespg+1,+2) + range(2,nslicespg+1,+2);
##     else: # siemens-even
##       AnatSliceOrder = range(2,nslicespg+1,+2) + range(1,nslicespg+1,+2);


MB=$1

echo MB factor is ${MB}

infile=$2
instem=`echo $infile | sed - -e s/.gz$// | sed -e s/\.nii//`
outfile=$3
outstem=`echo $outfile | sed - -e s/.gz$// | sed -e s/\.nii//`


if [[ -z "$outstem" ]]; then
    outstem=${instem}_stc
    echo setting output to ${outstem}
fi

if [[ ${MB} -eq 1 ]]; then

    stc.fsl --i ${infile} --o ${outstem}.nii.gz --siemens

    exit 1
fi


outdir=`dirname ${outstem}`

Nslc=`mri_info --nslices ${infile}`
TRms=`mri_info --tr      ${infile}`

# note MB factor is same as Nslicegroups (i.e., groups of slices
# acquired simultaneously)

# assumes Nslc is divisible by MB
Ntimegroups=$[Nslc/MB]

# note: Ntimegroups is same as slices per group (spg)
remainder=`expr $Nslc - $[Ntimegroups * MB]`

if [[ $remainder -ne 0 ]]; then
    echo error
fi

# MGH SMS-EPI convention is to match the siemens convention: if the
# number of *reconstructed* slices is odd-valued then each slice group
# is acquired in order 1,3,5,...,2,4,...

# this implies that the shots (or slice groups) will be acquired in a
# different order for a 10-slice SMS2 acquisition and a 15-slice SMS3
# acquisition even though both use 5 shots.

# note: the CMRR SMS-EPI sequence has a more complicated ordering
# algorithm to prevent the two reconstructed slices that are
# physically adjacent from being excited sequentially in time. (the
# MGH strategy for avoiding this is to constrain the acquisition such
# that the number of shots is always odd-valued.)

isodd=$(( $Nslc % 2 ))

if [[ $isodd ]]; then
    orderflag='--odd'
else
    orderflag='--even'
fi


# TODO: while conceptually it is nice to split the file up based on
# slice groups, perhaps to save time and (temporary) disk space in
# future will just calculate the acquisition time for each slice and
# pass this directly to 'slicetimer.fsl'

tmpdir="${outdir}/.sms_slicetime_correct.tmp$$.`date +%s`"

mkdir -p ${tmpdir}

if [ "$?" -ne 0 ]; then
    exit 1
fi

echo -e '\nsplitting input data'
fslsplit ${infile} ${tmpdir}/${instem}__ -z


echo -e '\nperforming slice timing correction on slice-groups'
slicegroup_list=''
for slicegroup in `seq -f %3.0f 0 $(( ${MB} - 1 ))`; do
    echo -e "\nslicegroup ${slicegroup} of `printf %02.0f ${MB}`"

    firstslice=$(( ${Ntimegroups} * ${slicegroup} ))

    cmd="fslmerge -z ${tmpdir}/slicegroup_${slicegroup}.nii `seq -f '${tmpdir}/${instem}__%04.0f.nii.gz' ${firstslice} 1 $(( ${firstslice} + ${Ntimegroups} - 1 ))`"
    echo ${cmd}
    eval ${cmd}

    mkdir -p ${tmpdir}/tmp${slicegroup}

#    stc.fsl --i ${tmpdir}/slicegroup_${slicegroup}.nii.gz --o ${tmpdir}/slicegroup_${slicegroup}_stc.nii.gz --siemens --tmp ${tmpdir}/tmp${slicegroup}
#    stc.fsl --i ${tmpdir}/slicegroup_${slicegroup}.nii.gz --o ${tmpdir}/slicegroup_${slicegroup}_stc.nii.gz --even --tmp ${tmpdir}/tmp${slicegroup}
     stc.fsl --i ${tmpdir}/slicegroup_${slicegroup}.nii.gz --o ${tmpdir}/slicegroup_${slicegroup}_stc.nii.gz ${orderflag} --tmp ${tmpdir}/tmp${slicegroup}

    fslsplit ${tmpdir}/slicegroup_${slicegroup}_stc.nii.gz ${tmpdir}/slicegroup_${slicegroup}_stc__ -z

    slicegroup_list="${slicegroup_list} ${tmpdir}/slicegroup_${slicegroup}_stc__*"

done;

echo -e '\nre-merging corrected data'

#echo ${slicegroup_list}
fslmerge -z ${outstem} ${slicegroup_list}

rm -rfv ${tmpdir}/slicegroup* ${tmpdir}/${instem}__*
rmdir ${tmpdir}

exit 0

