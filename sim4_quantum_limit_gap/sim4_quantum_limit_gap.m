%% sim4_quantum_limit_gap.m
% Ratio of operating noise to the reference limit for three quantum sensors.
% Data and sources: sim4_data.m. Drawing: sim4_plot.m.
% Base MATLAB only. Output: figures/fig_quantum_limit_gap.{pdf,png}

clear; close all; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'common'), here);

d = sim4_data();

%% Verification (ratios compared at one decimal)
expd = [10.6, 7.4, 10.0];
fprintf('\n===== Sim 4 verification =====\n');
fprintf('%-28s %9s %8s %9s %8s %8s  %s\n', 'entry', 'operating', 'limit', ...
        'computed', 'rounded', 'expected', 'reference');
nflag = 0;
for k = 1:numel(d)
    if isnan(d(k).operating)
        op = '-'; lim = '-';
    else
        op = sprintf('%g', d(k).operating); lim = sprintf('%g', d(k).limit);
    end
    rounded = round(d(k).ratio*10)/10;
    flag = '';
    if abs(rounded - expd(k)) > 1e-9, flag = '  <-- DIFFERS'; nflag = nflag + 1; end
    fprintf('%-28s %9s %8s %9.3f %8.1f %8.1f  %s%s\n', d(k).label, op, lim, ...
            d(k).ratio, rounded, expd(k), d(k).reference, flag);
end
fprintf('Units of operating and limit: row 1 E/sqrt(Hz), row 2 pT/sqrt(Hz).\n');
fprintf('Row 3: ratio taken directly from r04 ("about one order of magnitude").\n');
fprintf('Ratios differing from expected: %d\n', nflag);
if nflag > 0
    fprintf(2, 'STOPPED: %d ratio(s) differ; figure not generated.\n', nflag);
    return;
end

%% Figure
fig = figure('Units', 'inches', 'Position', [1 1 3.5 1.8]);
ax  = axes(fig, 'Units', 'inches', 'Position', [1.45 0.54 1.93 1.19]);
sim4_plot(ax, d);
ieee_style(fig);
ax.Box = 'off';
save_ieee(fig, 'fig_quantum_limit_gap');
