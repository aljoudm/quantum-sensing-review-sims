function res = sim2_maturity_mc()
%SIM2_MATURITY_MC Maturity ranking of five domains and its robustness.
%   PRIMARY ranking: unweighted sum of five scores (maximum 15): the TRL
%   score from the r06 lower bound plus four agreed (consensus) scores.
%   ROBUSTNESS analyses around it: Monte Carlo over random weights and
%   +/-1 score perturbations, leave-one-criterion-out, upper-bound TRL
%   rerun, adversarial score changes, and comparison with the ranking implied
%   by r06's TRL ranges (excluding TRL as a criterion, ranked by the sum of
%   the four judged scores; and partly circular, TRL shared). Table and
%   figure list the domains in primary-ranking order. Every ranking analysis is run twice: with column "score" and
%   with "score_without_r50" (r50 is a preprint).
%
%   Inputs (../data):
%     scores_consensus.csv - domain, technology_scored, criterion, score,
%       score_without_r50, sources, evidence_type, rule_applied, notes.
%       20 rows; scores are integers 0-3; an empty score_without_r50 means
%       "same as score". Used for ALL ranking analyses.
%     scores_rater1.csv, scores_rater2.csv - independent first round:
%       domain, criterion, score, sources. Used ONLY for agreement
%       statistics. They are never averaged into scores.
%     trl_from_ref6.csv - TRL range per domain (r06 Table VI, p. 1213).
%       TRL is not rated: TRL 1-3 -> 0, 4 -> 1, 5-6 -> 2, >= 7 -> 3.
%   The script stops on any missing, duplicated or invalid entry; it never
%   fills in scores.
%
%   Output: results.txt, loo_table.tex (this folder),
%           ../figures/fig_mc_rank.{pdf,png} (Monte Carlo, with r50)
%   res = sim2_maturity_mc() also returns the numeric results.
%   Base MATLAB only.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'common'));
data_dir       = fullfile(here, '..', 'data');
trl_file       = fullfile(data_dir, 'trl_from_ref6.csv');
consensus_file = fullfile(data_dir, 'scores_consensus.csv');
rater_files    = {fullfile(data_dir, 'scores_rater1.csv'), ...
                  fullfile(data_dir, 'scores_rater2.csv')};

%% Settings
domains  = {'PNT', 'Geophysics', 'Biomedical', 'RF_Radar_Comms', 'Networked'};
display_names = {'PNT', 'Geophysics', 'Biomedical', 'RF/Radar/Comms', 'Networked'};
% Judged criteria. The third one is named differently in the two inputs.
rated_first = {'Field_demonstrations', 'Incumbent_comparison', ...
               'Independent_replication', 'Commercial_availability'};
rated       = {'Field_demonstrations', 'Incumbent_comparison', ...
               'Independent_groups', 'Commercial_availability'};
crit_short  = {'TRL', 'Field', 'Incumb.', 'IndGroups', 'Commerc.'};   % TRL first
crit_table  = {'TRL', 'Field', 'Incumb.', '\shortstack{Independent\\groups}', ...
               'Commerc.'};
nD = numel(domains);
nC = numel(crit_short);          % TRL + 4 judged criteria
opt.seed      = 42;
opt.N         = 10000;           % Monte Carlo iterations
opt.p_perturb = 0.2;             % probability that a score is changed by +/-1
opt.score_min = 0;
opt.score_max = 3;
opt.boot_B    = 10000;           % bootstrap replicates for kappa
opt.boot_seed = 42;
% Perturbation models disagreement between raters, so it applies to the
% judged criteria (columns 2-5). The TRL column is not rated; its
% uncertainty is covered by the lower/upper-bound runs.
opt.perturbed = 2:nC;

%% Input (all problems in all four files are collected, then it stops)
[trl, problems] = read_trl(trl_file, domains, opt.score_min, opt.score_max);
[cons, p] = read_consensus(consensus_file, domains, rated, ...
                           opt.score_min, opt.score_max);
