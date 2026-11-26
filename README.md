# Quantum Sensing Review: Simulations

MATLAB simulations that produce the figures for an IEEE review paper on quantum sensing.

- **Base MATLAB only.** No toolbox is required. Needs R2025a or newer (for the export sizing); helpers tested with R2026a.
- **Sourced parameters.** Every parameter is taken from a cited source in the paper's `references.bib` (keys `r01`-`r50`). Each script cites the key next to the value it uses.
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
data/                    data files (Sim 2 reads data/scores.csv)
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

- **Purpose:** Monte Carlo test of whether the maturity ranking of six application domains depends on criterion weights or rater disagreement; also reports inter-rater agreement (weighted Cohen's kappa).
- **Input:** `data/scores.csv`.
- **How to run:**
  ```
  "C:\Program Files\MATLAB\R2026a\bin\matlab.exe" -batch "cd('sim2_maturity_mc'); sim2_maturity_mc"
  ```
- **Output:** `figures/fig_mc_rank.pdf` (and `.png`).
