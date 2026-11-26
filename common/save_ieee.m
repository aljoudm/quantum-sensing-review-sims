function save_ieee(fig, name)
%SAVE_IEEE Export a figure to figures/<name>.pdf (vector) and .png (200 dpi).
%   save_ieee(fig, name) writes into the repository's figures/ folder,
%   regardless of the current working directory. The exported size equals
%   the figure size. Base MATLAB only (R2025a or newer).

if nargin < 2
    error('save_ieee:args', 'Usage: save_ieee(fig, name)');
end

root   = fileparts(fileparts(mfilename('fullpath')));  % repo root
outdir = fullfile(root, 'figures');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

pdf_file = fullfile(outdir, [name '.pdf']);
png_file = fullfile(outdir, [name '.png']);

% 'Padding','figure' keeps the figure's own size; the default ('tight')
% crops to the content and would shrink the 3.5 in width. Needs R2025a+.
exportgraphics(fig, pdf_file, 'ContentType', 'vector', ...
               'BackgroundColor', 'white', 'Padding', 'figure');
exportgraphics(fig, png_file, 'Resolution', 200, ...
               'BackgroundColor', 'white', 'Padding', 'figure');

fprintf('Saved %s\n       %s\n', pdf_file, png_file);
end