problems = [problems, p];
R = cell(1, 2);
no_source = {};
for k = 1:2
    [R{k}, p, ns] = read_rater(rater_files{k}, domains, rated_first, ...
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

%% Inter-rater agreement: first round, the 20 judged pairs only (never TRL)
r1 = R1(:); r2 = R2(:);
n_pairs = numel(r1);
pct_agree = 100*mean(r1 == r2);
[kappa, confusion] = quad_weighted_kappa(r1, r2, opt.score_min:opt.score_max);
boot = bootstrap_kappa(r1, r2, opt);     % 95 % percentile interval
if isnan(kappa), boot.ci = [NaN NaN]; end
[di, ci] = find(abs(R1 - R2) >= 2);
big = sortrows([di(:), ci(:)]);      % [domain index, criterion index]

%% Ranking analyses, with and without r50 (consensus scores only)
% Reference ranking implied by r06's TRL alone (trl_low, ties by trl_high)
ref_rank = average_rank(100*trl.low + trl.high);
with    = rank_all(trl, cons.score,   ref_rank, opt);
without = rank_all(trl, cons.without, ref_rank, opt);

% Report, table and figure order: primary sum; domains with equal sums are
% listed by Monte Carlo P(top, ties), then median rank
[~, porder] = sortrows([-with.sum(:), -with.main.p_top(:), with.main.med(:)]);
order = porder;

write_loo_table(fullfile(here, 'loo_table.tex'), with, without.sum, porder, ...
                display_names, crit_table);

%% Results file (also printed to the console)
fid = fopen(fullfile(here, 'results.txt'), 'w', 'n', 'UTF-8');
if fid < 0
    error('sim2:output', 'Cannot write results.txt in %s', here);
end
closer = onCleanup(@() fclose(fid));

emit(fid, '===== Sim 2: maturity ranking =====\n');
emit(fid, 'Ranking analyses: data/scores_consensus.csv and data/trl_from_ref6.csv\n');
emit(fid, ['Agreement statistics only: data/scores_rater1.csv and ' ...
           'data/scores_rater2.csv (first round)\n']);
emit(fid, '"with r50" uses column score; "without r50" uses score_without_r50\n');
emit(fid, '(empty = same as score). r50 is a preprint.\n');

report_primary(fid, with, without, cons, domains, rated, crit_short, porder);

emit(fid, ['\n--- Inter-rater agreement (independent first round, %d judged ' ...
           'pairs; TRL excluded) ---\n'], n_pairs);
emit(fid, 'Exact agreement: %.1f %% (%d of %d)\n', pct_agree, sum(r1 == r2), n_pairs);
if isnan(kappa)
    emit(fid, 'Quadratic-weighted Cohen''s kappa: undefined (no expected disagreement)\n');
else
    emit(fid, 'Quadratic-weighted Cohen''s kappa: %.4f (95 %% bootstrap CI %.4f to %.4f)\n', ...
         kappa, boot.ci(1), boot.ci(2));
    emit(fid, ['Bootstrap: %d resamples of the %d pairs with replacement, rng(%d), ' ...
               'percentile interval;\nundefined replicates left out: %d\n'], ...
         opt.boot_B, n_pairs, opt.boot_seed, boot.n_undefined);
end
emit(fid, ['NOTE: agreement and kappa describe the first round only, under the ' ...
           'original criterion\ndefinitions. The agreed decision rules (single ' ...
           'most mature technology per domain,\nrevised field anchors, ' ...
           '"Independent_groups" counted for the same technology class,\n' ...
           'second-hand evidence capped at 2) were adopted for the consensus ' ...
           'round only.\n']);
emit(fid, 'Confusion counts (rows rater 1, columns rater 2, categories 0-3):\n');
for i = 1:size(confusion, 1)
    emit(fid, '  %d:%s\n', i - 1, sprintf(' %3d', confusion(i, :)));
end
emit(fid, 'Pairs differing by 2 or more points: %d\n', size(big, 1));
for k = 1:size(big, 1)
    i = big(k, 1); j = big(k, 2);
    emit(fid, '  %-16s %-24s rater1 = %d, rater2 = %d\n', ...
         domains{i}, rated_first{j}, R1(i, j), R2(i, j));
end
emit(fid, 'Rater rows with an empty "sources" field: %d\n', numel(no_source));
for k = 1:numel(no_source)
    emit(fid, '  %s\n', no_source{k});
end

emit(fid, '\n--- TRL inputs (r06 Table VI) ---\n');
emit(fid, '%-16s %8s %9s %12s %12s\n', 'domain', 'trl_low', 'trl_high', ...
     'score_lower', 'score_upper');
for i = porder.'
    emit(fid, '%-16s %8d %9d %12d %12d\n', domains{i}, trl.low(i), trl.high(i), ...
         trl.score_lower(i), trl.score_upper(i));
end

emit(fid, '\n=== ROBUSTNESS ANALYSES AROUND THE PRIMARY RANKING ===\n');
emit(fid, ['Monte Carlo: N = %d, rng(%d) restarted for each run, flat Dirichlet ' ...
           'weights;\neach judged consensus score changed by +/-1 with p = %.2f, ' ...
           'clipped to [%d,%d].\n'], opt.N, opt.seed, opt.p_perturb, ...
     opt.score_min, opt.score_max);
emit(fid, ['TRL is held fixed in the Monte Carlo: only the %d judged consensus ' ...
           'scores are\nperturbed. TRL uncertainty is covered by the lower- and ' ...
           'upper-bound TRL runs.\n'], n_pairs);

report_mc(fid, 'R1. Robustness: Monte Carlo (lower-bound TRL)', ...
          with.main, without.main, domains, porder);
report_loo(fid, 'R2. Robustness: leave-one-criterion-out (lower-bound TRL)', ...
           with.main, without.main, domains, porder, crit_short);
report_mc(fid, 'R3. Robustness: upper-bound TRL rerun, Monte Carlo', ...
          with.upper, without.upper, domains, porder);
report_loo(fid, 'R3. Robustness: upper-bound TRL rerun, leave-one-criterion-out', ...
           with.upper, without.upper, domains, porder, crit_short);
report_bounds(fid, 'with r50', with, domains);
report_bounds(fid, 'without r50', without, domains);

emit(fid, '\n--- R4. Robustness: adversarial test ---\n');
emit(fid, ['Starts from the primary ranking (lower-bound TRL). One change moves one ' ...
           'judged\nconsensus score up or down by 1 within 0-3 (a cell may be moved ' ...
           'more than once,\neach step counted); TRL is fixed; a tie for first ' ...
           'counts as losing.\n']);
report_adversarial(fid, 'with r50', with.adv, domains, [{'TRL'}, rated]);
report_adversarial(fid, 'without r50', without.adv, domains, [{'TRL'}, rated]);

report_r06(fid, with, without, ref_rank, domains, porder, opt);
report_r50_effect(fid, with, without);
clear closer

%% Figure: Monte Carlo robustness analysis (lower-bound TRL, with r50)
main = with.main;
fig = figure('Units', 'inches', 'Position', [1 1 3.5 2.2]);
axL = axes(fig, 'Units', 'inches', 'Position', [0.90 0.40 1.07 1.72]);
axR = axes(fig, 'Units', 'inches', 'Position', [2.20 0.40 1.19 1.72]);
ypos = nD:-1:1;                                   % first in order on top

hold(axL, 'on');
for k = 1:nD
    v = main.p_top(order(k));
    patch(axL, [0 v v 0], ypos(k) + 0.32*[-1 -1 1 1], [0.55 0.55 0.55], ...
          'EdgeColor', 'k', 'LineWidth', 0.6);
end
set(axL, 'XLim', [0 1], 'XTick', [0 0.5 1], 'YLim', [0.4 nD + 0.6], ...
         'YTick', 1:nD, 'YTickLabel', display_names(order(end:-1:1)), ...
         'TickLabelInterpreter', 'none');
xlabel(axL, 'P(first or tied)');        % P(top, ties)

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
             'big_diff', big, 'kappa_ci', boot.ci, ...
             'boot_undefined', boot.n_undefined, 'trl', trl, ...
             'consensus', cons, 'with', with, 'without', without, ...
             'ref_rank', ref_rank, 'primary_order', porder, 'order', order, ...
             'no_source', {no_source});
