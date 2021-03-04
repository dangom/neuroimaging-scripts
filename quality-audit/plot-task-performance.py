#!/usr/bin/env python3
"""
Here we plot the task performance by parsing the logfiles from my visual task program.

onset - time in seconds
duration - duration of event
sample - the current volume
trial_type - codes for what is in the logfile

TRIAL_TYPE contains DOT_FLIP, KEYPRESS, TRIGGER and FINISH

This will show intervals where there are more than two dot flips without a response.
"""
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


plt.rc("font", family="Roboto Condensed")
plt.rc("xtick", labelsize="small")
plt.rc("ytick", labelsize="small")
plt.rc("axes", labelsize="medium", titlesize="medium")


def read_task(name):
    t = pd.read_csv(name, delimiter="\t")
    return t


def check_presses(t):
    missed_presses = []
    onset = 0
    t_ = t.loc[t["trial_type"].isin(["DOT_FLIP", "KEYPRESS"])]
    # Each entry will be either a DOT_FLIP or a KEYPRESS
    for index, row in t_.iterrows():
        if row["trial_type"] == "DOT_FLIP":
            # If it is a dotflip, we store it's onset time
            if onset == 0:
                onset = row["onset"]
            # But if we already have an onset time of a previous flip stored, with no keypress in between,
            # then we missed a press.
            else:
                missed_presses.append(onset)
                onset = 0
        # If it is a keypress, then we reset our search for missed presses.
        else:
            onset = 0
    return missed_presses


def plot_task_performance(t, out=None):
    def cm2inch(*tupl):
        inch = 2.54
        if isinstance(tupl[0], tuple):
            return tuple(i / inch for i in tupl[0])
        else:
            return tuple(i / inch for i in tupl)

    flips = t["onset"][t["trial_type"] == "DOT_FLIP"]
    keypress = t["onset"][t["trial_type"] == "KEYPRESS"]
    triggers = t["onset"][t["trial_type"] == "TRIGGER"]

    time_between_presses = np.diff(keypress)
    missed_presses = check_presses(t)

    fig, ax = plt.subplots(dpi=300, figsize=cm2inch(9, 3.5))
    # ax.axis("off")

    for onset, time_between in zip(keypress[:-2], time_between_presses):
        if time_between > 5:
            v = ax.axvspan(onset, onset + time_between, color="red", alpha=0.6)

    try:  # Fails if there are no 5+ sec blocks of no response, since v above would not be defined.
        v.set_label("5sec+ w/o response")
    except:
        pass

    ax.set(ylim=[-0.1, 2 * np.pi], yticks=[], xlim=[0, triggers.values[-1] + 1])
    for i in missed_presses:
        h = ax.axvline(i, ymax=0.3, linewidth=0.5, color="r")

    try:
        h.set_label("Missed keypress")
    except:
        pass

    ax.legend(loc="upper right", fontsize="x-small", frameon=False)

    performance = t[t["trial_type"] == "FINISH"]["value"].values[0]
    ax.text(
        0.01,
        0.95,
        f"Hit Rate = {performance}",
        transform=ax.transAxes,
        weight=600,
        horizontalalignment="left",
        verticalalignment="top",
        size="medium",
    )

    ax.set_title("Task performance")

    fig.tight_layout()
    if out is not None:
        plt.savefig(out)


if __name__ == "__main__":
    name = sys.argv[1]
    out = sys.argv[2]
    t = read_task(name)
    if t[t["trial_type"] == "FINISH"].any().values.sum() == 0:
        print(f"Apparently incomplete run for file {name}")
    else:
        plot_task_performance(t, out)
