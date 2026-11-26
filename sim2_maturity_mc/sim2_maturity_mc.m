function res = sim2_maturity_mc()
%SIM2_MATURITY_MC Robustness of the maturity ranking of six domains.
%   Tests whether the ranking depends on the criterion weights or on
%   single-score disagreements between two raters.
%
%   Input : ../data/scores.csv with columns domain, criterion,
%           score_rater1, score_rater2 (integers 0-3). Other columns are
%           ignored. The script stops on any missing, duplicated or invalid
%           entry; it never fills in scores.
%   Output: results.txt, loo_table.tex (this folder),
%           ../figures/fig_mc_rank.{pdf,png}
%   res = sim2_maturity_mc() also returns the numeric results.
%   Base MATLAB only.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'common'));
input_file = fullfile(here, '..', 'data', 'scores.csv');

%% Settings
domains  = {'PNT', 'Geophysics', 'Biomedical', 'RF_Radar', 'Networked', ...
            'Fundamental_science'};
display_names = {'PNT', 'Geophysics', 'Biomedical', 'RF/Radar', 'Networked', ...
                 'Fund. science'};
criteria = {'TRL', 'Field_demonstrations', 'Incumbent_comparison', ...
            'Independent_replication', 'Commercial_availability'};
crit_short = {'TRL', 'Field', 'Incumb.', 'Replic.', 'Commerc.'};
nD = numel(domains);
nC = numel(criteria);
seed      = 42;
N         = 10000;   % Monte Carlo iterations
p_perturb = 0.2;     % probability that a cell is perturbed by +1 or -1
score_min = 0;
score_max = 3;

%% Input (stops with a list of problems if anything is wrong)
[R1, R2] = read_scores(input_file, domains, criteria, score_min, score_max);

%% 1. Inter-rater agreement over all domain-criterion pairs
r1 = R1(:); r2 = R2(:);
n_pairs = numel(r1);
pct_agree = 100*mean(r1 == r2);
[kappa, confusion] = quad_weighted_kappa(r1, r2, score_min:score_max);
[di, ci] = find(abs(R1 - R2) >= 2);
big = sortrows([di(:), ci(:)]);          % [domain index, criterion index]

%% 2. Consensus score
S = (R1 + R2)/2;

%% 3. Monte Carlo over weights and single-score perturbations
rng(seed);
ranks     = zeros(N, nD);
tie_first = false(N, 1);
for it = 1:N
    e = -log(rand(1, nC));
    w = e/sum(e);                                    % flat Dirichlet
    hit  = rand(nD, nC) < p_perturb;
    step = 2*(rand(nD, nC) < 0.5) - 1;               % +1 or -1
    Sp   = min(max(S + hit.*step, score_min), score_max);
    total = Sp*w.';
    ranks(it, :) = average_rank(total);
    tie_first(it) = ~any(ranks(it, :) == 1);
end

%% 4. Rank statistics
p_first = mean(ranks == 1, 1);
med     = median(ranks, 1);
p05     = zeros(1, nD);
p95     = zeros(1, nD);
for d = 1:nD
    p05(d) = percentile(ranks(:, d), 5);
    p95(d) = percentile(ranks(:, d), 95);
end

%% 5. Leave one criterion out (equal weights, consensus, no perturbation)
loo = zeros(nD, nC);
for k = 1:nC
    keep = setdiff(1:nC, k);
    total = S(:, keep)*(ones(numel(keep), 1)/numel(keep));
    loo(:, k) = average_rank(total).';
end
write_loo_table(fullfile(here, 'loo_table.tex'), loo, display_names, crit_short);