if nargout == 0
    clear res
end
end

%% --------------------------------------------------------------------- analysis
function b = rank_all(trl, C, ref_rank, opt)
% Every ranking analysis for one set of judged scores C (domains x 4).
S_low = [trl.score_lower, C];
S_up  = [trl.score_upper, C];
nC = size(S_low, 2);

% Primary ranking
b.scores = S_low;
b.sum    = sum(S_low, 2).';
b.rank   = average_rank(b.sum);

% Monte Carlo and leave-one-out, lower and upper TRL bound
b.main  = analyse(S_low, opt);
b.upper = analyse(S_up, opt);

% Comparison with r06 that excludes TRL as a criterion: domains ranked by the
% sum of the four judged consensus scores
b.rated_sum      = sum(C, 2).';
b.rated_sum_rank = average_rank(b.rated_sum);
b.rho_rated      = spearman(b.rated_sum_rank, ref_rank);

% Median Monte Carlo ranks (smaller = better): secondary line of that
% comparison, and the partly circular comparison with all five criteria
b.main.med_rank  = average_rank(-b.main.med);
b.upper.med_rank = average_rank(-b.upper.med);
opt_rated = opt;
opt_rated.perturbed = 1:size(C, 2);
b.rated_only = analyse(C, opt_rated);            % excludes TRL as a criterion
b.rated_only.med_rank = average_rank(-b.rated_only.med);
b.rho_rated_mc = spearman(b.rated_only.med_rank, ref_rank);   % secondary
b.rho_main  = spearman(b.main.med_rank,  ref_rank);    % partly circular
b.rho_upper = spearman(b.upper.med_rank, ref_rank);    % partly circular

