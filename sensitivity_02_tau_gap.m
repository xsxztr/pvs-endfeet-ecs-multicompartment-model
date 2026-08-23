clear; clc; close all;

% ============================================================
% Task 2: sensitivity to the dimensionless gap-response time
%
% The parameter varied is
%       tau_hat = tau_gap / T_wave.
%
% IMPORTANT:
% In the current vessel_waveform.m, the symmetric waveform uses
% T_wave = 10 s internally. Update symmetric_wave_period below
% if that implementation is changed.
% ============================================================

check_model_dependencies();

% ---------------- User settings ----------------
output_dir = fullfile(pwd, 'gap_sensitivity_output09');
pulse_shape = 'symmetric';
symmetric_wave_period = 10.0;  % s; must match vessel_waveform.m
simulation_end_time = 6000.0;  % s
%tau_ratio_values = [0.01, 0.05, 0.10, 0.25, 0.50, 1.0, 2.0];
tau_ratio_values = [0.01, 0.05, 0.10,  0.50, 2.0];
save_mat_file = true;

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% ---------------- Baseline model ----------------
p0 = params_default();
p0.t_end = simulation_end_time;
p0.osmotic_pressure = 0.0;

base = struct();
base.aqp4_scale = 1.0;
base.osmotic_case = 'none';
base.tracer_protocol = 'ecs_clearance_uniform';

switch lower(pulse_shape)

    case 'cardiac'
        p0.pulse_period = 0.2;

    case {'symmetric','asymmetric'}
        p0.pulse_period = 10.0;
        p0.radius_pulse_fraction = 0.050;
    otherwise
        error('Unknown waveform: %s',pulse_shape);
end
p_ref = set_SR_scale(p0, pulse_shape);
SR_scale_ref = p_ref.SR_scale;

tau_values = tau_ratio_values * symmetric_wave_period;
ncase = numel(tau_values);

O_v = zeros(ncase,1);
net_water = zeros(ncase,1);
backflow_ratio = zeros(ncase,1);
w_mean = zeros(ncase,1);
w_min = zeros(ncase,1);
w_max = zeros(ncase,1);
phase_lag = zeros(ncase,1);
phase_lag_over_period = zeros(ncase,1);
ecs_cleared = zeros(ncase,1);
mass_balance_error = zeros(ncase,1);

fprintf('\nGap-response-time sensitivity under %s forcing\n', pulse_shape);
fprintf('T_wave = %.6g s, fixed SR scale = %.8g\n\n', ...
    symmetric_wave_period, SR_scale_ref);
results = cell(1,ncase);
for k = 1:ncase
    p_case = p_ref;
    p_case.SR_scale = SR_scale_ref;
    p_case.tau_gap = tau_values(k);

    cfg = set_case(base, ...
        sprintf('tau_ratio_%g', tau_ratio_values(k)), ...
        pulse_shape, true);

    results{k} = run_case(p_case, cfg);
    m = results{k}.metrics;

    O_v(k) = m.tracer_venous_output;
    net_water(k) = m.net_water_PaEa;
    backflow_ratio(k) = ...
        m.backward_water_EaPa / max(m.forward_water_PaEa, eps);
    w_mean(k) = m.w_mean;
    w_min(k) = m.w_min;
    w_max(k) = m.w_max;
    phase_lag(k) = estimate_gap_peak_lag(results{k}, symmetric_wave_period);
    phase_lag_over_period(k) = phase_lag(k) / symmetric_wave_period;
    ecs_cleared(k) = m.ECS_cleared_fraction;
    mass_balance_error(k) = m.mass_balance_error;

    fprintf(['tau/T=%6.3f  tau=%8.4g s  O_v=%10.5g  ' ...
             'R_back=%8.5f  wmean=%.5f  lag/T=%+.5f\n'], ...
        tau_ratio_values(k), tau_values(k), O_v(k), ...
        backflow_ratio(k), w_mean(k), phase_lag_over_period(k));

    clear result
end

% Normalize by the run closest to the current baseline tau_gap.
[~, idx_ref] = min(abs(tau_values - p_ref.tau_gap));
O_v_relative = O_v / max(O_v(idx_ref), eps);

T_tau = table( ...
    tau_ratio_values(:), tau_values(:), ...
    O_v, O_v_relative, net_water, backflow_ratio, ...
    w_mean, w_min, w_max, ...
    phase_lag, phase_lag_over_period, ...
    ecs_cleared, mass_balance_error, ...
    'VariableNames', { ...
    'tau_over_Twave', 'tau_gap_seconds', ...
    'O_v', 'O_v_relative_to_baseline_tau', ...
    'NetWaterPaEa', 'BackflowRatio', ...
    'w_mean', 'w_min', 'w_max', ...
    'PeakLag_seconds', 'PeakLag_over_Twave', ...
    'ECSClearedFraction', 'MassBalanceError'});




plot_gap_rectification(results)

csv_file = fullfile(output_dir, 'sensitivity_02_tau_gap09.csv');
writetable(T_tau, csv_file);

if save_mat_file
    save(fullfile(output_dir, 'sensitivity_02_tau_gap09.mat'), ...
        'T_tau', 'p_ref', 'base', 'SR_scale_ref', ...
        'symmetric_wave_period');
end

% ---------------- Figure ----------------
fig = figure('Color','w', 'Position',[100 100 1120 760]);
tl = tiledlayout(2,2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
semilogx(tau_ratio_values, O_v_relative, '-o', 'LineWidth',1.5);
xlabel('$\tau_w/T_{\mathrm{wave}}$', 'Interpreter','latex');
ylabel('$O_v(T)/O_v^{\mathrm{baseline}}(T)$', 'Interpreter','latex');
title('Cumulative venous output');
grid on;

nexttile;
semilogx(tau_ratio_values, backflow_ratio, '-o', 'LineWidth',1.5);
xlabel('$\tau_w/T_{\mathrm{wave}}$', 'Interpreter','latex');
ylabel('$R_{\mathrm{back}}$', 'Interpreter','latex');
title('Backflow ratio');
grid on;

nexttile;
semilogx(tau_ratio_values, w_mean, '-o', 'LineWidth',1.5);
hold on;
semilogx(tau_ratio_values, w_max, '-s', 'LineWidth',1.5);
xlabel('$\tau_w/T_{\mathrm{wave}}$', 'Interpreter','latex');
ylabel('Gap factor');
title('Gap response');
legend({'$\overline{w_a}$','$\max w_a$'}, ...
    'Interpreter','latex', 'Location','best');
grid on;

nexttile;
semilogx(tau_ratio_values, phase_lag_over_period, '-o', 'LineWidth',1.5);
xlabel('$\tau_w/T_{\mathrm{wave}}$', 'Interpreter','latex');
ylabel('$\Delta t_{\mathrm{peak}}/T_{\mathrm{wave}}$', ...
    'Interpreter','latex');
title('Gap-response phase lag');
grid on;

%title(tl, 'Sensitivity to the arterial gap response time');

save_figure_300dpi(fig, ...
    fullfile(output_dir, 'Fig_sensitivity_02_tau_gap09.png'));

fprintf('\nSaved:\n  %s\n  %s\n', csv_file, ...
    fullfile(output_dir, 'Fig_sensitivity_02_tau_gap09.png'));
