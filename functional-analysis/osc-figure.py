#!/usr/bin/env python
"""
Given a subject folder, generate an oscillations figure.
"""

import os
import os.path as op
from nilearn import image, input_data, plotting
import pandas as pd
import numpy as np
from glob import glob
import matplotlib.pyplot as plt
import seaborn as sns
import argparse


def cli_parser():

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", help="Name of subject directory")
    parser.add_argument("output", help="Name of output figure")
    parser.add_argument("--nvox", help="Number of voxels over which to calculate oscillations", type=int, default=1000)

    return parser

def run():

    parser = cli_parser()
    args = parser.parse_args()

    os.chdir(args.root)
    files = sorted(glob("*.feat"))
    dfs = {}
    for f in files:
        root = f[:29]
        dfs[root] = get_highest_activation(root, args.nvox)


    fig, axes = plt.subplots(nrows=5, ncols=4, dpi=300, figsize=plt.figaspect(1/3.5))

    axes = axes.T
    for i, ax in enumerate(axes.flatten()):
        for spine in ("top", "bottom", "left", "right"):
            ax.spines[spine].set_visible(False)
        if i>=5:
            ax.set_yticks([])

        ax.set_xticks([])
        ax.set(ylim=[-15, 15])

    def plotter(data, ax, color=None):
        if color is None:
            sns.lineplot(data=data, x="time", y="psc", ci="sd", ax=ax)
        else:
            sns.lineplot(data=data, x="time", y="psc", ci="sd", ax=ax, color=color)
        ax.set(ylim=[-15, 15]) # title=root[5::16],

    def avg(freq, runs):
        df_avg = dfs[f'task-0p{freq}_run-01_bold_antsmcf'].copy()

        if runs > 1:
            for i in range(2, runs+1):
                df_avg["psc"] += dfs[f'task-0p{freq}_run-0{i}_bold_antsmcf']["psc"]

        df_avg["psc"] /= runs
        return df_avg

    plotter(dfs['task-0p05_run-01_bold_antsmcf'], axes[0, 0])
    plotter(dfs['task-0p10_run-01_bold_antsmcf'], axes[1, 0])
    plotter(dfs['task-0p10_run-02_bold_antsmcf'], axes[1, 1])
    plotter(dfs['task-0p16_run-01_bold_antsmcf'], axes[2, 0])
    plotter(dfs['task-0p16_run-02_bold_antsmcf'], axes[2, 1])
    plotter(dfs['task-0p16_run-03_bold_antsmcf'], axes[2, 2])
    plotter(dfs['task-0p20_run-01_bold_antsmcf'], axes[3, 0])
    plotter(dfs['task-0p20_run-02_bold_antsmcf'], axes[3, 1])
    plotter(dfs['task-0p20_run-03_bold_antsmcf'], axes[3, 2])
    plotter(dfs['task-0p20_run-04_bold_antsmcf'], axes[3, 3])
    plotter(avg("05", 1), axes[0, 4], color="red")
    plotter(avg("10", 2), axes[1, 4], color="red")
    plotter(avg("16", 3), axes[2, 4], color="red")
    plotter(avg("20", 4), axes[3, 4], color="red")

    fig.suptitle(f"Oscillations - Top {args.nvox/1000} ml of active voxels")
    fig.tight_layout()
    fig.patch.set_facecolor('w')
    fig.savefig(args.output)


def get_highest_activation(root, nvox=1000):
    stats_file = op.join(root + ".feat", "stats", "zfstat1.nii.gz")
    epi_file = op.join(root + ".nii.gz")
    stats = image.load_img(stats_file)
    masker = input_data.NiftiMasker()
    stats_data = masker.fit_transform(stats)
    top_indices = np.argpartition(stats_data[0,:], -nvox)[-nvox:]
    target_mask = np.zeros_like(stats_data)
    target_mask[0, top_indices] = 1
    target_mask = masker.inverse_transform(target_mask)
    masker = input_data.NiftiMasker(mask_img=target_mask, standardize="psc")
    ts = masker.fit_transform(image.load_img(epi_file))
    df = pd.DataFrame(ts).melt().rename(columns={"variable": "voxel", "value": "psc"})
    df["time"] = [0.874 * (float(i)%ts.shape[0]) for i in df.index]
    return df

if __name__ == "__main__":
    run()