% Adversarial test from the primary ranking
b.adv = adversarial(S_low, 2:nC, opt.score_min, opt.score_max);
end

function a = analyse(S, opt)
% Monte Carlo and leave-one-criterion-out for one score matrix S
% (domains x criteria). The generator is restarted so that all runs use the
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

function b = bootstrap_kappa(r1, r2, opt)
% Resample the rated pairs with replacement; percentile 95 % interval.
% Replicates with undefined kappa (both raters constant and equal) are
% counted and left out.
n = numel(r1);
k = nan(opt.boot_B, 1);
rng(opt.boot_seed);
for it = 1:opt.boot_B
    idx = randi(n, n, 1);
    k(it) = quad_weighted_kappa(r1(idx), r2(idx), opt.score_min:opt.score_max);
end
ok = ~isnan(k);
b.n_undefined = sum(~ok);
if any(ok)
    b.ci = [percentile(k(ok), 2.5), percentile(k(ok), 97.5)];
else
    b.ci = [NaN NaN];
end
end

function a = adversarial(S, judged, lo, hi)
% Fewest one-point changes to judged cells after which the top domain (sum of
% scores) is no longer uniquely first. A tie counts as losing. One change
% moves one cell by +1 or -1 and stays within [lo, hi]; a cell may be moved
% more than once, each step counted.
%
% Each change alters the margin (leader - challenger) by at most 1, so
% challenger j needs at least ceil(margin) changes: lowering the leader or
% raising j. The minimum over challengers is therefore exact.
tol = 1e-9;
total = sum(S, 2);
top = find(total >= max(total) - tol);
a = struct('scores', S, 'totals', total, 'leaders', top, 'tied', numel(top) > 1, ...
           'n_min', NaN, 'challengers', [], 'changes', zeros(0, 3), ...
           'new_totals', total, 'distinct', true);
if a.tied
    return;
end
L = top;
best = [];                     % [n changes, repeats a cell, challenger]
sets = {};
for j = setdiff(1:size(S, 1), L)
    need = ceil(total(L) - total(j) - tol);
    moves = zeros(0, 3);       % [domain, criterion, step]
    for pass = 1:(hi - lo)     % first pass uses each cell once
        for c = judged
            if S(L, c) - pass >= lo - tol
                moves(end+1, :) = [L, c, -1]; %#ok<AGROW>
            end
        end
        for c = judged
            if S(j, c) + pass <= hi + tol
                moves(end+1, :) = [j, c, +1]; %#ok<AGROW>
            end
        end
    end
    if size(moves, 1) >= need
        set_j = moves(1:need, :);
        repeats = size(unique(set_j(:, 1:2), 'rows'), 1) < need;
        best(end+1, :) = [need, repeats, j]; %#ok<AGROW>
        sets{end+1} = set_j;                 %#ok<AGROW>
    end
end
if isempty(best)
    return;                    % cannot be displaced within the score range
end
a.n_min = min(best(:, 1));
at_min = find(best(:, 1) == a.n_min);
a.challengers = best(at_min, 3).';
% Among the minimal sets prefer one that moves every cell only once
[~, p] = min(best(at_min, 2));
pick = at_min(p);
a.changes = sets{pick};
a.distinct = ~best(pick, 2);
S2 = S;
for k = 1:size(a.changes, 1)
    S2(a.changes(k, 1), a.changes(k, 2)) = ...
        S2(a.changes(k, 1), a.changes(k, 2)) + a.changes(k, 3);
end
a.new_totals = sum(S2, 2);
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

function [c, problems] = read_consensus(file, domains, criteria, lo, hi)
% Agreed scores. c.score and c.without are domains x criteria;
% c.technology holds one technology_scored text per domain.
needed = {'domain', 'technology_scored', 'criterion', 'score', ...
          'score_without_r50', 'sources', 'evidence_type', 'rule_applied', 'notes'};
