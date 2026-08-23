function lag = estimate_gap_peak_lag(result, T_wave)
%ESTIMATE_GAP_PEAK_LAG Estimate the peak lag between PVS compression
%and the effective arterial gap over the last waveform period.
%
% The returned lag is wrapped to [-T_wave/2, T_wave/2].
%
% Positive lag means that the gap peak occurs after the compression peak.

t = result.t(:);
S = [result.flux.S_a].';
w = [result.flux.w_eff].';

if isempty(t) || T_wave <= 0
    lag = NaN;
    return;
end

t_start = max(t(1), t(end) - T_wave);
idx = (t >= t_start);

if nnz(idx) < 3
    lag = NaN;
    return;
end

t_last = t(idx);
S_last = max(S(idx), 0.0);
w_last = w(idx);

[~, iS] = max(S_last);
[~, iw] = max(w_last);

lag = t_last(iw) - t_last(iS);

% Wrap the lag to the nearest periodic representation.
lag = mod(lag + 0.5*T_wave, T_wave) - 0.5*T_wave;

end
