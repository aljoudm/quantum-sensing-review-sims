function d = sim3_data()
%SIM3_DATA Model and source values for Sim 3 (loss-limited squeezing).
%   Single source of the numbers used by sim3_squeezing_loss.m and
%   combine_loss_gap.m.

% Pure-loss model
db2var    = @(dB) 10.^(-dB/10);   % noise variance relative to shot noise
d.s_obs   = @(dB_src, eta) -10*log10(eta.*db2var(dB_src) + (1 - eta));
d.ceil_db = @(eta) -10*log10(1 - eta);       % infinite source squeezing

% Advanced LIGO (r03, Table I and Sec. IV-D)
d.ligo.src = 7.2;    d.ligo.src_err = 0.3;   % dB, generated squeezing
% Budget: efficiency from the loss budget and r03's predictions
d.bud.eta  = 0.75;   d.bud.eta_err  = 0.06;  % budgeted total efficiency
d.bud.pred = 4.1;    d.bud.pred_err = 0.6;   % dB, r03 prediction, losses only
% (r03 predicts 4.0 +/- 0.6 dB with losses plus ~15 mrad phase noise)
% Measurement: r03 infers eta FROM the observed squeezing, so agreement of
% the model at this eta is a consistency check, not an independent test.
d.meas.eta = 0.66;   d.meas.eta_err = 0.02;  % efficiency inferred by r03
d.meas.obs = 3.2;    d.meas.obs_err = 0.1;   % dB, observed squeezing
% Optomechanics (r17), no error bars given. r17 reports the observed value
% as consistent with the overall loss.
d.om.src = 4;        % dB, generated squeezing, "about" (r17)
d.om.eta = 0.74;     % detection efficiency (r17)
d.om.obs = 2.4;      % dB, observed squeezing, "about" (r17)

d.src_levels = [4 7.2 10 15];   % dB, curves shown in the figure
end