nD = numel(domains); nC = numel(criteria);
c.score   = nan(nD, nC);
c.without = nan(nD, nC);
c.technology = repmat({''}, nD, 1);
c.r50_notes = {};              % possible inconsistencies, reported only
c.no_source = {};
[rows, problems, tag] = read_table(file, needed);
if ~isempty(problems), return; end
count = zeros(nD, nC);
for r = 1:size(rows, 1)
    dom  = cell_text(rows{r, 2});
    tech = cell_text(rows{r, 3});
    cri  = cell_text(rows{r, 4});
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
    [v, msg] = check_integer(rows{r, 5}, lo, hi);
    if ~isempty(msg)
        problems{end+1} = sprintf('%s: score %s', where, msg); %#ok<AGROW>
    end
    alt_text = cell_text(rows{r, 6});
    if isempty(alt_text)
        alt = v;                                   % same as score
    else
        [alt, msg] = check_integer(rows{r, 6}, lo, hi);
        if ~isempty(msg)
            problems{end+1} = sprintf('%s: score_without_r50 %s', where, msg); %#ok<AGROW>
        end
    end
    if isempty(tech)
        problems{end+1} = sprintf('%s: technology_scored is empty', where); %#ok<AGROW>
    elseif ~isempty(i)
        if isempty(c.technology{i})
            c.technology{i} = tech;
        elseif ~strcmp(c.technology{i}, tech)
            problems{end+1} = sprintf(['%s: technology_scored "%s" differs from "%s" ' ...
                'in an earlier row of this domain'], where, tech, ...
                c.technology{i}); %#ok<AGROW>
        end
    end
    if ~isempty(i) && ~isempty(j)
        count(i, j) = count(i, j) + 1;
        c.score(i, j) = v;
        c.without(i, j) = alt;
        src = cell_text(rows{r, 7});
        % reference 50 written as "r50" or as the bare number "50"
        cites = ~isempty(regexpi(src, '(?<!\d)50(?!\d)', 'once'));
        if isempty(src)
            c.no_source{end+1} = sprintf('%s / %s', dom, cri); %#ok<AGROW>
        end
        if cites && isempty(alt_text)
            c.r50_notes{end+1} = sprintf(['%s / %s: sources cite r50 but ' ...
                'score_without_r50 is empty (treated as unchanged)'], dom, cri); %#ok<AGROW>
        elseif ~cites && ~isempty(alt_text)
            c.r50_notes{end+1} = sprintf(['%s / %s: score_without_r50 is filled but ' ...
                'sources do not cite r50'], dom, cri); %#ok<AGROW>
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
C = readcell(file, 'FileType', 'text', 'Delimiter', ',', 'Encoding', 'UTF-8');
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
function report_primary(fid, w, wo, cons, domains, rated, crit_short, porder)
emit(fid, ['\n--- PRIMARY RANKING: unweighted sum of five scores (maximum 15) ' ...
           '---\n']);
emit(fid, ['TRL score from the r06 lower bound + four consensus scores. ' ...
           'Rank 1 = most mature;\ntied domains share the average rank.\n']);
width = max([cellfun(@numel, cons.technology); numel('technology_scored')]);
emit(fid, '%-16s %-*s | %8s %6s | %11s %9s\n', 'domain', width, 'technology_scored', ...
     'sum', 'rank', 'sum w/o r50', 'rank w/o');
for i = porder.'
    emit(fid, '%-16s %-*s | %8d %6.1f | %11d %9.1f\n', domains{i}, width, ...
         cons.technology{i}, w.sum(i), w.rank(i), wo.sum(i), wo.rank(i));
end
emit(fid, '\nScores summed (with r50 | without r50):\n');
emit(fid, '%-16s%s |%s\n', 'domain', sprintf(' %9s', crit_short{:}), ...
     sprintf(' %9s', crit_short{:}));
for i = porder.'
    emit(fid, '%-16s%s |%s\n', domains{i}, sprintf(' %9d', w.scores(i, :)), ...
         sprintf(' %9d', wo.scores(i, :)));
end
[di, ci] = find(cons.score ~= cons.without);
cells = sortrows([di(:), ci(:)]);
emit(fid, 'Cells whose score changes without r50: %d\n', size(cells, 1));
for k = 1:size(cells, 1)
    i = cells(k, 1); j = cells(k, 2);
    emit(fid, '  %-16s %-24s %d -> %d\n', domains{i}, rated{j}, ...
         cons.score(i, j), cons.without(i, j));
