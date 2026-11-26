function sim4_plot(ax, d)
%SIM4_PLOT Draw the operating-noise / limit bar chart (panel b) into ax.
%   sim4_plot(ax, d) uses d from sim4_data. ax must already have its final
%   position. Call ieee_style on the figure afterwards, then set the axes
%   'Box' to 'off'. Base MATLAB only.

font = {'FontName', 'Times New Roman', 'FontSize', 8};
set(ax, font{:}, 'LineWidth', 0.6);
hold(ax, 'on');

n    = numel(d);
ypos = n:-1:1;                  % first entry on top
hbar = 0.30;                    % half bar height
for k = 1:n
    if d(k).quantum
        face = [0.45 0.45 0.45];    % quantum reference limit
    else
        face = [0.85 0.85 0.85];    % classical limit, second-hand
    end
    r = d(k).ratio;
    patch(ax, [1 r r 1], ypos(k) + hbar*[-1 -1 1 1], face, ...
          'EdgeColor', 'k', 'LineWidth', 0.6);
    text(ax, r*1.05, ypos(k), d(k).value_text, font{:}, ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end

% Ratio = 1 reference line (it is also the left end of the x-axis)
ylim(ax, [0.2 n + 0.9]);
plot(ax, [1 1], ylim(ax), 'k--', 'LineWidth', 0.8);
text(ax, 1.04, 0.42, 'at limit', font{:}, ...
     'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');

set(ax, 'XScale', 'log', 'XLim', [1 30], ...
        'XTick', [1 2 3 5 10 20 30], 'XTickLabel', {'1','2','3','5','10','20','30'});
xlabel(ax, 'Operating noise / limit', font{:});

% The y ruler is hidden so the dashed line at 1 reads as a reference line;
% bar labels are therefore drawn as text.
ax.YTick  = [];
ax.YColor = 'none';
for k = 1:n
    text(ax, 0.95, ypos(k), d(k).label, font{:}, ...
         'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
end

% Panel label and footnote, positioned in inches relative to the axes
ax.Units = 'inches';
p = ax.Position;
text(ax, 'Units', 'inches', 'Position', [0.07 - p(1), p(4)], ...
     'String', '(b)', font{:}, ...
     'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
text(ax, 'Units', 'inches', 'Position', [p(3), 0.07 - p(2)], ...
     'String', '* classical limit, second-hand', font{:}, ...
     'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
end
