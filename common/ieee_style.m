function ieee_style(fig)
%IEEE_STYLE Format a figure for an IEEE one-column layout (3.5 in wide).
%   ieee_style(fig) sets the figure width to 3.5 in, uses Times New Roman
%   at 8 pt for axes, ticks and legends, axes line width 0.6, a white
%   background and removes figure titles. Base MATLAB only.
%
%   If fig is omitted, the current figure is used.

if nargin < 1 || isempty(fig)
    fig = gcf;
end

width_in  = 3.5;
font_name = 'Times New Roman';
font_size = 8;
line_w    = 0.6;

% Figure: width 3.5 in, keep current height, white background
set(fig, 'Units', 'inches');
pos = get(fig, 'Position');
set(fig, 'Position', [pos(1) pos(2) width_in pos(4)], ...
         'PaperUnits', 'inches', ...
         'PaperSize', [width_in pos(4)], ...
         'PaperPosition', [0 0 width_in pos(4)], ...
         'Color', 'w', ...
         'InvertHardcopy', 'off', ...
         'NumberTitle', 'off', ...
         'Name', '');

% Axes
axs = findall(fig, 'Type', 'axes');
for k = 1:numel(axs)
    ax = axs(k);
    set(ax, 'FontName', font_name, 'FontSize', font_size, ...
            'LineWidth', line_w, 'Color', 'w', 'Box', 'on');
    % No title (IEEE captions go in the paper)
    title(ax, '');
    % Axis labels in the same font
    set(get(ax, 'XLabel'), 'FontName', font_name, 'FontSize', font_size);
    set(get(ax, 'YLabel'), 'FontName', font_name, 'FontSize', font_size);
end

% Legends and colorbars
lgs = findall(fig, 'Type', 'legend');
for k = 1:numel(lgs)
    set(lgs(k), 'FontName', font_name, 'FontSize', font_size);
end
cbs = findall(fig, 'Type', 'colorbar');
for k = 1:numel(cbs)
    set(cbs(k), 'FontName', font_name, 'FontSize', font_size, ...
                'LineWidth', line_w);
end

% Free text annotations
txt = findall(fig, 'Type', 'text');
for k = 1:numel(txt)
    set(txt(k), 'FontName', font_name, 'FontSize', font_size);
end
end