%% 6. Results file (also printed to the console)
% Plot and report order: P(rank 1) descending, then median rank, mean rank
[~, order] = sortrows([-p_first(:), med(:), mean(ranks, 1).']);

fid = fopen(fullfile(here, 'results.txt'), 'w');
if fid < 0
    error('sim2:output', 'Cannot write results.txt in %s', here);
end
closer = onCleanup(@() fclose(fid));

emit(fid, '===== Sim 2: maturity ranking robustness =====\n');
emit(fid, 'Input: data/scores.csv\n');
emit(fid, 'Monte Carlo: N = %d, rng(%d), flat Dirichlet weights, ', N, seed);
emit(fid, 'perturbation +/-1 with p = %.2f, clipped to [%d,%d]\n', ...
     p_perturb, score_min, score_max);

emit(fid, '\n--- 1. Inter-rater agreement (%d pairs) ---\n', n_pairs);
emit(fid, 'Exact agreement: %.1f %% (%d of %d)\n', pct_agree, sum(r1 == r2), n_pairs);
if isnan(kappa)
    emit(fid, 'Quadratic-weighted Cohen''s kappa: undefined (no expected disagreement)\n');
else
    emit(fid, 'Quadratic-weighted Cohen''s kappa: %.4f\n', kappa);
end
emit(fid, 'Confusion counts (rows rater 1, columns rater 2, categories 0-3):\n');
for i = 1:size(confusion, 1)
    emit(fid, '  %d:%s\n', i - 1, sprintf(' %3d', confusion(i, :)));
end
emit(fid, 'Pairs differing by 2 or more points: %d\n', size(big, 1));
for k = 1:size(big, 1)
    i = big(k, 1); j = big(k, 2);
    emit(fid, '  %-20s %-24s rater1 = %d, rater2 = %d\n', ...
         domains{i}, criteria{j}, R1(i, j), R2(i, j));
end

emit(fid, '\n--- 2. Consensus scores (mean of the two raters) ---\n');
emit(fid, '%-20s%s\n', 'domain', sprintf(' %9s', crit_short{:}));
for i = 1:nD
    emit(fid, '%-20s%s\n', domains{i}, sprintf(' %9.1f', S(i, :)));
end

emit(fid, '\n--- 3-4. Monte Carlo rank statistics (1 = most mature) ---\n');
emit(fid, '%-20s %10s %8s %8s %8s\n', 'domain', 'P(rank=1)', 'median', 'p05', 'p95');
for i = order.'
    emit(fid, '%-20s %10.4f %8.2f %8.2f %8.2f\n', domains{i}, p_first(i), ...
         med(i), p05(i), p95(i));
end
emit(fid, 'Iterations with a tie for first place: %.4f\n', mean(tie_first));
emit(fid, '(Tied domains get the average rank, so a tie for first counts for none.)\n');

emit(fid, '\n--- 5. Leave-one-criterion-out ranks (equal weights, consensus) ---\n');
emit(fid, '%-20s%s\n', 'domain \ left out', sprintf(' %9s', crit_short{:}));
for i = 1:nD
    emit(fid, '%-20s%s\n', domains{i}, sprintf(' %9.1f', loo(i, :)));
end
clear closer

%% Figure
fig = figure('Units', 'inches', 'Position', [1 1 3.5 2.2]);
axL = axes(fig, 'Units', 'inches', 'Position', [0.84 0.40 1.12 1.72]);
axR = axes(fig, 'Units', 'inches', 'Position', [2.20 0.40 1.19 1.72]);
ypos = nD:-1:1;                                   % first in order on top

hold(axL, 'on');
for k = 1:nD
    v = p_first(order(k));
    patch(axL, [0 v v 0], ypos(k) + 0.32*[-1 -1 1 1], [0.55 0.55 0.55], ...
          'EdgeColor', 'k', 'LineWidth', 0.6);
end
set(axL, 'XLim', [0 1], 'XTick', [0 0.5 1], 'YLim', [0.4 nD + 0.6], ...
         'YTick', 1:nD, 'YTickLabel', display_names(order(end:-1:1)), ...
         'TickLabelInterpreter', 'none');
xlabel(axL, 'P(rank 1)');

hold(axR, 'on');
for k = 1:nD
    d = order(k);
    plot(axR, [p05(d) p95(d)], ypos(k)*[1 1], 'k-', 'LineWidth', 1.0);
    plot(axR, med(d), ypos(k), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
end
% Limits extend slightly beyond 1 and 6 so that markers are not cut off
set(axR, 'XLim', [0.7 nD + 0.3], 'XTick', 1:nD, 'YLim', [0.4 nD + 0.6], ...
         'YTick', 1:nD, 'YTickLabel', []);
xlabel(axR, 'Rank');

ieee_style(fig);
save_ieee(fig, 'fig_mc_rank');

res = struct('pct_agree', pct_agree, 'kappa', kappa, 'confusion', confusion, ...
             'big_diff', big, 'consensus', S, 'ranks', ranks, ...
             'p_first', p_first, 'median_rank', med, 'p05', p05, 'p95', p95, ...
             'tie_first_share', mean(tie_first), 'loo', loo, 'order', order);
if nargout == 0
    clear res
end
end

%% ---------------------------------------------------------------------
function [R1, R2] = read_scores(file, domains, criteria, lo, hi)
% Read and validate the scores. Collects every problem before stopping.
if ~isfile(file)
    error('sim2:missingFile', ...
          'STOPPED: score file not found:\n  %s\nNo results were produced.', file);
end
C = readcell(file, 'FileType', 'text', 'Delimiter', ',');

header = cellfun(@cell_text, C(1, :), 'UniformOutput', false);
header = strrep(header, char(65279), '');            % byte-order mark
needed = {'domain', 'criterion', 'score_rater1', 'score_rater2'};
col = zeros(1, numel(needed));
problems = {};
for k = 1:numel(needed)
    hit = find(strcmpi(header, needed{k}));
    if numel(hit) == 1
        col(k) = hit;
    elseif isempty(hit)
        problems{end+1} = sprintf('missing column "%s"', needed{k}); %#ok<AGROW>
    else
        problems{end+1} = sprintf('column "%s" appears %d times', ...
                                  needed{k}, numel(hit)); %#ok<AGROW>
    end
end
stop_if(problems, file);

nD = numel(domains); nC = numel(criteria);
R1 = nan(nD, nC); R2 = nan(nD, nC);
count = zeros(nD, nC);
for row = 2:size(C, 1)
    dom = cell_text(C{row, col(1)});
    cri = cell_text(C{row, col(2)});
    s1  = C{row, col(3)};
    s2  = C{row, col(4)};
    if isempty(dom) && isempty(cri) && isempty(cell_text(s1)) && isempty(cell_text(s2))
        continue;                                    % blank line
    end
    where = sprintf('data row %d (%s / %s)', row - 1, dom, cri);
    i = find(strcmp(domains, dom));
    j = find(strcmp(criteria, cri));
    if isempty(i)
        problems{end+1} = sprintf('%s: unknown domain "%s"', where, dom); %#ok<AGROW>
    end
    if isempty(j)
        problems{end+1} = sprintf('%s: unknown criterion "%s"', where, cri); %#ok<AGROW>
    end
    [v1, msg1] = check_score(s1, lo, hi);
    [v2, msg2] = check_score(s2, lo, hi);
    if ~isempty(msg1)
        problems{end+1} = sprintf('%s: score_rater1 %s', where, msg1); %#ok<AGROW>
    end
    if ~isempty(msg2)
        problems{end+1} = sprintf('%s: score_rater2 %s', where, msg2); %#ok<AGROW>
    end
    if ~isempty(i) && ~isempty(j)
        count(i, j) = count(i, j) + 1;
        R1(i, j) = v1; R2(i, j) = v2;
    end
end
for i = 1:nD
    for j = 1:nC
        if count(i, j) == 0
            problems{end+1} = sprintf('missing row: %s / %s', ...
                                      domains{i}, criteria{j}); %#ok<AGROW>
        elseif count(i, j) > 1
            problems{end+1} = sprintf('duplicated row (%d times): %s / %s', ...
                                      count(i, j), domains{i}, criteria{j}); %#ok<AGROW>
        end
    end
end
stop_if(problems, file);
end

function stop_if(problems, file)
if ~isempty(problems)
    list = sprintf('  - %s\n', problems{:});
    error('sim2:invalidScores', ...
          'STOPPED: %d problem(s) in %s:\n%sNo results were produced.', ...
          numel(problems), file, list);
end
end

function t = cell_text(v)
% Cell content as trimmed text; empty for a missing cell.
if isa(v, 'missing')
    t = '';
else
    t = strtrim(char(string(v)));
end
end

function [x, msg] = check_score(v, lo, hi)
x = NaN; msg = '';
t = cell_text(v);
if isempty(t)
    msg = 'is empty';
    return;
end
if isnumeric(v)
    num = double(v);
else
    num = str2double(t);
end
if ~isscalar(num) || ~isfinite(num) || num ~= round(num) || num < lo || num > hi
    msg = sprintf('is "%s" (must be an integer %d-%d)', t, lo, hi);
    return;
end
x = num;
end

function [kappa, O] = quad_weighted_kappa(a, b, cats)
% kappa = 1 - sum(W.*P_obs) / sum(W.*P_exp), W(i,j) = (i-j)^2/(k-1)^2
k = numel(cats);
O = zeros(k);
for n = 1:numel(a)
    i = find(cats == a(n)); j = find(cats == b(n));
    O(i, j) = O(i, j) + 1;
end
P = O/sum(O(:));
E = sum(P, 2)*sum(P, 1);                 % product of the marginals
[J, I] = meshgrid(1:k, 1:k);
W = (I - J).^2/(k - 1)^2;
den = sum(W(:).*E(:));
if den == 0
    kappa = NaN;
else
    kappa = 1 - sum(W(:).*P(:))/den;
end
end

function r = average_rank(total)
% Rank 1 = largest total; tied totals share the average rank.
tol = 1e-9;                              % guards against round-off
total = total(:).';
r = zeros(size(total));
for i = 1:numel(total)
    higher = sum(total > total(i) + tol);
    tied   = sum(abs(total - total(i)) <= tol);
    r(i) = higher + (tied + 1)/2;
end
end

function q = percentile(x, p)
% Linear interpolation between sorted values placed at 100*(i-0.5)/n.
x = sort(x(:));
n = numel(x);
pos = min(max(p/100*n + 0.5, 1), n);
a = floor(pos); b = ceil(pos);
q = x(a) + (pos - a)*(x(b) - x(a));
end

function write_loo_table(file, loo, names, crit_short)
fid = fopen(file, 'w');
if fid < 0
    error('sim2:output', 'Cannot write %s', file);
end
closer = onCleanup(@() fclose(fid));
fprintf(fid, '\\begin{table}[!t]\n');
fprintf(fid, '\\renewcommand{\\arraystretch}{1.3}\n');
fprintf(fid, ['\\caption{Domain Rank With One Criterion Left Out ' ...
              '(Equal Weights on the Other Four, Consensus Scores; ' ...
              '1 = Most Mature)}\n']);
fprintf(fid, '\\label{tab:loo}\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\begin{tabular}{|l|%s}\n', repmat('c|', 1, numel(crit_short)));
fprintf(fid, '\\hline\n');
fprintf(fid, ' & \\multicolumn{%d}{c|}{Criterion left out} \\\\\n', numel(crit_short));
fprintf(fid, '\\cline{2-%d}\n', numel(crit_short) + 1);
fprintf(fid, 'Domain%s \\\\\n', sprintf(' & %s', crit_short{:}));
fprintf(fid, '\\hline\n');
for i = 1:size(loo, 1)
    fprintf(fid, '%s%s \\\\\n', names{i}, sprintf(' & %g', loo(i, :)));
    fprintf(fid, '\\hline\n');
end
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\end{table}\n');
end

function emit(fid, fmt, varargin)
% Write the same text to results.txt and to the console.
text_out = sprintf(fmt, varargin{:});
fprintf('%s', text_out);
fprintf(fid, '%s', text_out);
end
