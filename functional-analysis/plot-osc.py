#!/usr/bin/env python3

import niutils
import sys
import os.path as op
from nilearn import image, input_data
import matplotlib.pyplot as plt

if __name__ == "__main__":

    data = sys.argv[1]
    oscdir = sys.argv[2]
    transientdir = sys.argv[3]
    img = image.load_img(data)

    oscmask = op.join(oscdir,"stats", "zfstat1.nii.gz")
    transientmask = op.join(transientdir, "stats", "zfstat1.nii.gz")

    oscmask_ = niutils.bin_img(oscmask, threshold=3.1)
    transientmask_ = niutils.bin_img(transientmask, threshold=3.1)

    oscmasker = input_data.NiftiMasker(mask_img=oscmask_, standardize="psc")
    transientmasker = input_data.NiftiMasker(mask_img=transientmask_, standardize="psc")

    oscts = oscmasker.fit_transform(img)
    transientts = transientmasker.fit_transform(img)

    fig, ax = plt.subplots()

    ax.text(
        0.01,
        0.95,
        f"{data}",
        transform=ax.transAxes,
        weight=600,
        horizontalalignment="left",
        verticalalignment="top",
        size="medium",
    )

    plt.plot(oscts.mean(1), label="Sin/cos")
    plt.plot(transientts.mean(1), label="Transient")
    plt.legend()
    plt.savefig(sys.argv[4])

