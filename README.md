# Quantum Sensing Review: Simulations

MATLAB simulations that produce the figures for an IEEE review paper on quantum sensing.

- **Base MATLAB only.** No toolbox is required.
- **Sourced parameters.** Every parameter is taken from a cited source in the paper's `references.bib` (keys `r01`-`r50`). Each script cites the key next to the value it uses.
- **Shared style.** All figures use `common/ieee_style.m` (3.5 in one-column width, Times New Roman 8 pt) and are exported with `common/save_ieee.m` to `figures/<name>.pdf` (vector) and `figures/<name>.png` (200 dpi).

## Run order

Run the simulations in the order **1, 3, 4, 2**.

## Layout

```
common/                  ieee_style.m, save_ieee.m
sim1_nav_error/
sim2_maturity_mc/
sim3_squeezing_loss/
sim4_quantum_limit_gap/
data/                    intermediate results shared between simulations
figures/                 exported PDF and PNG figures
```

From the repository root, add the helpers to the path first:

```matlab
addpath('common');
```

## Simulation 1: Navigation error

- **Purpose:** Navigation error growth with and without quantum sensors.
- **How to run:** `cd sim1_nav_error; run_sim1` (entry script to be added).
- **Output files:** `figures/sim1_nav_error.pdf`, `figures/sim1_nav_error.png`; data in `data/`.

## Simulation 3: Squeezing and loss

- **Purpose:** Effect of optical loss on squeezing-enhanced sensitivity.
- **How to run:** `cd sim3_squeezing_loss; run_sim3` (entry script to be added).
- **Output files:** `figures/sim3_squeezing_loss.pdf`, `figures/sim3_squeezing_loss.png`; data in `data/`.

## Simulation 4: Quantum limit gap

- **Purpose:** Gap between achieved sensitivity and the fundamental quantum limit.
- **How to run:** `cd sim4_quantum_limit_gap; run_sim4` (entry script to be added).
- **Output files:** `figures/sim4_quantum_limit_gap.pdf`, `figures/sim4_quantum_limit_gap.png`; data in `data/`.

## Simulation 2: Maturity Monte Carlo

- **Purpose:** Monte Carlo analysis of technology maturity, run last because it draws on the results of simulations 1, 3 and 4.
- **How to run:** `cd sim2_maturity_mc; run_sim2` (entry script to be added).
- **Output files:** `figures/sim2_maturity_mc.pdf`, `figures/sim2_maturity_mc.png`; data in `data/`.
