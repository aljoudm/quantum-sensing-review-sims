%% sim3_squeezing_loss.m
% Loss-limited squeezing: detected squeezing versus detection efficiency.
%   V       = 10^(-dB/10)            noise variance relative to shot noise
%   V_obs   = eta*V_src + (1 - eta)
%   S_obs   = -10*log10(V_obs)       detected squeezing (dB)
%   ceiling = -10*log10(1 - eta)     infinite source squeezing
% Pure-loss model: phase noise and anti-squeezing are not modeled.
% Base MATLAB only. Output: figures/fig_squeezing_loss.{pdf,png}

clear; close all; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'common'));

%% Model
db2var  = @(dB) 10.^(-dB/10);
s_obs   = @(dB_src, eta) -10*log10(eta.*db2var(dB_src) + (1 - eta));
ceil_db = @(eta) -10*log10(1 - eta);

%% Source values
% Advanced LIGO (r03, Table I and Sec. IV-D)
ligo.src = 7.2;    ligo.src_err = 0.3;    % dB, generated squeezing
% Budget: efficiency from the loss budget and r03's predictions
bud.eta  = 0.75;   bud.eta_err  = 0.06;   % budgeted total efficiency
bud.pred = 4.1;    bud.pred_err = 0.6;    % dB, r03 prediction, losses only
% (r03 predicts 4.0 +/- 0.6 dB with losses plus ~15 mrad phase noise)
% Measurement: r03 infers eta FROM the observed squeezing, so agreement of
% the model at this eta is a consistency check, not an independent test.
meas.eta = 0.66;   meas.eta_err = 0.02;   % efficiency inferred by r03
meas.obs = 3.2;    meas.obs_err = 0.1;    % dB, observed squeezing
% Optomechanics (r17), no error bars given. r17 reports the observed value
% as consistent with the overall loss.
om.src = 4;        % dB, generated squeezing, "about" (r17)
om.eta = 0.74;     % detection efficiency (r17)
om.obs = 2.4;      % dB, observed squeezing, "about" (r17)

src_levels = [4 7.2 10 15];   % dB, curves shown in the figure

%% Verification
% Rows: quantity, computed, expected, source value (NaN = none), note
rows = { ...
  'Model, eta=0.75, 7.2 dB',   s_obs(ligo.src, bud.eta),  4.06, bud.pred, ...
      'independent check (vs r03 loss-only prediction)'; ...
  'Model, eta=0.66, 7.2 dB',   s_obs(ligo.src, meas.eta), 3.32, meas.obs, ...
      'consistency only (eta inferred from the same measurement)'; ...
  'Model, eta=0.74, 4 dB',     s_obs(om.src, om.eta),     2.56, om.obs, ...
      'vs r17 observed'; ...
  'Ceiling at eta=0.66',       ceil_db(meas.eta),         4.69, NaN, ''; ...
  'Ceiling at eta=0.74',       ceil_db(om.eta),           5.85, NaN, ''};
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
fig_w = 3.5; fig_h = 2.3;                         % in
fig = figure('Units', 'inches', 'Position', [1 1 fig_w fig_h]);
ax  = axes(fig, 'Units', 'inches', 'Position', [0.44 0.38 2.95 1.84]);
hold(ax, 'on');

eta = linspace(0.3, 1, 701);
sty  = {':', '--', '-.', '-'};
gry  = [0.35 0.50 0.35 0.65];
lw   = [1.3 1.0 1.0 1.0];
h    = gobjects(1, 8);
lbl  = cell(1, 8);
for k = 1:numel(src_levels)
    h(k)   = plot(ax, eta, s_obs(src_levels(k), eta), sty{k}, ...
                  'Color', gry(k)*[1 1 1], 'LineWidth', lw(k));
    lbl{k} = sprintf('Source %g dB', src_levels(k));
end
yc = ceil_db(eta); yc(~isfinite(yc)) = NaN;     % diverges at eta = 1
h(5)   = plot(ax, eta, yc, 'k-', 'LineWidth', 1.2);
lbl{5} = 'Infinite source (ceiling)';

xl = [0.3 1]; yl = [0 15];
xlim(ax, xl); ylim(ax, yl);

% Thin gray arrow, budgeted -> measured. Bowed downward because a straight
% arrow would lie on top of the 7.2 dB curve. Geometry is computed in inches
% so the head keeps its shape.
axin  = ax.Position;
to_in = @(x, y) [(x - xl(1))/diff(xl)*axin(3); (y - yl(1))/diff(yl)*axin(4)];
P0 = to_in(bud.eta,  bud.pred);
P1 = to_in(0.692, 2.40);                          % control point (shape only)
P2 = to_in(0.667, 2.85);    % tip just below the measured marker, so it
s  = linspace(0, 1, 400);   % stays clear of the horizontal error-bar cap
B  = P0*(1-s).^2 + P1*(2*(1-s).*s) + P2*s.^2;
gap  = 0.055;                                     % in, clearance at start
B    = B(:, vecnorm(B - P0) > gap);
tip  = B(:, end);
hlen = 0.055; hw = 0.020;                         % in, head length, half width
i0   = find(vecnorm(B - tip) >= hlen, 1, 'last'); % where shaft meets head
d    = tip - B(:, i0); d = d/norm(d);
n    = [-d(2); d(1)];
head = [tip, tip - hlen*d + hw*n, tip - hlen*d - hw*n];
body = B(:, 1:i0);
x_of = @(u) xl(1) + u/axin(3)*diff(xl);
y_of = @(v) yl(1) + v/axin(4)*diff(yl);
agray = [0.45 0.45 0.45];
plot(ax, x_of(body(1,:)), y_of(body(2,:)), '-', 'Color', agray, 'LineWidth', 0.6);
patch(ax, x_of(head(1,:)), y_of(head(2,:)), agray, 'EdgeColor', 'none');

% Points with error bars
h(6) = errorbar(ax, bud.eta, bud.pred, bud.pred_err, bud.pred_err, ...
                bud.eta_err, bud.eta_err, 'ko', 'MarkerFaceColor', 'w', ...
                'MarkerSize', 4, 'LineWidth', 0.8, 'CapSize', 3);
lbl{6} = 'Interferometer, budgeted';
h(7) = errorbar(ax, meas.eta, meas.obs, meas.obs_err, meas.obs_err, ...
                meas.eta_err, meas.eta_err, 'ko', 'MarkerFaceColor', 'k', ...
                'MarkerSize', 4, 'LineWidth', 0.8, 'CapSize', 3);
lbl{7} = 'Interferometer, measured';
h(8) = plot(ax, om.eta, om.obs, 'ks', 'MarkerFaceColor', 'w', ...
            'MarkerSize', 5, 'LineWidth', 0.8);
lbl{8} = 'Optomechanics';

xlabel(ax, 'Detection efficiency \eta', 'Interpreter', 'tex');
ylabel(ax, 'Detected squeezing (dB)');
lg = legend(ax, h, lbl, 'Location', 'northwest', 'Box', 'off');
text(ax, 0.03, 0.96, '(a)', 'Units', 'normalized', ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

ieee_style(fig);
set(fig, 'Position', [1 1 fig_w fig_h]);

% Place the legend just right of "(a)", flush with the top of the axes
drawnow;
lg.ItemTokenSize = [18 8];
drawnow;
ax.Units = 'normalized';
axp = ax.Position;
lg.Units = 'normalized';
lgp = lg.Position;
lg.Position = [axp(1) + 0.11*axp(3), axp(2) + axp(4) - lgp(4) - 0.005, lgp(3), lgp(4)];

save_ieee(fig, 'fig_squeezing_loss');
