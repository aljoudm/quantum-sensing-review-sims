function sim3_plot(ax, d)
%SIM3_PLOT Draw detected squeezing vs efficiency (panel a) into ax.
%   sim3_plot(ax, d) uses d from sim3_data. ax must already have its final
%   position (the arrow geometry depends on it). Call ieee_style on the
%   figure afterwards. Base MATLAB only.

fig = ancestor(ax, 'figure');
set(ax, 'FontName', 'Times New Roman', 'FontSize', 8, 'LineWidth', 0.6, ...
        'Box', 'on');
hold(ax, 'on');

eta = linspace(0.3, 1, 701);
sty  = {':', '--', '-.', '-'};
gry  = [0.35 0.50 0.35 0.65];
lw   = [1.3 1.0 1.0 1.0];
h    = gobjects(1, 8);
lbl  = cell(1, 8);
for k = 1:numel(d.src_levels)
    h(k)   = plot(ax, eta, d.s_obs(d.src_levels(k), eta), sty{k}, ...
                  'Color', gry(k)*[1 1 1], 'LineWidth', lw(k));
    lbl{k} = sprintf('Source %g dB', d.src_levels(k));
end
yc = d.ceil_db(eta); yc(~isfinite(yc)) = NaN;   % diverges at eta = 1
h(5)   = plot(ax, eta, yc, 'k-', 'LineWidth', 1.2);
lbl{5} = 'Infinite source (ceiling)';

xl = [0.3 1]; yl = [0 15];
xlim(ax, xl); ylim(ax, yl);

% Thin gray arrow, budgeted -> measured. Bowed downward because a straight
% arrow would lie on top of the 7.2 dB curve. Geometry is computed in inches
% so the head keeps its shape.
ax.Units = 'inches';
axin  = ax.Position;
to_in = @(x, y) [(x - xl(1))/diff(xl)*axin(3); (y - yl(1))/diff(yl)*axin(4)];
P0 = to_in(d.bud.eta, d.bud.pred);
P1 = to_in(0.692, 2.40);                          % control point (shape only)
P2 = to_in(0.667, 2.85);    % tip just below the measured marker, so it
s  = linspace(0, 1, 400);   % stays clear of the horizontal error-bar cap
B  = P0*(1-s).^2 + P1*(2*(1-s).*s) + P2*s.^2;
gap  = 0.055;                                     % in, clearance at start
B    = B(:, vecnorm(B - P0) > gap);
tip  = B(:, end);
hlen = 0.055; hw = 0.020;                         % in, head length, half width
i0   = find(vecnorm(B - tip) >= hlen, 1, 'last'); % where shaft meets head
dirv = tip - B(:, i0); dirv = dirv/norm(dirv);
nrm  = [-dirv(2); dirv(1)];
head = [tip, tip - hlen*dirv + hw*nrm, tip - hlen*dirv - hw*nrm];
body = B(:, 1:i0);
x_of = @(u) xl(1) + u/axin(3)*diff(xl);
y_of = @(v) yl(1) + v/axin(4)*diff(yl);
agray = [0.45 0.45 0.45];
plot(ax, x_of(body(1,:)), y_of(body(2,:)), '-', 'Color', agray, 'LineWidth', 0.6);
patch(ax, x_of(head(1,:)), y_of(head(2,:)), agray, 'EdgeColor', 'none');

% Points with error bars
h(6) = errorbar(ax, d.bud.eta, d.bud.pred, d.bud.pred_err, d.bud.pred_err, ...
                d.bud.eta_err, d.bud.eta_err, 'ko', 'MarkerFaceColor', 'w', ...
                'MarkerSize', 4, 'LineWidth', 0.8, 'CapSize', 3);
lbl{6} = 'Interferometer, budgeted';
h(7) = errorbar(ax, d.meas.eta, d.meas.obs, d.meas.obs_err, d.meas.obs_err, ...
                d.meas.eta_err, d.meas.eta_err, 'ko', 'MarkerFaceColor', 'k', ...
                'MarkerSize', 4, 'LineWidth', 0.8, 'CapSize', 3);
lbl{7} = 'Interferometer, measured';
h(8) = plot(ax, d.om.eta, d.om.obs, 'ks', 'MarkerFaceColor', 'w', ...
            'MarkerSize', 5, 'LineWidth', 0.8);
lbl{8} = 'Optomechanics';

xlabel(ax, 'Detection efficiency \eta', 'Interpreter', 'tex', ...
       'FontName', 'Times New Roman', 'FontSize', 8);
ylabel(ax, 'Detected squeezing (dB)', ...
       'FontName', 'Times New Roman', 'FontSize', 8);
lg = legend(ax, h, lbl, 'Location', 'northwest', 'Box', 'off', ...
            'FontName', 'Times New Roman', 'FontSize', 8);
text(ax, 0.03, 0.96, '(a)', 'Units', 'normalized', ...
     'FontName', 'Times New Roman', 'FontSize', 8, ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

% Place the legend just right of "(a)", flush with the top of the axes
set(fig, 'Color', 'w');
drawnow;
lg.ItemTokenSize = [18 8];
drawnow;
ax.Units = 'normalized';
axp = ax.Position;
lg.Units = 'normalized';
lgp = lg.Position;
lg.Position = [axp(1) + 0.11*axp(3), axp(2) + axp(4) - lgp(4) - 0.005, lgp(3), lgp(4)];
end
