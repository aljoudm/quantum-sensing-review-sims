function res = sim2_maturity_mc()
%SIM2_MATURITY_MC Robustness of the maturity ranking of five domains.
%   Tests whether the ranking depends on the criterion weights, on
%   single-score disagreements between two raters, or on how the TRL range
%   of r06 is turned into a score.
%
%   Inputs (../data):
%     scores_rater1.csv, scores_rater2.csv - columns domain, criterion,
%       score (integer 0-3), sources; other columns are ignored.
%       20 rows each (5 domains x 4 rated criteria).
%     trl_from_ref6.csv - TRL range per domain (r06 Table VI, p. 1213).
%   TRL is not rated. Its score follows from r06:
%     TRL 1-3 -> 0, TRL 4 -> 1, TRL 5-6 -> 2, TRL >= 7 -> 3.
%   Main result uses the lower TRL bound, robustness run the upper bound.
%   The script stops on any missing, duplicated or invalid entry; it never
%   fills in scores.
%
%   Output: results.txt, loo_table.tex (this folder),
%           ../figures/fig_mc_rank.{pdf,png} (main result)
%   res = sim2_maturity_mc() also returns the numeric results.
%   Base MATLAB only.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'common'));
data_dir  = fullfile(here, '..', 'data');
trl_file  = fullfile(data_dir, 'trl_from_ref6.csv');
rater_files = {fullfile(data_dir, 'scores_rater1.csv'), ...
               fullfile(data_dir, 'scores_rater2.csv')};

%% Settings
domains  = {'PNT', 'Geophysics', 'Biomedical', 'RF_Radar_Comms', 'Networked'};
display_names = {'PNT', 'Geophysics', 'Biomedical', 'RF/Radar/Comms', 'Networked'};
rated    = {'Field_demonstrations', 'Incumbent_comparison', ...
            'Independent_replication', 'Commercial_availability'};
crit_short = {'TRL', 'Field', 'Incumb.', 'Replic.', 'Commerc.'};   % TRL first
nD = numel(domains);
nC = numel(crit_short);          % TRL + 4 rated criteria
opt.seed      = 42;
opt.N         = 10000;           % Monte Carlo iterations
opt.p_perturb = 0.2;             % probability that a score is changed by +/-1
opt.score_min = 0;
opt.score_max = 3;
% Perturbation models disagreement between raters, so it applies to the
% rated criteria (columns 2-5). The TRL column is not rated; its
% uncertainty is covered by the lower/upper-bound runs.
opt.perturbed = 2:nC;

%% Input (all problems in all three files are collected, then it stops)
[trl, problems] = read_trl(trl_file, domains, opt.score_min, opt.score_max);
R = cell(1, 2);
no_source = {};
for k = 1:2
    [R{k}, p, ns] = read_rater(rater_files{k}, domains, rated, ...
                               opt.score_min, opt.score_max);
    problems  = [problems, p];   %#ok<AGROW>
    no_source = [no_source, ns]; %#ok<AGROW>
end
if ~isempty(problems)
    list = sprintf('  - %s\n', problems{:});
    error('sim2:invalidInput', ...
          'STOPPED: %d problem(s) in the input files:\n%sNo results were produced.', ...
          numel(problems), list);
end
R1 = R{1}; R2 = R{2};

%% 1. Inter-rater agreement: the 20 rated pairs only (never TRL)
r1 = R1(:); r2 = R2(:);
n_pairs = numel(r1);
pct_agree = 100*mean(r1 == r2);
[kappa, confusion] = quad_weighted_kappa(r1, r2, opt.score_min:opt.score_max);
[di, ci] = find(abs(R1 - R2) >= 2);
big = sortrows([di(:), ci(:)]);      % [domain index, rated criterion index]

%% 2. Consensus score of the rated criteria
consensus = (R1 + R2)/2;

%% 3-5. Full analysis, twice
main  = analyse([trl.score_lower, consensus], opt);    % main result
upper = analyse([trl.score_upper, consensus], opt);    % robustness

%% 6. Ranking implied by r06's TRL alone (trl_low, ties by trl_high)
ref_rank = average_rank(100*trl.low + trl.high);
% Our ranking: order of the median Monte Carlo rank (smaller = better)
main.med_rank  = average_rank(-main.med);
upper.med_rank = average_rank(-upper.med);
rho_main  = spearman(main.med_rank,  ref_rank);
rho_upper = spearman(upper.med_rank, ref_rank);

