"""SIM 1 - Navigation error growth: where the quantum benefit lands.

Illustrative single-axis analytic error budget, r43 Eq. (31) (after Titterton & Weston):
  accelerometer term  e_a(t) = B_a (1 - cos wS t) / wS^2          (bounded Schuler oscillation)
  gyroscope term      e_g(t) = B_Om R (t - sin(wS t)/wS)           (unbounded growth)
The two terms come from independent biases and are combined as a root sum of squares (RSS).
Every parameter is annotated with its source key.
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

g = 9.81                         # m/s^2, standard gravity (unit conversion)
R = 6.371e6                      # m, Earth radius; r43: R "typically the radius of the Earth"
TS = 84.4 * 60.0                 # s, Schuler period, r45
wS = 2 * np.pi / TS
ug = 1e-6 * g

def acc_term(Ba, t):  return Ba * (1 - np.cos(wS * t)) / wS**2
def gyro_term(B, t):  return B * R * (t - np.sin(wS * t) / wS)
def total(Ba, B, t):  return np.hypot(acc_term(Ba, t), gyro_term(B, t))

GYRO_AV = 0.05e-6                # rad/s; r44 Table 1 lists "0.05 micro-radians", interpreted as a rate (about 0.01 deg/h)
S = {
    "S1": dict(Ba=30 * ug,   B=GYRO_AV, label="S1 aviation-grade INS"),          # r44 Table 1 (simulation inputs)
    "S2": dict(Ba=0.89 * ug, B=GYRO_AV, label="S2 accel. 0.89 µg"),        # r45 RMS tracking error, lab
    "S3": dict(Ba=6e-8 * g,  B=GYRO_AV, label="S3 accel. 6×10⁻⁸ g"),  # r20 bias stability, static lab
    "S4": dict(Ba=30 * ug,   B=1e-9,    label="S4 gyro. 1 nrad/s"),              # r46 rotation stability, lab
    "S5": dict(Ba=6e-8 * g,  B=1e-9,    label="S5 = S3 + S4"),
}

def red(k, t):  # percentage reduction relative to S1
    return 100 * (1 - total(S[k]["Ba"], S[k]["B"], t) / total(S["S1"]["Ba"], S["S1"]["B"], t))

t = np.logspace(np.log10(60), np.log10(36000), 4000)
tm = t / 60
cross = t[np.argmax(gyro_term(GYRO_AV, t) > acc_term(30 * ug, t))] / 60
tt = np.linspace(60, 36000, 400000)
r3 = red("S3", tt)

print("VERIFICATION / NUMBERS QUOTED IN THE PAPER")
print(f"Schuler amplitude for 10 ug bias (Ba/wS^2): {10*ug/wS**2:.1f} m (r45: ~60 m)")
print(f"gyro term exceeds accel term after {cross:.1f} min")
for s in (60, 300, 600, 1000, 3600, 4*3600, 36000):
    print(f"t={s:6d} s: " + " ".join(f"{k} {total(v['Ba'], v['B'], s):9.1f} m" for k, v in S.items())
          + " | red. S3 %.1f%%, S4 %.1f%%, S5 %.1f%%" % (red("S3", s), red("S4", s), red("S5", s)))
print(f"S3 reduction falls below 50% after {tt[np.argmax(r3 < 50)]/60:.1f} min and below 10% after {tt[np.argmax(r3 < 10)]/60:.1f} min")
m = tt >= 4*3600; print(f"max S2/S3 reduction between 4 and 10 h: {red('S2', tt[m]).max():.2f}% / {r3[m].max():.2f}%")
cl = 50 * 6e-8 * g               # classical triad implied by r20's 50-fold gain
for s in (60, 300, 600):
    print(f"[r20 claim] 50-fold bias gain -> position-error ratio at {s:4d} s: aviation gyro {total(cl, GYRO_AV, s)/total(6e-8*g, GYRO_AV, s):.1f}x, 1 nrad/s gyro {total(cl, 1e-9, s)/total(6e-8*g, 1e-9, s):.1f}x")
print(f"gyro 0.05 urad/s = {GYRO_AV*180/np.pi*3600:.4f} deg/h")

plt.rcParams.update({"font.family": "serif", "font.serif": ["DejaVu Serif"], "mathtext.fontset": "dejavuserif",
                     "font.size": 7.5, "axes.linewidth": 0.6, "lines.linewidth": 1.1})
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(3.45, 3.25), sharex=True)
sty = {"S1": ("k", "-"), "S3": ("0.45", "--"), "S4": ("k", "-."), "S5": ("0.45", ":")}
for k, (c, ls) in sty.items():
    ax1.loglog(tm, total(S[k]["Ba"], S[k]["B"], t), color=c, ls=ls, label=S[k]["label"])
ax1.set_ylabel("Position error (m)"); ax1.set_ylim(1e-2, 3e4)
ax1.legend(loc="lower left", bbox_to_anchor=(0.0, 1.0), ncol=2, frameon=False, fontsize=6, borderaxespad=0.1, columnspacing=0.8, handlelength=2.2)
ax1.text(0.02, 0.86, "(a)", transform=ax1.transAxes)
for k, (c, ls), lab in [("S3", ("0.45", "--"), "accelerometer (S3)"), ("S4", ("k", "-."), "gyroscope (S4)"), ("S5", ("0.45", ":"), "both (S5)")]:
    ax2.semilogx(tm, red(k, t), color=c, ls=ls, label=lab)
for ax in (ax1, ax2):
    ax.axvline(cross, color="0.6", lw=0.6, ls=(0, (1, 2)))
ax1.text(cross * 1.1, 0.06, "gyro. term exceeds\naccel. term (26 min)", fontsize=5.8, color="0.35", va="center")
ax2.set_ylabel("Error reduction vs S1 (%)"); ax2.set_ylim(-3, 103)
ax2.set_xlabel("Time without position fix (min)"); ax2.set_xlim(1, 600)
ax2.set_xticks([1, 10, 60, 600]); ax2.set_xticklabels(["1", "10", "60", "600"])
ax2.legend(loc="lower left", frameon=False, fontsize=6, handlelength=2.2)
ax2.text(0.93, 0.45, "(b)", transform=ax2.transAxes)
fig.tight_layout(h_pad=0.4)
fig.savefig("../figures/fig_nav_error.pdf", bbox_inches="tight", pad_inches=0.02)
fig.savefig("../figures/fig_nav_error.png", dpi=200, bbox_inches="tight", pad_inches=0.02)
print("saved figures/fig_nav_error.pdf")
