% SUPERSEDED by sim1_nav_error.py, which combines the accelerometer and
% gyroscope terms as a root sum of squares and is the version used in the
% paper. This MATLAB file is kept for reference.

%% sim1_nav_error.m
% Illustrative single-axis inertial-navigation error budget.
% Analytic model (r43 Eq. (31), after Titterton and Weston):
%   sigma_x(t) = B_Om*R*(t - sin(wS*t)/wS) + B_a*(1 - cos(wS*t))/wS^2
% Base MATLAB only. Output: figures/fig_nav_error.{pdf,png}

clear; close all; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'common'));

%% Constants
g    = 9.81;            % m/s^2, unit conversion (standard gravity)
R    = 6.371e6;         % m, standard Earth radius (r43: R "typically the radius of the Earth")
T_S  = 84.4*60;         % s, Schuler period 84.4 min (r45).
                        % Note: r43 quotes 84 min and r44 quotes 87 min.
wS   = 2*pi/T_S;        % rad/s
ug   = 1e-6*g;          % m/s^2, 1 micro-g

%% Scenarios (B_a in m/s^2, B_Om in rad/s)
B_Om_S1 = 0.05e-6;      % rad/s, aviation-grade gyro bias (r44 Table 1)
B_a  = [30*ug, ...      % S1: aviation-grade accel bias (r44 Table 1; inputs to r44's simulation)
        0.89*ug, ...    % S2: RMS quantum bias-tracking error, lab with simulated mobile disturbances (r45)
        6e-8*g, ...     % S3: bias stability, static laboratory (r20)
        30*ug];         % S4: as S1 (r44 Table 1)
B_Om = [B_Om_S1, B_Om_S1, B_Om_S1, ...
        1e-9];          % S4: rotation stability, laboratory, not a navigation test (r46)

% Reference lines (r50, preprint): end-of-trajectory errors, not time-resolved
ref_air_m    = 22;      % m, best airborne (r50)
ref_ground_m = 180;     % m, ground (r50)

%% Model
accel_term = @(Ba, t) Ba.*(1 - cos(wS*t))/wS^2;
gyro_term  = @(Bo, t) Bo*R.*(t - sin(wS*t)/wS);
total      = @(Ba, Bo, t) gyro_term(Bo, t) + accel_term(Ba, t);

t  = 0:1:10*3600;       % s, 1 s resolution over 0-10 h
th = t/3600;            % h

acc1 = accel_term(B_a(1), t);
gyr1 = gyro_term(B_Om(1), t);
tot  = zeros(4, numel(t));
for k = 1:4
    tot(k,:) = total(B_a(k), B_Om(k), t);
end

%% Verification
fprintf('\n===== Sim 1 verification =====\n');

% Check 1: B_a/wS^2 for 10 micro-g (r45 states about 60 m)
v1 = 10*ug/wS^2;
fprintf('Check 1: B_a/wS^2 at 10 ug = %.2f m (r45: ~60 m)\n', v1);
assert(v1 > 55 && v1 < 70, 'Check 1 failed: %.2f m not in (55,70)', v1);

% Check 2: S1 total at 1 h (r44: "several km per hour")
v2 = total(B_a(1), B_Om(1), 3600)/1e3;
fprintf('Check 2: S1 total at 1 h = %.3f km (r44: several km/h)\n', v2);
assert(v2 > 0.5 && v2 < 10, 'Check 2 failed: %.3f km not in (0.5,10)', v2);

% Check 3 (printed, not asserted; compared with expected values)
i_cross = find(gyr1 > acc1 & t > 0, 1, 'first');
t_cross_min = t(i_cross)/60;
t_cross_h   = t(i_cross)/3600;

hrs = [2 4 10];
red = zeros(size(hrs));
for j = 1:numel(hrs)
    s1 = total(B_a(1), B_Om(1), hrs(j)*3600);
    s2 = total(B_a(2), B_Om(2), hrs(j)*3600);
    red(j) = 100*(s1 - s2)/s1;
end

h3 = [1 4 10];
Skm = zeros(4, numel(h3));      % totals, rows S1-S4
for k = 1:4
    Skm(k,:) = total(B_a(k), B_Om(k), h3*3600)/1e3;
end

names = {'Gyro>accel crossover (min)', ...
         'S2 lower than S1 at 2 h (%)', 'S2 lower than S1 at 4 h (%)', 'S2 lower than S1 at 10 h (%)'};
for k = 1:4
    for j = 1:numel(h3)
        names{end+1} = sprintf('S%d total at %d h (km)', k, h3(j)); %#ok<SAGROW>
    end
end
got  = [t_cross_min, red, reshape(Skm.', 1, [])];
% NaN = no expected value (printed only). 0.37 % is the unrounded form of
% the originally quoted 0.4 %.
expd = [26.2, 13.8, 1.7, 0.37, ...
        1.633, 4.886, 11.349, ...   % S1
        NaN,   NaN,   NaN, ...      % S2
        NaN,   NaN,   NaN, ...      % S3
        0.266, 0.181, 0.269];       % S4
relerr = 100*(got - expd)./expd;

fprintf('\nCheck 3: %-32s %10s %10s %9s  %s\n', 'quantity', 'computed', 'expected', 'diff (%)', 'flag');
nflag = 0;
for k = 1:numel(got)
    if isnan(expd(k))
        fprintf('         %-32s %10.4f %10s %9s\n', names{k}, got(k), '-', '-');
        continue;
    end
    flag = '';
    if abs(relerr(k)) > 1, flag = '<-- >1% DIFFERENCE'; nflag = nflag + 1; end
    fprintf('         %-32s %10.4f %10.4f %9.2f  %s\n', names{k}, got(k), expd(k), relerr(k), flag);
end
fprintf('Values differing from expected by more than 1%%: %d\n', nflag);
if nflag > 0
    fprintf(2, 'STOPPED: %d value(s) differ from expected by >1%%; figure not generated.\n', nflag);
    return;
end

%% Figure
fig = figure('Units', 'inches', 'Position', [1 1 3.5 4.4]);
tl  = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% (a) S1 contributions
axA = nexttile(tl);
hold(axA, 'on');
xline(axA, t_cross_h, ':', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8, 'HandleVisibility', 'off');
pa1 = semilogy(axA, th, max(acc1, eps), 'k--', 'LineWidth', 1.0);
pa2 = semilogy(axA, th, max(gyr1, eps), 'k-',  'LineWidth', 1.0);
set(axA, 'YScale', 'log');
xlim(axA, [0 10]); ylim(axA, [1 1e6]);
ylabel(axA, 'Position error (m)');
set(axA, 'XTickLabel', []);
% char(181) = micro sign, upright (SI/IEEE). TeX \mu would be italic.
legend(axA, [pa1 pa2], {['Accelerometer term (30 ' char(181) 'g)'], ...
                        ['Gyroscope term (0.05 ' char(181) 'rad/s)']}, ...
       'Location', 'northeast', 'Box', 'off', 'Interpreter', 'tex');
text(axA, 0.07, 0.93, '(a)', 'Units', 'normalized', ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

% (b) totals
axB = nexttile(tl);
hold(axB, 'on');
yline(axB, ref_air_m,    '--', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.6, 'HandleVisibility', 'off');
yline(axB, ref_ground_m, '--', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.6, 'HandleVisibility', 'off');
sty = {{'k-',  1.0, [0 0 0]}, {'--', 1.0, [0.5 0.5 0.5]}, {':', 1.4, [0.5 0.5 0.5]}, {'-.', 1.0, [0 0 0]}};
ph = gobjects(1, 4);
for k = 1:4
    y = tot(k,:); y(y < 1e-3) = NaN;   % drop t = 0 for log axis
    ph(k) = plot(axB, th, y, sty{k}{1}, 'Color', sty{k}{3}, 'LineWidth', sty{k}{2});
end
set(axB, 'YScale', 'log');
xlim(axB, [0 10]); ylim(axB, [1 1e8]);
xlabel(axB, 'Time without position fix (h)');
ylabel(axB, 'Position error (m)');
legend(axB, ph, {'S1 aviation-grade INS', 'S2 accel. bias quantum-tracked', ...
                 'S3 accel. bias 6\times10^{-8} g', 'S4 gyro bias 1 nrad/s'}, ...
       'Location', 'northeast', 'Box', 'off', 'NumColumns', 1, 'Interpreter', 'tex');
text(axB, 0.07, 0.93, '(b)', 'Units', 'normalized', ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

linkaxes([axA axB], 'x');
set(fig, 'Units', 'inches');
ieee_style(fig);
set(fig, 'Position', [1 1 3.5 4.4]);   % keep height ~4.4 in

% Reference annotations (added after ieee_style so the smaller font is kept)
text(axB, 9.75, ref_air_m/1.6,'map matching, 22 m (preprint)', ...
     'Color', [0.45 0.45 0.45], 'FontName', 'Times New Roman', 'FontSize', 6.5, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
text(axB, 9.75, ref_ground_m/1.6,'map matching, 180 m (preprint)', ...
     'Color', [0.45 0.45 0.45], 'FontName', 'Times New Roman', 'FontSize', 6.5, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');

save_ieee(fig, 'fig_nav_error');
