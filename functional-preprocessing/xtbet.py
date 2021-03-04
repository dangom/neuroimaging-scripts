#!/usr/bin/env python
"""
Create an EPI mask by clustering the time-series into two components.
"""
import argparse
from tslearn.clustering import TimeSeriesKMeans
from tslearn.utils import to_time_series_dataset
from nilearn import input_data, image

def cli_parser():

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="Name of input file")
    parser.add_argument("output", help="Name of mask file")


    return parser

def run():
    parser = cli_parser()
    args = parser.parse_args()

    nii = image.index_img(args.input, slice(0, 30))
    masker = input_data.NiftiMasker()
    data = masker.fit_transform(nii)
    ds = to_time_series_dataset(data.T[::80,:])

    model= TimeSeriesKMeans(n_clusters=2, metric="dtw", max_iter=15)
    model.fit(ds)

    all = to_time_series_dataset(data.T)

    mask = model.predict(all)
    mask_nii = masker.inverse_transform(mask)
    mask.nii.to_filename(args.output)
