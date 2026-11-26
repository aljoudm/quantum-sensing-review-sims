%% sim3_squeezing_loss.m
% Loss-limited squeezing: detected squeezing versus detection efficiency.
%   V       = 10^(-dB/10)            noise variance relative to shot noise
%   V_obs   = eta*V_src + (1 - eta)
%   S_obs   = -10*log10(V_obs)       detected squeezing (dB)
%   ceiling = -10*log10(1 - eta)     infinite source squeezing
% Pure-loss model: phase noise and anti-squeezing are not modeled.
% Model and source values: sim3_data.m. Drawing: sim3_plot.m.
% Base MATLAB only. Output: figures/fig_squeezing_loss.{pdf,png}

clear; close all; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'common'), here);

d = sim3_data();

%% Verification
% Rows: quantity, computed, expected, source value (NaN = none), note
rows = { ...
  'Model, eta=0.75, 7.2 dB',   d.s_obs(d.ligo.src, d.bud.eta),  4.06, d.bud.pred, ...
      'independent check (vs r03 loss-only prediction)'; ...
  'Model, eta=0.66, 7.2 dB',   d.s_obs(d.ligo.src, d.meas.eta), 3.32, d.meas.obs, ...
      'consistency only (eta inferred from the same measurement)'; ...
  'Model, eta=0.74, 4 dB',     d.s_obs(d.om.src, d.om.eta),     2.56, d.om.obs, ...
      'vs r17 observed'; ...
  'Ceiling at eta=0.66',       d.ceil_db(d.meas.eta),           4.69, NaN, ''; ...
  'Ceiling at eta=0.74',       d.ceil_db(d.om.eta),             5.85, NaN, ''};
tol = 0.05;   % dB, computed vs expected

fprintf('\n===== Sim 3 verification (all values in dB) =====\n');
fprintf('%-25s %8s %8s %7s %7s %8s  %s\n', 'quantity', 'computed', 'expected', ...
        'diff', 'source', 'residual', 'label');
nflag = 0;
for k = 1:size(rows, 1)
    [name, got, expd, ref, note] = rows{k,:};
    if isnan(ref)
        refs = '-'; ress = '-';
    else
        refs = sprintf('%.2f', ref); ress = sprintf('%.3f', got - ref);
    end
    if abs(got - expd) > tol
        note = [note ' <-- >0.05 dB DIFFERENCE']; %#ok<AGROW>
        nflag = nflag + 1;
    end
    fprintf('%-25s %8.3f %8.2f %7.3f %7s %8s  %s\n', name, got, expd, ...
            got - expd, refs, ress, note);
end
fprintf('diff = computed - expected; residual = computed - source value\n');
fprintf('Values differing from expected by more than %.2f dB: %d\n', tol, nflag);
if nflag > 0
    fprintf(2, 'STOPPED: %d value(s) differ by >%.2f dB; figure not generated.\n', nflag, tol);
    return;
end

%% Figure
fig = figure('Units', 'inches', 'Position', [1 1 3.5 2.3]);
ax  = axes(fig, 'Units', 'inches', 'Position', [0.44 0.38 2.95 1.84]);
sim3_plot(ax, d);
ieee_style(fig);
save_ieee(fig, 'fig_squeezing_loss');