end
emit(fid, 'Possible r50 inconsistencies in the consensus file: %d\n', ...
     numel(cons.r50_notes));
for k = 1:numel(cons.r50_notes)
    emit(fid, '  %s\n', cons.r50_notes{k});
end
emit(fid, 'Consensus rows with an empty "sources" field: %d\n', numel(cons.no_source));
for k = 1:numel(cons.no_source)
    emit(fid, '  %s\n', cons.no_source{k});
end
end

function report_mc(fid, heading, w, wo, domains, porder)
emit(fid, '\n--- %s ---\n', heading);
emit(fid, '%-16s | %-34s | %-34s\n', '', 'with r50', 'without r50');
head = sprintf('%12s %7s %6s %6s', 'P(top, ties)', 'median', 'p05', 'p95');
emit(fid, '%-16s | %-34s | %-34s\n', 'domain', head, head);
for i = porder.'
    emit(fid, '%-16s | %12.4f %7.2f %6.2f %6.2f    | %12.4f %7.2f %6.2f %6.2f\n', ...
         domains{i}, w.p_top(i), w.med(i), w.p05(i), w.p95(i), ...
         wo.p_top(i), wo.med(i), wo.p05(i), wo.p95(i));
end
emit(fid, 'P(top, ties) counts every tie for first, so a column can sum to more than 1.\n');
emit(fid, 'Secondary:\n');
head = sprintf('%12s %10s', 'P(rank<=1.5)', 'P(rank=1)');
emit(fid, '%-16s | %-34s | %-34s\n', 'domain', head, head);
for i = porder.'
    emit(fid, '%-16s | %12.4f %10.4f            | %12.4f %10.4f\n', domains{i}, ...
         w.p_le15(i), w.p_first(i), wo.p_le15(i), wo.p_first(i));
end
emit(fid, 'First place tied (share of iterations): with r50 %.4f | without r50 %.4f\n', ...
     w.tie_share, wo.tie_share);
end

function report_loo(fid, heading, w, wo, domains, porder, crit_short)
emit(fid, '\n--- %s ---\n', heading);
emit(fid, 'Rank with one criterion left out (equal weights, no perturbation)\n');
emit(fid, '%-16s | %-50s| %s\n', '', 'with r50', 'without r50');
emit(fid, '%-16s |%s |%s\n', 'left out ->', sprintf(' %9s', crit_short{:}), ...
     sprintf(' %9s', crit_short{:}));
for i = porder.'
    emit(fid, '%-16s |%s |%s\n', domains{i}, sprintf(' %9.1f', w.loo(i, :)), ...
         sprintf(' %9.1f', wo.loo(i, :)));
end
end

function report_bounds(fid, label, b, domains)
% What changes between the lower- and upper-bound TRL runs
emit(fid, '\nLower versus upper TRL bound (%s):\n', label);
a = leaders(b.main.p_top); u = leaders(b.upper.p_top);
emit(fid, '  Highest P(top, ties):  lower %s | upper %s | changes: %s\n', ...
     name_list(domains, a), name_list(domains, u), yesno(~isequal(a, u)));
a = leaders(b.main.p_le15); u = leaders(b.upper.p_le15);
emit(fid, '  Highest P(rank<=1.5) [secondary]:  lower %s | upper %s | changes: %s\n', ...
     name_list(domains, a), name_list(domains, u), yesno(~isequal(a, u)));
moved = find(abs(b.main.med - b.upper.med) > 1e-9);
emit(fid, '  Median ranks change: %s\n', yesno(~isempty(moved)));
for i = moved(:).'
    emit(fid, '    %-16s lower %.2f -> upper %.2f\n', domains{i}, b.main.med(i), ...
         b.upper.med(i));
end
end

function report_adversarial(fid, label, a, domains, criteria)
emit(fid, '\n[%s]\n', label);
if a.tied
    emit(fid, 'RESULT (%s): %d domains already tie for first: %s\n', label, ...
         numel(a.leaders), strjoin(domains(a.leaders), ', '));
    emit(fid, 'No domain is uniquely first, so no minimum number of changes applies.\n');
    return;
end
L = a.leaders;
if isnan(a.n_min)
    emit(fid, 'RESULT (%s): %s stays uniquely first for any changes within 0-3.\n', ...
         label, domains{L});
    return;
