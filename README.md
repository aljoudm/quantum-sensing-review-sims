# Quantum Sensing Review: Simulations

MATLAB simulations that produce the figures for an IEEE review paper on quantum sensing.

- **Base MATLAB only.** No toolbox is required. Needs R2025a or newer (for the export sizing); helpers tested with R2026a.
- **Sourced parameters.** Every parameter is taken from a cited source in the paper's `references.bib` (keys `r01`-`r52`). Each script cites the key next to the value it uses.
- **Shared style.** All figures use `common/ieee_style.m` (3.5 in one-column width, Times New Roman 8 pt) and are exported with `common/save_ieee.m` to `figures/<name>.pdf` (vector) and `figures/<name>.png` (200 dpi). Each script adds `../common` to the MATLAB path.

## Run order

Run the simulations in the order **1, 3, 4, 2**.

Run each script from the repository root with MATLAB in batch mode (commands are given in each section below). Adjust the executable path if MATLAB is installed elsewhere. In PowerShell, put `&` in front of the quoted path.

## Layout

```
common/                  ieee_style.m, save_ieee.m
sim1_nav_error/          sim1_nav_error.m
sim2_maturity_mc/        sim2_maturity_mc.m
sim3_squeezing_loss/     sim3_squeezing_loss.m
sim4_quantum_limit_gap/  sim4_quantum_limit_gap.m
data/                    data files read by Sim 2
figures/                 exported PDF and PNG figures
```

## Simulation 1: Navigation error

- **Purpose:** Single-axis analytic inertial-navigation error budget showing that gyroscope bias, not accelerometer bias, dominates position error, and how much quantum-improved biases change it.
- **How to run:**
  ```
  "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -batch "cd('sim1_nav_error'); sim1_nav_error"
  ```
- **Output:** `figures/fig_nav_error.pdf` (and `.png`).

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

## Simulation 2: Maturity Monte Carlo

- **Purpose:** Monte Carlo test of whether the maturity ranking of five application domains (PNT, Geophysics, Biomedical, RF_Radar_Comms, Networked) depends on criterion weights, rater disagreement or the TRL scoring bound; also reports inter-rater agreement (weighted Cohen's kappa) and a comparison with the ranking implied by r06's TRL alone.
- **Inputs:**
  - `data/trl_from_ref6.csv`: TRL range per domain from r06, Table VI, p. 1213. TRL is not rated by the authors. Score rule: TRL 1-3 gives 0, TRL 4 gives 1, TRL 5-6 gives 2, TRL 7 or higher gives 3. The lower bound is the main result, the upper bound the robustness run.
  - `data/scores_rater1.csv` and `data/scores_rater2.csv`: columns `domain, criterion, score, sources` (extra columns are ignored), 20 rows each: 5 domains x `Field_demonstrations`, `Incumbent_comparison`, `Independent_replication`, `Commercial_availability`; scores are integers 0-3. Commit these only after both raters have finished, with those four columns only.
- **How to run:**
  ```
  "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -batch "cd('sim2_maturity_mc'); sim2_maturity_mc"
  ```
- **Output:** `figures/fig_mc_rank.pdf` (and `.png`), `sim2_maturity_mc/results.txt`, `sim2_maturity_mc/loo_table.tex`.