% Comparison of the two runs
lead_main     = leaders(main.p_first);
lead_upper    = leaders(upper.p_first);
lead15_main   = leaders(main.p_le15);
lead15_upper  = leaders(upper.p_le15);
lead_changed  = ~isequal(lead_main, lead_upper);
lead15_changed = ~isequal(lead15_main, lead15_upper);
med_changed   = find(abs(main.med - upper.med) > 1e-9);

% Plot and report order: P(rank 1) descending, then median, mean rank
[~, order] = sortrows([-main.p_first(:), main.med(:), mean(main.ranks, 1).']);

write_loo_table(fullfile(here, 'loo_table.tex'), main.loo, display_names, crit_short);

%% Results file (also printed to the console)
fid = fopen(fullfile(here, 'results.txt'), 'w');
if fid < 0
    error('sim2:output', 'Cannot write results.txt in %s', here);
end
closer = onCleanup(@() fclose(fid));

emit(fid, '===== Sim 2: maturity ranking robustness =====\n');
emit(fid, 'Inputs: data/scores_rater1.csv, data/scores_rater2.csv, data/trl_from_ref6.csv\n');
emit(fid, 'Monte Carlo: N = %d, rng(%d) restarted for each run, flat Dirichlet weights\n', ...
     opt.N, opt.seed);
emit(fid, 'on %d criteria; each rated consensus score changed by +/-1 with p = %.2f,\n', ...
     nC, opt.p_perturb);
emit(fid, 'clipped to [%d,%d]. The TRL score is not perturbed.\n', ...
     opt.score_min, opt.score_max);

emit(fid, '\n--- 1. Inter-rater agreement (%d rated pairs; TRL excluded) ---\n', n_pairs);
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
    emit(fid, '  %-16s %-24s rater1 = %d, rater2 = %d\n', ...
         domains{i}, rated{j}, R1(i, j), R2(i, j));
end
emit(fid, 'Rows with an empty "sources" field: %d\n', numel(no_source));
for k = 1:numel(no_source)
    emit(fid, '  %s\n', no_source{k});
end

emit(fid, '\n--- 2. Scores ---\n');
emit(fid, 'TRL from r06 Table VI and the resulting score:\n');
emit(fid, '%-16s %8s %9s %12s %12s\n', 'domain', 'trl_low', 'trl_high', ...
     'score_lower', 'score_upper');
for i = 1:nD
    emit(fid, '%-16s %8d %9d %12d %12d\n', domains{i}, trl.low(i), trl.high(i), ...
         trl.score_lower(i), trl.score_upper(i));
end
emit(fid, 'Consensus of the rated criteria (mean of the two raters):\n');
emit(fid, '%-16s%s\n', 'domain', sprintf(' %9s', crit_short{2:end}));
for i = 1:nD
    emit(fid, '%-16s%s\n', domains{i}, sprintf(' %9.1f', consensus(i, :)));
end

report_run(fid, 'MAIN RESULT (TRL = lower-bound rule)', main, order, domains, crit_short);
report_run(fid, 'ROBUSTNESS (TRL = upper-bound rule)', upper, order, domains, crit_short);

emit(fid, '\n--- Main versus robustness ---\n');
emit(fid, 'Highest P(rank=1):    main %s | upper %s | changes: %s\n', ...
     name_list(domains, lead_main), name_list(domains, lead_upper), yesno(lead_changed));
emit(fid, 'Highest P(rank<=1.5): main %s | upper %s | changes: %s\n', ...
     name_list(domains, lead15_main), name_list(domains, lead15_upper), ...
     yesno(lead15_changed));
emit(fid, 'Median ranks change: %s\n', yesno(~isempty(med_changed)));
for i = med_changed(:).'
    emit(fid, '  %-16s main %.2f -> upper %.2f\n', domains{i}, main.med(i), upper.med(i));
end

emit(fid, '\n--- 6. Comparison with the ranking implied by r06 TRL alone ---\n');
emit(fid, 'r06 ranking: by trl_low, ties broken by trl_high; remaining ties averaged.\n');
emit(fid, 'This work: domains ranked by median Monte Carlo rank; ties averaged.\n');
emit(fid, '%-16s %9s %12s %12s %13s %13s\n', 'domain', 'r06 rank', ...
     'main median', 'main rank', 'upper median', 'upper rank');
for i = order.'
    emit(fid, '%-16s %9.1f %12.2f %12.1f %13.2f %13.1f\n', domains{i}, ref_rank(i), ...
         main.med(i), main.med_rank(i), upper.med(i), upper.med_rank(i));
end
emit(fid, 'Spearman rank correlation with r06, main:  %s\n', rho_text(rho_main));
emit(fid, 'Spearman rank correlation with r06, upper: %s\n', rho_text(rho_upper));
emit(fid, ['Note: only %d domains, and the TRL score (from r06) is one of the %d ' ...
           'criteria,\nso this is not an independent validation.\n'], nD, nC);
clear closer

%% Figure (main result)
fig = figure('Units', 'inches', 'Position', [1 1 3.5 2.2]);
axL = axes(fig, 'Units', 'inches', 'Position', [0.90 0.40 1.07 1.72]);
axR = axes(fig, 'Units', 'inches', 'Position', [2.20 0.40 1.19 1.72]);
ypos = nD:-1:1;                                   % first in order on top

hold(axL, 'on');
for k = 1:nD
    v = main.p_first(order(k));
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
    plot(axR, [main.p05(d) main.p95(d)], ypos(k)*[1 1], 'k-', 'LineWidth', 1.0);
    plot(axR, main.med(d), ypos(k), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
end
% Limits extend slightly beyond 1 and nD so that markers are not cut off
set(axR, 'XLim', [0.75 nD + 0.25], 'XTick', 1:nD, 'YLim', [0.4 nD + 0.6], ...
         'YTick', 1:nD, 'YTickLabel', []);
xlabel(axR, 'Rank');

ieee_style(fig);
save_ieee(fig, 'fig_mc_rank');

res = struct('pct_agree', pct_agree, 'kappa', kappa, 'confusion', confusion, ...
             'big_diff', big, 'consensus', consensus, 'trl', trl, ...
             'main', main, 'upper', upper, 'ref_rank', ref_rank, ...
             'rho_main', rho_main, 'rho_upper', rho_upper, ...
             'lead_changed', lead_changed, 'median_changed', med_changed, ...
             'no_source', {no_source}, 'order', order);
if nargout == 0
    clear res
end
end

%% --------------------------------------------------------------------- analysis
function a = analyse(S, opt)
% Monte Carlo and leave-one-criterion-out for one score matrix S
% (domains x criteria). The generator is restarted so that both runs use the
% same weights and perturbations.
[nD, nC] = size(S);
cols = opt.perturbed;
rng(opt.seed);
ranks = zeros(opt.N, nD);
top   = false(opt.N, nD);            % holds the highest total, alone or tied
for it = 1:opt.N
    e = -log(rand(1, nC));
    w = e/sum(e);                                    % flat Dirichlet
    hit  = rand(nD, numel(cols)) < opt.p_perturb;
    step = 2*(rand(nD, numel(cols)) < 0.5) - 1;      % +1 or -1
    Sp = S;
    Sp(:, cols) = min(max(S(:, cols) + hit.*step, opt.score_min), opt.score_max);
    total = Sp*w.';
    ranks(it, :) = average_rank(total);
    top(it, :)   = total.' >= max(total) - 1e-9;
end

a.scores  = S;
a.ranks   = ranks;
a.p_first = mean(ranks == 1, 1);
a.p_le15  = mean(ranks <= 1.5, 1);       % alone first, or two-way tie
a.p_top   = mean(top, 1);                % first, alone or in any tie
a.tie_share = mean(~any(ranks == 1, 2)); % first place tied
a.med = median(ranks, 1);
a.p05 = zeros(1, nD);
a.p95 = zeros(1, nD);
for d = 1:nD
    a.p05(d) = percentile(ranks(:, d), 5);
    a.p95(d) = percentile(ranks(:, d), 95);
end

% Leave one criterion out: equal weights, no perturbation
a.loo = zeros(nD, nC);
for k = 1:nC
    keep = setdiff(1:nC, k);
    total = S(:, keep)*(ones(numel(keep), 1)/numel(keep));
    a.loo(:, k) = average_rank(total).';
end
end

function r = average_rank(total)
% Rank 1 = largest value; tied values share the average rank.
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

function rho = spearman(rank_a, rank_b)
% Spearman correlation = Pearson correlation of the (tie-averaged) ranks.
a = rank_a(:) - mean(rank_a);
b = rank_b(:) - mean(rank_b);
den = sqrt(sum(a.^2)*sum(b.^2));
if den == 0
    rho = NaN;                           % one ranking is completely tied
else
    rho = sum(a.*b)/den;
end
end

function idx = leaders(p)
idx = find(p >= max(p) - 1e-12);
end

%% --------------------------------------------------------------------- input
function [trl, problems] = read_trl(file, domains, lo, hi)
needed = {'domain', 'trl_low', 'trl_high', 'score_lower_rule', 'score_upper_rule'};
nD = numel(domains);
trl = struct('low', nan(nD, 1), 'high', nan(nD, 1), ...
             'score_lower', nan(nD, 1), 'score_upper', nan(nD, 1));
[rows, problems, tag] = read_table(file, needed);
if ~isempty(problems), return; end
count = zeros(nD, 1);
for r = 1:size(rows, 1)
    dom = cell_text(rows{r, 2});
    where = sprintf('%s data row %d (%s)', tag, rows{r, 1}, dom);
    i = find(strcmp(domains, dom));
    if isempty(i)
        problems{end+1} = sprintf('%s: unknown domain "%s"', where, dom); %#ok<AGROW>
        continue;
    end
    count(i) = count(i) + 1;
    [low,  m1] = check_integer(rows{r, 3}, 1, 9);
    [high, m2] = check_integer(rows{r, 4}, 1, 9);
    [sl,   m3] = check_integer(rows{r, 5}, lo, hi);
    [su,   m4] = check_integer(rows{r, 6}, lo, hi);
    msgs = {m1, m2, m3, m4};
    for k = find(~cellfun(@isempty, msgs))
        problems{end+1} = sprintf('%s: %s %s', where, needed{k+1}, msgs{k}); %#ok<AGROW>
    end
    if all(cellfun(@isempty, msgs))
        if low > high
            problems{end+1} = sprintf('%s: trl_low exceeds trl_high', where); %#ok<AGROW>
        end
        if sl ~= trl_score(low) || su ~= trl_score(high)
            problems{end+1} = sprintf(['%s: scores %d/%d do not follow the TRL rule ' ...
                '(expected %d/%d)'], where, sl, su, trl_score(low), ...
                trl_score(high)); %#ok<AGROW>
        end
        trl.low(i) = low; trl.high(i) = high;
        trl.score_lower(i) = sl; trl.score_upper(i) = su;
    end
end
for i = 1:nD
    if count(i) == 0
        problems{end+1} = sprintf('%s: missing row: %s', tag, domains{i}); %#ok<AGROW>
    elseif count(i) > 1
        problems{end+1} = sprintf('%s: duplicated row (%d times): %s', ...
                                  tag, count(i), domains{i}); %#ok<AGROW>
    end
end
end

function s = trl_score(t)
% TRL 1-3 -> 0, TRL 4 -> 1, TRL 5-6 -> 2, TRL >= 7 -> 3
s = (t >= 4) + (t >= 5) + (t >= 7);
end

function [S, problems, no_source] = read_rater(file, domains, criteria, lo, hi)
needed = {'domain', 'criterion', 'score', 'sources'};
nD = numel(domains); nC = numel(criteria);
S = nan(nD, nC);
no_source = {};
[rows, problems, tag] = read_table(file, needed);
if ~isempty(problems), return; end
count = zeros(nD, nC);
for r = 1:size(rows, 1)
    dom = cell_text(rows{r, 2});
    cri = cell_text(rows{r, 3});
    where = sprintf('%s data row %d (%s / %s)', tag, rows{r, 1}, dom, cri);
    i = find(strcmp(domains, dom));
    j = find(strcmp(criteria, cri));
    if isempty(i)
        problems{end+1} = sprintf('%s: unknown domain "%s"', where, dom); %#ok<AGROW>
    end
    if strcmp(cri, 'TRL')
        problems{end+1} = sprintf(['%s: TRL must not be rated (it is taken from ' ...
                                   'trl_from_ref6.csv)'], where); %#ok<AGROW>
    elseif isempty(j)
        problems{end+1} = sprintf('%s: unknown criterion "%s"', where, cri); %#ok<AGROW>
    end
    [v, msg] = check_integer(rows{r, 4}, lo, hi);
    if ~isempty(msg)
        problems{end+1} = sprintf('%s: score %s', where, msg); %#ok<AGROW>
    end
    if ~isempty(i) && ~isempty(j)
        count(i, j) = count(i, j) + 1;
        S(i, j) = v;
        if isempty(cell_text(rows{r, 5}))
            no_source{end+1} = sprintf('%s: %s / %s', tag, dom, cri); %#ok<AGROW>
        end
    end
end
for i = 1:nD
    for j = 1:nC
        if count(i, j) == 0
            problems{end+1} = sprintf('%s: missing row: %s / %s', ...
                                      tag, domains{i}, criteria{j}); %#ok<AGROW>
        elseif count(i, j) > 1
            problems{end+1} = sprintf('%s: duplicated row (%d times): %s / %s', ...
                tag, count(i, j), domains{i}, criteria{j}); %#ok<AGROW>
        end
    end
end
end

function [rows, problems, tag] = read_table(file, needed)
% Returns {data row number, needed columns...} for every non-blank row.
[~, name, ext] = fileparts(file);
tag = [name ext];
rows = {};
problems = {};
if ~isfile(file)
    problems = {sprintf('%s: file not found (%s)', tag, file)};
    return;
end
C = readcell(file, 'FileType', 'text', 'Delimiter', ',');
header = cellfun(@cell_text, C(1, :), 'UniformOutput', false);
header = strrep(header, char(65279), '');            % byte-order mark
col = zeros(1, numel(needed));
for k = 1:numel(needed)
    hit = find(strcmpi(header, needed{k}));
    if numel(hit) == 1
        col(k) = hit;
    elseif isempty(hit)
        problems{end+1} = sprintf('%s: missing column "%s"', tag, needed{k}); %#ok<AGROW>
    else
        problems{end+1} = sprintf('%s: column "%s" appears %d times', ...
                                  tag, needed{k}, numel(hit)); %#ok<AGROW>
    end
end
if ~isempty(problems), return; end
for r = 2:size(C, 1)
    values = C(r, col);
    if all(cellfun(@(v) isempty(cell_text(v)), values))
        continue;                                    % blank line
    end
    rows(end+1, :) = [{r - 1}, values]; %#ok<AGROW>
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

function [x, msg] = check_integer(v, lo, hi)
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

%% --------------------------------------------------------------------- output
function report_run(fid, heading, a, order, domains, crit_short)
emit(fid, '\n=== %s ===\n', heading);
emit(fid, '--- Monte Carlo rank statistics (1 = most mature) ---\n');
emit(fid, '%-16s %10s %12s %12s %7s %6s %6s\n', 'domain', 'P(rank=1)', ...
     'P(rank<=1.5)', 'P(top, ties)', 'median', 'p05', 'p95');
for i = order.'
    emit(fid, '%-16s %10.4f %12.4f %12.4f %7.2f %6.2f %6.2f\n', domains{i}, ...
         a.p_first(i), a.p_le15(i), a.p_top(i), a.med(i), a.p05(i), a.p95(i));
end
emit(fid, 'First place tied (share of iterations): %.4f\n', a.tie_share);
emit(fid, ['P(rank<=1.5) counts first alone or a two-way tie; P(top, ties) also ' ...
           'counts\nties of three or more (average rank 2 or higher).\n']);
emit(fid, '--- Leave-one-criterion-out ranks (equal weights, no perturbation) ---\n');
emit(fid, '%-16s%s\n', 'left out ->', sprintf(' %9s', crit_short{:}));
for i = 1:numel(domains)
    emit(fid, '%-16s%s\n', domains{i}, sprintf(' %9.1f', a.loo(i, :)));
end
end

function s = name_list(domains, idx)
s = strjoin(domains(idx), ' = ');
end

function s = yesno(tf)
if tf, s = 'YES'; else, s = 'NO'; end
end

function s = rho_text(rho)
if isnan(rho)
    s = 'undefined (one ranking is completely tied)';
else
    s = sprintf('%.4f', rho);
end
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
              '(Equal Weights on the Other Four, Consensus Scores, ' ...
              'Lower-Bound TRL Rule; 1 = Most Mature)}\n']);
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
