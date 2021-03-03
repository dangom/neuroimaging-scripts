#!/usr/bin/env python3
"""
The information from the mcdat file.
           where:   n     = sub-brick index
                    roll  = rotation about the I-S axis }
                    pitch = rotation about the R-L axis } degrees counterclockwise
                    yaw   = rotation about the A-P axis }
                      dS  = displacement in the Superior direction  }
                      dL  = displacement in the Left direction      } mm
                      dP  = displacement in the Posterior direction }
                   rmsold = RMS difference between input brick and base brick
                   rmsnew = RMS difference between output brick and base brick

       ** roll  = shaking head 'no' left-right
       ** pitch = nodding head 'yes' up-down
       ** yaw   = wobbling head sideways (ear toward shoulder)
"""
import matplotlib.pyplot as plt
import pandas as pd
import sys


plt.rc("font", family="Roboto Condensed")
plt.rc("xtick", labelsize="small")
plt.rc("ytick", labelsize="small")
plt.rc("axes", labelsize="medium", titlesize="medium")


def read_afni(filename):
    x = pd.read_csv(
        filename,
        header=None,
        sep="\s+",
        usecols=range(1, 7),
        names=[
            "Roll (L-R)",
            "Pitch (Up-Down)",
            "Yaw (Ear-Shoulder)",
            "I-S",
            "L-R",
            "A-P",
        ],
    )
    return x


def plot_afni(x, out=None):
    def cm2inch(*tupl):
        inch = 2.54
        if isinstance(tupl[0], tuple):
            return tuple(i / inch for i in tupl[0])
        else:
            return tuple(i / inch for i in tupl)

    fig, (tra_ax, rot_ax) = plt.subplots(nrows=2, sharex=True, dpi=100)

    vols = x.shape[0]

    rot = x.loc[:, "Roll (L-R)":"Yaw (Ear-Shoulder)"]
    tra = x.loc[:, "I-S":"A-P"]

    rot.plot(ax=rot_ax, linewidth=1.5)
    tra.plot(ax=tra_ax, linewidth=1.5)

    rot_ax.text(
        0.01,
        0.95,
        "Rotation ($^\circ$)",
        transform=rot_ax.transAxes,
        weight=600,
        horizontalalignment="left",
        verticalalignment="top",
        size="medium",
    )

    rot_ax.set(ylim=[-1.25, 1.25])
    rot_ax.legend(loc="upper center", ncol=3, fontsize="x-small")
    tra_ax.set(ylim=[-1.25, 1.25], xlabel="Volumes")
    tra_ax.legend(loc="upper center", ncol=3, fontsize="x-small")

    tra_ax.text(
        0.01,
        0.95,
        "Translation (mm)",
        transform=tra_ax.transAxes,
        weight=600,
        horizontalalignment="left",
        verticalalignment="top",
        size="medium",
    )

    fig.suptitle("Motion Parameter Estimates", y=0.94)

    fig.tight_layout()
    fig.subplots_adjust(hspace=0.0)

    if out is not None:
        plt.savefig(out)


if __name__ == "__main__":
    name = sys.argv[1]
    out = sys.argv[2]
    x = read_afni(name)
    plot_afni(x, out)
