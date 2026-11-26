function d = sim4_data()
%SIM4_DATA Operating noise and reference limits for Sim 4.
%   Single source of the numbers used by sim4_quantum_limit_gap.m and
%   combine_loss_gap.m. Each entry's ratio is operating / limit.

% 1. Gravity gradiometer, outdoor field test (r19)
d(1).label     = 'Gravity gradiometer (field)';
d(1).operating = 466;     % E/sqrt(Hz), operating noise (r19)
d(1).limit     = 44;      % E/sqrt(Hz), estimated quantum projection noise (r19)
d(1).ratio     = d(1).operating / d(1).limit;
d(1).value_text = sprintf('%.1f', d(1).ratio);    % printed at the bar end
d(1).reference = 'quantum projection noise';
d(1).quantum   = true;

% 2. NV magnetocardiography, in vivo in a shielded room (r22)
d(2).label     = 'NV MCG (in vivo)';
d(2).operating = 140;     % pT/sqrt(Hz), operating noise (r22)
d(2).limit     = 19;      % pT/sqrt(Hz), shot-noise limit (r22)
d(2).ratio     = d(2).operating / d(2).limit;
d(2).value_text = sprintf('%.1f', d(2).ratio);
d(2).reference = 'shot noise';
d(2).quantum   = true;

% 3. Rydberg electrometer, best reported, compiled in a review (r04):
%    about one order of magnitude above the antenna thermal limit.
%    Only the ratio is used; the reference is a CLASSICAL limit, second-hand.
d(3).label     = 'Rydberg E-field*';
d(3).operating = NaN;
d(3).limit     = NaN;
d(3).ratio     = 10;      % "about one order of magnitude" (r04)
d(3).value_text = '~10';  % order of magnitude only, so no decimal
d(3).reference = 'classical thermal limit, second-hand';
d(3).quantum   = false;
end
