function save_ieee(fig, name)
%SAVE_IEEE Export a figure to figures/<name>.pdf (vector) and .png (200 dpi).
%   save_ieee(fig, name) writes into the repository's figures/ folder,
%   regardless of the current working directory. Base MATLAB only.

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

exportgraphics(fig, pdf_file, 'ContentType', 'vector', ...
               'BackgroundColor', 'white');
exportgraphics(fig, png_file, 'Resolution', 200, ...
               'BackgroundColor', 'white');

fprintf('Saved %s\n       %s\n', pdf_file, png_file);
end
