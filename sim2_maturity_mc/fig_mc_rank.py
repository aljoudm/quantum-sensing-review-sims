"""Fig. 2: probability that each domain ranks strictly first under three perturbation models."""
import numpy as np, matplotlib
matplotlib.use("Agg"); import matplotlib.pyplot as plt
from sim2_robustness import mc, D
runs = [("random weights, $\\pm$1 with $p=0.20$", mc(0.20, "sym")[0]),
        ("random weights, $\\pm$1 with $p=0.45$", mc(0.45, "sym")[0]),
        ("random weights, $-$1 with $p=0.45$", mc(0.45, "down")[0])]
plt.rcParams.update({"font.family": "serif", "font.serif": ["DejaVu Serif"], "mathtext.fontset": "dejavuserif",
                     "font.size": 7.5, "axes.linewidth": 0.6})
fig, ax = plt.subplots(figsize=(3.45, 1.55))
lab = ["Geophysics", "Biomedicine", "PNT", "RF, radar, comm.", "Networked"]
y = np.arange(5); h = 0.27
cols = ["0.15", "0.55", "0.85"]; hatch = ["", "", "////"]
for i, (name, st) in enumerate(runs):
    b = ax.barh(y + (i - 1) * h, st, h, color=cols[i], edgecolor="0.15", lw=0.4, hatch=hatch[i], label=name)
    for yy, v in zip(y + (i - 1) * h, st):
        pass
ax.set_yticks(y); ax.set_yticklabels(lab); ax.invert_yaxis()
ax.set_xlim(0, 1.0); ax.grid(axis="x", color="0.85", lw=0.4); ax.set_axisbelow(True); ax.set_xlabel("Probability of ranking strictly first")
ax.legend(loc="lower right", frameon=False, fontsize=5.8, handlelength=1.4)
for s in ("top", "right"): ax.spines[s].set_visible(False)
fig.tight_layout(pad=0.2)
fig.savefig("../figures/fig_mc_rank.pdf", bbox_inches="tight", pad_inches=0.02)
fig.savefig("../figures/fig_mc_rank.png", dpi=200, bbox_inches="tight", pad_inches=0.02)
print([ (n, np.round(s,3).tolist()) for n,s in runs])
