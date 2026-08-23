function [wave, dwave_dt] = vessel_waveform(t, p, shape)
%VESSEL_WAVEFORM Vessel-radius forcing waveform.
%
% Output:
%   wave      : dimensionless vessel-radius waveform
%   dwave_dt  : time derivative of wave
%
% Interpretation:
%   R_v(t) = R_v0 * (1 + p.radius_pulse_fraction * wave(t))
%
% Cases:
%   cardiac     : zero-mean oscillation with dilation and contraction
%   symmetric   : nonnegative symmetric vasodilation pulse
%   asymmetric  : nonnegative fast-rise slow-decay vasodilation pulse

% phase = mod(t, p.pulse_period) / p.pulse_period;
% dphase_dt = 1.0 / p.pulse_period;

switch lower(shape)

    case 'cardiac'
        % Zero-mean cardiac-like oscillation.
        % wave > 0: dilation
        % wave < 0: contraction
%        p.pulse_period = 0.2;            % 5 Hz
        %p.radius_pulse_fraction = 0.005; % 0.5% oscillation
        phase = mod(t, p.pulse_period) / p.pulse_period;
        dphase_dt = 1.0 / p.pulse_period;
        wave = sin(2*pi*phase);
        dwave_dphase = 2*pi*cos(2*pi*phase);
        dwave_dt = dwave_dphase * dphase_dt;

    case 'symmetric'
        % Nonnegative symmetric vasodilation pulse.
        % Vessel dilates and then returns to baseline.
 %       p.pulse_period = 10.0;           % one event every 10 s
%        p.radius_pulse_fraction = 0.20;  % 20% dilation
        phase = mod(t, p.pulse_period) / p.pulse_period;
        dphase_dt = 1.0 / p.pulse_period;
        sigma = 0.12;
        center = 0.50;

        raw = exp(-((phase - center).^2) / (2*sigma^2));
        draw_dphase = raw .* (-(phase - center) / sigma^2);

        % Normalize using one full period.
        ph_grid = linspace(0, 1, 5000);
        raw_grid = exp(-((ph_grid - center).^2) / (2*sigma^2));
        raw_max = max(raw_grid);

        wave = raw / raw_max;
        dwave_dt = draw_dphase / raw_max * dphase_dt;

    case 'asymmetric'
        % Nonnegative fast-rise slow-decay vasodilation pulse.
        % Vessel rapidly dilates and then slowly returns to baseline.
     %   p.pulse_period = 10.0;           % one event every 10 s
     %   p.radius_pulse_fraction = 0.20;  % 20% dilation
        phase = mod(t, p.pulse_period) / p.pulse_period;
        dphase_dt = 1.0 / p.pulse_period;

        % tau_rise = 0.04;
        % tau_decay = 0.204;   % same-AUC approximately with symmetric waveform

        % tau_rise = 0.06;
        % tau_decay = 0.172;   % same-AUC approximately with symmetric waveform
        tau_rise = 0.08;
        tau_decay = 0.145;
        raw = exp(-phase/tau_decay) - exp(-phase/tau_rise);
        draw_dphase = ...
            -(1/tau_decay)*exp(-phase/tau_decay) ...
            + (1/tau_rise)*exp(-phase/tau_rise);

        % Numerical protection near phase = 0.
        if raw < 0
            raw = 0;
            draw_dphase = 0;
        end

        % Normalize using one full period.
        ph_grid = linspace(0, 1, 5000);
        raw_grid = exp(-ph_grid/tau_decay) - exp(-ph_grid/tau_rise);
        raw_grid(raw_grid < 0) = 0;
        raw_max = max(raw_grid);

        wave = raw / raw_max;
        dwave_dt = draw_dphase / raw_max * dphase_dt;

    otherwise
        error('Unknown pulse shape: %s', shape);
end

end