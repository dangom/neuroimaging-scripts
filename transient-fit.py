import pickle
import pandas as pd
import seaborn as sns
import numpy as np

from symfit import Parameter, Variable, Fit, exp, sin, pi

# cd /cluster/osc/data/analysis/pickled_oscillations

def avg(dfs, freq):
    df_avg = dfs[f'task-0p{freq}_run-01_bold_antsmcf'].copy()
    runs_magic = {"05": 1, "10": 2, "16": 3, "20": 4}
    runs = runs_magic[freq]
    if runs > 1:
        for i in range(2, runs+1):
            df_avg["psc"] += dfs[f'task-0p{freq}_run-0{i}_bold_antsmcf']["psc"]

    df_avg["psc"] /= runs
    return df_avg

def avg_subs(freqname):
    sub_avg = avg(dfs["fhr-osc01a"], freqname)
    for sub in ("fhr-osc02a", "fhr-osc04a"):
            sub_other = avg(dfs[sub], freqname)
            sub_avg["psc"] += sub_other["psc"]

    sub_avg["psc"] /= 3  # Assumes 3 subjects.
    return sub_avg


for sub in ("fhr-osc01a", "fhr-osc02a", "fhr-osc04a"):
    files = glob(f"{sub}/*.pkl")
    dfs[sub] = {}
    for f in files:
        with open(f, "rb") as picklefile:
            dfs[sub][f[11:-4]] = pickle.load(picklefile)


a = Parameter("a", value=20, min=15, max=25)
b = Parameter("b", value=0.05, min=0.02, max=0.08)
c = Parameter("c", value=2, min=1, max=4)

phi = Parameter("phi", value=3.14, min=0, max=2*pi)
omega = Parameter("omega", value=3.14, min=0, max=2*pi)
x = Variable("x")
y = Variable("y")
delta = Parameter("delta", value=0)

tr = 0.874
real_time = np.arange(0, tr*330, tr)

df_avg_subs = {}
df_avg_subs["05"] = avg_subs("05")
df_avg_subs["10"] = avg_subs("10")
df_avg_subs["16"] = avg_subs("16")
df_avg_subs["20"] = avg_subs("20")

def fit_model(df_avg, frequency):

    Model = {y: a* exp(-b * x) + c * sin(2*pi*frequency*x + phi) + delta}
    avg_osc = df_avg.groupby("time").mean()["psc"]
    argmax_ind = avg_osc.values.argmax()
    ydata = avg_osc.values[argmax_ind:]
    xdata = real_time[argmax_ind:]
    sigma_y = df_avg.groupby("time").std()["psc"].values[argmax_ind:]

    fit = Fit(model, x=xdata, y=ydata, sigma_y=sigma_y)
    fit_result = fit.execute()
    yfit = model[y](x=xdata, **fit_result.params)
    return avg_osc, xdata, ydata, fit_result, yfit

fig, ax = plt.subplots(nrows=4, dpi=200, sharex=True)
for idx, (freqname, freq) in enumerate(zip(["05", "10", "16", "20"], [0.05, 0.10, 0.16, 0.2])):
    df_avg = df_avg_subs[freqname]
    avg_osc, xdata, ydata, fit_result, yfit = fit_model(df_avg, freq)
    print(freqname)
    sns.lineplot(data=df_avg, x="time", y="psc", ax=ax[idx])
    ax[idx].plot(xdata, yfit, alpha=0.8, linewidth=1.2)
    b_val = fit_result.value(b)
    ax[idx].set_title(f" {freq:.2} Hz - Transient decay time = {1/b_val:0.1f}s", fontdict={"fontsize": 8})
    # print(fit_result)

sns.despine()
plt.tight_layout()