end
emit(fid, 'Top-ranked domain: %s (sum %d)\n', domains{L}, a.totals(L));
emit(fid, ['RESULT (%s): minimum number of one-point changes for %s to stop being ' ...
           'uniquely first: %d\n'], label, domains{L}, a.n_min);
emit(fid, 'Domain(s) that can tie or overtake it with that number: %s\n', ...
     strjoin(domains(a.challengers), ', '));
emit(fid, 'One minimal set of changes:\n');
cells = unique(a.changes(:, 1:2), 'rows', 'stable');
for k = 1:size(cells, 1)
    i = cells(k, 1); c = cells(k, 2);
    step = sum(a.changes(a.changes(:, 1) == i & a.changes(:, 2) == c, 3));
    emit(fid, '  %-16s %-24s %d -> %d\n', domains{i}, criteria{c}, ...
         a.scores(i, c), a.scores(i, c) + step);
end
emit(fid, 'This set moves each cell at most once: %s\n', yesno(a.distinct));
emit(fid, 'Sums after these changes:');
[~, order] = sort(a.totals, 'descend');
for i = order.'
    emit(fid, ' %s %d;', domains{i}, a.new_totals(i));
end
emit(fid, '\n');
end

function report_r06(fid, w, wo, ref_rank, domains, porder, opt)
emit(fid, ['\n--- R5. Robustness: comparison with the ranking implied by r06 TRL ' ...
           'alone ---\n']);
emit(fid, 'r06 ranking: by trl_low, ties broken by trl_high; remaining ties averaged.\n');
emit(fid, 'Only %d domains are compared.\n', numel(domains));

emit(fid, '\nR5a. Comparison that excludes TRL as a criterion (4 judged criteria only)\n');
emit(fid, ['This work: domains ranked by the sum of the four judged consensus ' ...
           'scores (maximum 12);\nties averaged. Secondary: median rank of the ' ...
           'same Monte Carlo on these four criteria\n(N = %d, rng(%d), flat ' ...
           'Dirichlet on 4 weights, same perturbation rule).\n'], opt.N, opt.seed);
emit(fid, '%-16s %9s | %-34s | %-34s\n', '', '', 'with r50', 'without r50');
head = sprintf('%6s %6s %9s %10s', 'sum', 'rank', 'MC median', 'MC rank');
emit(fid, '%-16s %9s | %-34s | %-34s\n', 'domain', 'r06 rank', head, head);
for i = porder.'
    emit(fid, '%-16s %9.1f | %6d %6.1f %9.2f %10.1f | %6d %6.1f %9.2f %10.1f\n', ...
         domains{i}, ref_rank(i), ...
         w.rated_sum(i), w.rated_sum_rank(i), w.rated_only.med(i), ...
         w.rated_only.med_rank(i), ...
         wo.rated_sum(i), wo.rated_sum_rank(i), wo.rated_only.med(i), ...
         wo.rated_only.med_rank(i));
end
emit(fid, ['Spearman rank correlation with r06, excludes TRL as a criterion ' ...
           '(sum of four):\n']);
emit(fid, '  with r50:    %s\n  without r50: %s\n', rho_text(w.rho_rated), ...
     rho_text(wo.rho_rated));
emit(fid, 'Secondary, same comparison using the Monte Carlo median rank:\n');
emit(fid, '  with r50:    %s\n  without r50: %s\n', rho_text(w.rho_rated_mc), ...
     rho_text(wo.rho_rated_mc));
emit(fid, ['This comparison is computed identically for both TRL bounds, so there ' ...
           'is one value\nfor each score set.\n']);

emit(fid, '\nR5b. PARTLY CIRCULAR (TRL is shared): all 5 criteria\n');
emit(fid, 'This work: domains ranked by median Monte Carlo rank; ties averaged.\n');
emit(fid, '%-16s %9s | %-29s | %-29s\n', '', '', 'with r50', 'without r50');
head = sprintf('%6s %7s %6s %7s', 'lo med', 'lo rank', 'up med', 'up rank');
emit(fid, '%-16s %9s | %-29s | %-29s\n', 'domain', 'r06 rank', head, head);
for i = porder.'
    emit(fid, '%-16s %9.1f | %6.2f %7.1f %6.2f %7.1f | %6.2f %7.1f %6.2f %7.1f\n', ...
         domains{i}, ref_rank(i), ...
         w.main.med(i), w.main.med_rank(i), w.upper.med(i), w.upper.med_rank(i), ...
         wo.main.med(i), wo.main.med_rank(i), wo.upper.med(i), wo.upper.med_rank(i));
