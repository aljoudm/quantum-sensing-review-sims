# Quantum Sensing Review: Simulations

Python and MATLAB simulations that produce the figures for an IEEE review paper on quantum sensing.

**Requirements:** Python 3, numpy, matplotlib (Simulations 1 and 2). Base MATLAB, R2025a or newer, for Simulations 3 and 4, the combined figure and the earlier MATLAB versions of Simulations 1 and 2.

- **No MATLAB toolbox is required.** The MATLAB helpers were tested with R2026a.
- **Sourced parameters.** Every parameter is taken from a cited source in the paper's `references.bib` (keys `r01`-`r52`).
- **MATLAB figure style.** MATLAB figures use `common/ieee_style.m` (3.5 in one-column width, Times New Roman 8 pt) and are exported with `common/save_ieee.m` to `figures/<name>.pdf` (vector) and `figures/<name>.png` (200 dpi). Each MATLAB script adds `../common` to the MATLAB path.

## Run order

Run the simulations in the order **1, 3, 4, 2**.

Run the Python scripts from inside their own folders. Run the MATLAB scripts from the repository root in batch mode. Adjust the MATLAB executable path if it is installed elsewhere. In PowerShell, put `&` in front of the quoted path.

## Layout

```
common/                  ieee_style.m, save_ieee.m
sim1_nav_error/          sim1_nav_error.py, results_sim1.txt  (earlier: sim1_nav_error.m)
sim2_maturity_mc/        sim2_robustness.py, fig_mc_rank.py, results_sim2_python.txt
                         (also: sim2_maturity_mc.m and its outputs)
sim3_squeezing_loss/     sim3_squeezing_loss.m
sim4_quantum_limit_gap/  sim4_quantum_limit_gap.m
data/                    data files read by the MATLAB version of Sim 2
figures/                 exported PDF and PNG figures
```

## Simulation 1: Navigation error

- **Version used in the paper:** `sim1_nav_error/sim1_nav_error.py`.
- **Model:** illustrative single-axis analytic error budget of Narducci et al. 2022 (`r43`), Eq. (31). The two terms come from independent biases and are combined as a root sum of squares (RSS):
  - accelerometer term `e_a(t) = B_a (1 - cos wS t) / wS^2` (bounded Schuler oscillation)
  - gyroscope term `e_g(t) = B_Om R (t - sin(wS t)/wS)` (unbounded growth)
- **Constants:**

  | Constant | Value | Source |
  |---|---|---|
  | Standard gravity `g` (unit conversion) | 9.81 m/s^2 | standard value |
  | Earth radius `R` | 6.371e6 m | `r43`: R "typically the radius of the Earth" |
  | Schuler period | 84.4 min | `r45` |

- **Scenarios:**

  | Scenario | Accelerometer bias | Source | Gyroscope bias | Source |
  |---|---|---|---|---|
  | S1 aviation-grade INS | 30 µg | `r44` Table 1 (simulation inputs) | 0.05 µrad/s | `r44` Table 1 (see note) |
  | S2 | 0.89 µg | `r45`, RMS tracking error, laboratory | 0.05 µrad/s | as S1 |
  | S3 | 6×10⁻⁸ g | `r20`, bias stability, static laboratory | 0.05 µrad/s | as S1 |
  | S4 | 30 µg | as S1 | 1 nrad/s | `r46`, rotation stability, laboratory |
  | S5 = S3 + S4 | 6×10⁻⁸ g | `r20` | 1 nrad/s | `r46` |

  Note: `r44` Table 1 lists "0.05 micro-radians", interpreted here as a rate (about 0.01 deg/h).
- **Figure:** (a) position error for S1, S3, S4 and S5; (b) error reduction of S3, S4 and S5 relative to S1. S2 appears in the printed results only.
- **How to run:**
  ```bash
  cd sim1_nav_error && python3 sim1_nav_error.py > results_sim1.txt
  ```
- **Output:** `figures/fig_nav_error.pdf` (and `.png`), `sim1_nav_error/results_sim1.txt`.
- **Earlier MATLAB version:** `sim1_nav_error.m` is superseded and kept for reference. `caption.txt` in the same folder describes that version. Running it overwrites `figures/fig_nav_error.*`.

## Simulation 3: Squeezing and loss

- **Purpose:** Loss model showing that detected squeezing is capped by detection efficiency, checked against two measured values.
- **How to run:**
  ```
  "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -batch "cd('sim3_squeezing_loss'); sim3_squeezing_loss"
  ```
- **Output:** `figures/fig_squeezing_loss.pdf` (and `.png`).

## Simulation 4: Quantum limit gap

- **Purpose:** Ratio of operating noise to the quantum limit for field-tested sensors.
- **How to run:**
  ```
  "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -batch "cd('sim4_quantum_limit_gap'); sim4_quantum_limit_gap"
  ```
