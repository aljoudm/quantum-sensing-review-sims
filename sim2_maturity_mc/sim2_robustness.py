"""SIM 2 (Python re-run) - robustness of the maturity ranking.
Inputs: agreed scores (Table II), first-round rater scores, r06 TRL lower bound.
Rank 1 = most mature; tied domains share the average rank.
"""
import numpy as np
D = ["Geophysics", "Biomedicine", "PNT", "RF", "Networked"]
TRL = np.array([1, 1, 1, 0, 0])                         # r06 Table VI, lower bound
J = np.array([[2, 3, 3, 2],                             # Field, Inc., Grp., Com. (agreed)
              [1, 3, 1, 2],
              [2, 2, 2, 1],
              [0, 2, 2, 0],
              [0, 1, 0, 0]])
R1 = np.array([[3, 3, 3, 3], [2, 3, 3, 2], [3, 3, 3, 2], [1, 2, 3, 0], [0, 3, 3, 0]])  # round 1, rater 1
R2 = np.array([[3, 1, 3, 2], [0, 2, 3, 2], [3, 2, 3, 1], [0, 1, 3, 0], [0, 0, 3, 0]])  # round 1, rater 2

def ranks(s):
    order = (-s).argsort(kind="stable"); r = np.empty(len(s)); i = 0
    ss = s[order]
    while i < len(s):
        j = i
        while j + 1 < len(s) and np.isclose(ss[j + 1], ss[i]): j += 1
        r[order[i:j + 1]] = (i + j) / 2 + 1; i = j + 1
    return r

def mc(p, mode, N=10000, seed=42, weights=True):
    rng = np.random.default_rng(seed)
    strict = np.zeros(5); tied = np.zeros(5); R = np.zeros((N, 5))
    for n in range(N):
        w = rng.dirichlet(np.ones(5)) if weights else np.full(5, 0.2)
        s = J.astype(float).copy()
        hit = rng.random(s.shape) < p
        if mode == "sym":
            step = rng.choice([-1, 1], size=s.shape)
            s = s + hit * step
            s = np.where(s < 0, 1, np.where(s > 3, 2, s))   # reflect at the bounds
        elif mode == "down":                                 # one-directional (lenient-rater) shift
            s = np.clip(s - hit, 0, 3)
        tot = w[0] * TRL + (s * w[1:]).sum(1)
        m = tot.max(); top = np.isclose(tot, m)
        if top.sum() == 1: strict[top] += 1
        else: tied[top] += 1
        R[n] = ranks(tot)
    return strict / N, tied / N, np.median(R, 0), np.percentile(R, 5, 0), np.percentile(R, 95, 0)

def show(name, res):
    st, ti, med, p5, p95 = res
    print(f"\n{name}")
    for k in range(5):
        print(f"  {D[k]:12s} P(strictly first) {st[k]:.3f}  P(tied first) {ti[k]:.3f}  median {med[k]:.2f} [{p5[k]:.1f}, {p95[k]:.1f}]")

if __name__ == "__main__":
    print("Equal-weight sums:", dict(zip(D, (TRL + J.sum(1)).tolist())))
    show("Weights only (no score changes)", mc(0.0, "sym"))
    show("Weights + symmetric +/-1, p = 0.20, reflected", mc(0.20, "sym"))
    show("Weights + symmetric +/-1, p = 0.45 (observed disagreement rate), reflected", mc(0.45, "sym"))
    show("Weights + one-directional -1, p = 0.45, clipped at 0", mc(0.45, "down"))
    for nm, M in [("rater 1", R1), ("rater 2", R2)]:
        tot = TRL + M.sum(1); print(f"\nRound-1 ranking, {nm}: sums {dict(zip(D, tot.tolist()))} ranks {dict(zip(D, ranks(tot.astype(float)).tolist()))}")
    d = (R1 - R2); print("\nSigned difference rater1 - rater2: mean", d.mean(), " disagreements", (d != 0).sum(), " rater 1 higher in", (d > 0).sum())
    from math import comb
    k = (d != 0).sum(); print("two-sided sign test p =", 2 * sum(comb(k, i) for i in range(k, k + 1)) / 2**k)
    S = J.copy(); S[2, 2] = 1; S[0, 2] = 2     # strict R4: PNT entangled clock and geophysics gradiometer not counted
    tot = TRL + S.sum(1); print("\nStrict reading of R4: sums", dict(zip(D, tot.tolist())), "ranks", dict(zip(D, ranks(tot.astype(float)).tolist())))

    # Additional checks quoted in the paper
    rng = np.random.default_rng(42); c = 0
    for n in range(10000):
        w = rng.dirichlet(np.ones(5)); t = w[0] * TRL + (J * w[1:]).sum(1); c += t[1] > t[2]
    print("\nWeights only: P(biomedicine above PNT) =", c / 10000)
    for k, nm in enumerate(["Field", "Inc.", "Grp.", "Com."]):
        t = TRL + np.delete(J, k, 1).sum(1); print(f"Leave out {nm}: ranks", dict(zip(D, ranks(t.astype(float)).tolist())))
    t = J.sum(1); print("Leave out TRL: ranks", dict(zip(D, ranks(t.astype(float)).tolist())))
    TRLu = np.array([2, 2, 2, 2, 2]); t = TRLu + J.sum(1); print("Upper TRL bound: ranks", dict(zip(D, ranks(t.astype(float)).tolist())))
    S = J.copy(); S[0, 0] -= 1; S[0, 1] -= 1; S[0, 2] -= 1; t = TRL + S.sum(1)
    print("Three one-point changes (geophysics field, incumbent, groups -1):", dict(zip(D, t.tolist())))