end
emit(fid, 'Spearman rank correlation with r06, partly circular:\n');
emit(fid, '  lower bound: with r50 %s | without r50 %s\n', rho_text(w.rho_main), ...
     rho_text(wo.rho_main));
emit(fid, '  upper bound: with r50 %s | without r50 %s\n', rho_text(w.rho_upper), ...
     rho_text(wo.rho_upper));
end

function report_r50_effect(fid, w, wo)
differs = @(a, b) yesno(~isequaln(a, b));
emit(fid, '\n--- Effect of removing r50: does anything change? ---\n');
emit(fid, 'Primary sums:                        %s\n', differs(w.sum, wo.sum));
emit(fid, 'Primary ranks:                       %s\n', differs(w.rank, wo.rank));
emit(fid, 'Highest P(top, ties), lower bound:   %s\n', ...
     differs(leaders(w.main.p_top), leaders(wo.main.p_top)));
emit(fid, 'Highest P(top, ties), upper bound:   %s\n', ...
     differs(leaders(w.upper.p_top), leaders(wo.upper.p_top)));
emit(fid, 'Median ranks, lower bound:           %s\n', differs(w.main.med, wo.main.med));
emit(fid, 'Median ranks, upper bound:           %s\n', differs(w.upper.med, wo.upper.med));
emit(fid, 'Leave-one-out ranks, lower bound:    %s\n', differs(w.main.loo, wo.main.loo));
emit(fid, 'Leave-one-out ranks, upper bound:    %s\n', differs(w.upper.loo, wo.upper.loo));
emit(fid, 'Adversarial result (leader, number): %s\n', ...
     differs({w.adv.leaders, w.adv.n_min}, {wo.adv.leaders, wo.adv.n_min}));
emit(fid, 'Spearman values (all four):          %s\n', ...
     differs(round([w.rho_rated, w.rho_rated_mc, w.rho_main, w.rho_upper], 10), ...
             round([wo.rho_rated, wo.rho_rated_mc, wo.rho_main, wo.rho_upper], 10)));
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

function write_loo_table(file, w, sum_without, order, names, crit_table)
% Primary ranking first (sum, rank, sum without the preprint), then the
% robustness columns: P(top, ties) and leave-one-criterion-out ranks
% (lower-bound TRL, with all sources). Rows in primary order.
fid = fopen(file, 'w');
if fid < 0
    error('sim2:output', 'Cannot write %s', file);
end
closer = onCleanup(@() fclose(fid));
nC = numel(crit_table);
fprintf(fid, '\\begin{table}[!t]\n');
fprintf(fid, '\\renewcommand{\\arraystretch}{1.3}\n');
fprintf(fid, '\\setlength{\\tabcolsep}{3pt}\n');
fprintf(fid, ['\\caption{Primary Ranking by the Unweighted Sum of Five Scores ' ...
              '(Maximum 15; 1 = Most Mature), Also Without the Preprint ' ...
              '\\cite{r50_Muradoglu2025}, and Robustness Analyses: Monte Carlo ' ...
              'Probability of Ranking First (All Ties Counted) and Rank With One ' ...
              'Criterion Left Out. Lower-Bound TRL Rule}\n']);
fprintf(fid, '\\label{tab:loo}\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\footnotesize\n');
fprintf(fid, '\\begin{tabular}{|l|c|c|c|c|%s}\n', repmat('c|', 1, nC));
fprintf(fid, '\\hline\n');
fprintf(fid, [' & \\multicolumn{3}{c|}{Primary ranking} & ' ...
              '\\multicolumn{%d}{c|}{Robustness} \\\\\n'], nC + 1);
fprintf(fid, '\\cline{2-%d}\n', nC + 5);
fprintf(fid, ' & & & & & \\multicolumn{%d}{c|}{Rank with criterion left out} \\\\\n', nC);
fprintf(fid, '\\cline{6-%d}\n', nC + 5);
fprintf(fid, ['Domain & Sum & Rank & \\shortstack{Sum w/o\\\\preprint} & ' ...
              '$P_{\\mathrm{top}}$%s \\\\\n'], sprintf(' & %s', crit_table{:}));
fprintf(fid, '\\hline\n');
for i = order(:).'
    fprintf(fid, '%s & %d & %g & %d & %.3f%s \\\\\n', names{i}, w.sum(i), ...
            w.rank(i), sum_without(i), w.main.p_top(i), ...
            sprintf(' & %g', w.main.loo(i, :)));
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