- **Output:** `figures/fig_quantum_limit_gap.pdf` (and `.png`).

## Combined figure: Simulations 3 and 4

- **Purpose:** Panels (a) Sim 3 and (b) Sim 4 in one column-width figure. Both are re-plotted from the same data and plotting functions (`sim3_data.m`, `sim3_plot.m`, `sim4_data.m`, `sim4_plot.m`) as the individual figures.
- **How to run** (after Sim 3 and Sim 4, which print the verification tables):
  ```
  "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -batch "combine_loss_gap"
  ```
- **Output:** `figures/fig_loss_gap.pdf` (and `.png`).

## Simulation 2: Maturity ranking

Robustness of the maturity ranking of five application domains (Geophysics, Biomedicine, PNT, RF/radar/communications, Networked). Rank 1 is the most mature; tied domains share the average rank.

### Python robustness analysis (`sim2_robustness.py`)

The agreed scores, the first-round scores of both raters and the TRL score from the `r06` lower bound are written into the script. It computes:

- equal-weight sums (TRL score plus the four agreed scores);
- Monte Carlo runs with 10000 draws (seed 42) and random Dirichlet weights on the five criteria, reporting the probability of ranking strictly first, the probability of being tied first, the median rank and the 5th to 95th percentiles, for:
  - random weights only, with no score changes;
  - symmetric ±1 changes with p = 0.20, reflected at the bounds 0 and 3;
  - symmetric ±1 changes with p = 0.45 (the observed disagreement rate), reflected at the bounds;
  - one-directional −1 changes with p = 0.45 (lenient-rater shift), clipped at 0;
- the first-round ranking of each rater;
- the signed difference between the raters and a two-sided sign test;
- the ranking under a strict reading of rule R4 (PNT entangled clock and geophysics gradiometer not counted);
- the probability that biomedicine ranks above PNT under random weights only;
- leave-one-criterion-out rankings, including leaving out TRL;
- the ranking with the upper TRL bound;
- the sums after three one-point changes (geophysics field, incumbent and groups, each −1).

`fig_mc_rank.py` plots the probability that each domain ranks strictly first under the three perturbation models. It imports `sim2_robustness.py`, so both files must stay in the same folder.

- **How to run:**
  ```bash
  cd sim2_maturity_mc && python3 sim2_robustness.py > results_sim2_python.txt && python3 fig_mc_rank.py
  ```
- **Output:** `figures/fig_mc_rank.pdf` (and `.png`), `sim2_maturity_mc/results_sim2_python.txt`.

### MATLAB analysis (`sim2_maturity_mc.m`)

The paper's Monte Carlo results come from the Python script above. The minimum-change (adversarial) result in `results.txt` from this MATLAB analysis is still used. `loo_table.tex` and `caption.txt` belong to the MATLAB version, and running it overwrites `figures/fig_mc_rank.*`.

- **Analysis:** The primary ranking is the unweighted sum of five scores (TRL from the `r06` lower bound plus four consensus scores, maximum 15). Robustness analyses around it: Monte Carlo over weights and score perturbations, leave-one-criterion-out, upper-bound TRL rerun, adversarial score changes and a comparison with the ranking implied by `r06`'s TRL alone. Every ranking analysis is run with and without the preprint `r50`. Inter-rater agreement (weighted Cohen's kappa with a bootstrap interval) is reported for the independent first round.
- **Inputs:**
  - `data/trl_from_ref6.csv`: TRL range per domain from `r06`, Table VI, p. 1213. TRL is not rated by the authors. Score rule: TRL 1-3 gives 0, TRL 4 gives 1, TRL 5-6 gives 2, TRL 7 or higher gives 3.
  - `data/scores_consensus.csv` (all ranking analyses): columns `domain, technology_scored, criterion, score, score_without_r50, sources, evidence_type, rule_applied, notes`; 20 rows: 5 domains x `Field_demonstrations`, `Incumbent_comparison`, `Independent_groups`, `Commercial_availability`; integer scores 0-3. `score_without_r50` is filled only for cells that depend on `r50` (empty means the same as `score`). `technology_scored` must be the same in all rows of a domain.
  - `data/scores_rater1.csv` and `data/scores_rater2.csv` (agreement statistics only): the independent first round, columns `domain, criterion, score, sources` (extra columns are ignored), 20 rows each, with `Independent_replication` as the third criterion.
- **How to run:**
  ```
  "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -batch "cd('sim2_maturity_mc'); sim2_maturity_mc"
  ```
- **Output:** `figures/fig_mc_rank.pdf` (and `.png`), `sim2_maturity_mc/results.txt`, `sim2_maturity_mc/loo_table.tex`.
