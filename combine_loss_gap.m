%% combine_loss_gap.m
% Panels (a) Sim 3 (loss-limited squeezing) and (b) Sim 4 (quantum limit
% gap) in one column-width figure. Both panels are re-plotted from the same
% data and plotting functions as the individual scripts.
% Base MATLAB only. Output: figures/fig_loss_gap.{pdf,png}
%
% Verification tables are printed by the individual scripts; run
% sim3_squeezing_loss and sim4_quantum_limit_gap first.

clear; close all; clc;
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root, 'common'), ...
        fullfile(root, 'sim3_squeezing_loss'), ...
        fullfile(root, 'sim4_quantum_limit_gap'));

h_b = 1.80;                 % in, height of panel (b), as in Sim 4
h_a = 2.30;                 % in, height of panel (a), as in Sim 3
fig = figure('Units', 'inches', 'Position', [1 1 3.5 h_a + h_b]);

% Same axes sizes as the single figures; panel (a) is shifted up by h_b
axA = axes(fig, 'Units', 'inches', 'Position', [0.44 h_b+0.38 2.95 1.84]);
sim3_plot(axA, sim3_data());

axB = axes(fig, 'Units', 'inches', 'Position', [1.45 0.54 1.93 1.19]);
sim4_plot(axB, sim4_data());

ieee_style(fig);
axB.Box = 'off';
save_ieee(fig, 'fig_loss_gap');
