clear; clc; close all;

% ============================================================
% Task 1: mechanism ablation for dynamic arterial gap regulation
%
% Cases:
%   1) fixed gap
%   2) mechanical regulation only
%   3) endfoot-volume regulation only
%   4) full dynamic regulation
%
% This script assumes that the model files (params_default.m,
% set_case.m, set_SR_scale.m, run_case.m, etc.) are on the
% MATLAB path or in the current folder.
% ============================================================

check_model_dependencies();

% ---------------- User settings ----------------
output_dir = fullfile(pwd, 'gap_sensitivity_output09');
pulse_shape = 'symmetric';
simulation_end_time = 6000.0;  % s; use the value reported in the manuscript
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

% Compute the normalization scale once and keep it fixed for all cases.
switch lower(pulse_shape)

    case 'cardiac'
        p0.pulse_period = 0.2;

    case {'symmetric','asymmetric'}
        p0.pulse_period = 10.0;
        p0.radius_pulse_fraction = 0.05;
    otherwise
        error('Unknown waveform: %s',cfg.pulse_shape);
end
p_ref = set_SR_scale(p0, pulse_shape);
SR_scale_ref = p_ref.SR_scale;

g_open_0 = p_ref.gap_SR_gain;
g_volA_0 = p_ref.gap_swelling_gain;

case_names = {
    'Fixed gap'
    'Mechanical only'
    'Volume only'
    'Full regulation'
    };

dynamic_flags = [false, true, true, true];
g_open_values = [0.0, g_open_0, 0.0, g_open_0];
g_volA_values = [0.0, 0.0, g_volA_0, g_volA_0];

ncase = numel(case_names);

O_v = zeros(ncase,1);
net_water = zeros(ncase,1);
forward_water = zeros(ncase,1);
backward_water = zeros(ncase,1);
backflow_ratio = zeros(ncase,1);
w_mean = zeros(ncase,1);
w_min = zeros(ncase,1);
w_max = zeros(ncase,1);
ecs_cleared = zeros(ncase,1);
pv_efficiency = zeros(ncase,1);
mass_balance_error = zeros(ncase,1);

fprintf('\nMechanism ablation under %s forcing\n', pulse_shape);
fprintf('Fixed SR scale = %.8g\n\n', SR_scale_ref);
results = cell(1,ncase);
for k = 1:ncase
    p_case = p_ref;
    p_case.SR_scale = SR_scale_ref;
    p_case.gap_SR_gain = g_open_values(k);
    p_case.gap_swelling_gain = g_volA_values(k);

    cfg = set_case(base, ...
        case_names(k), ...
        pulse_shape, dynamic_flags(k));

    results{k} = run_case(p_case, cfg);
   % results{k}=result;
    m =  results{k}.metrics;

    O_v(k) = m.tracer_venous_output;
    net_water(k) = m.net_water_PaEa;
    forward_water(k) = m.forward_water_PaEa;
    backward_water(k) = m.backward_water_EaPa;
    backflow_ratio(k) = backward_water(k) / max(forward_water(k), eps);
    w_mean(k) = m.w_mean;
    w_min(k) = m.w_min;
    w_max(k) = m.w_max;
    ecs_cleared(k) = m.ECS_cleared_fraction;
    pv_efficiency(k) = m.Pv_out_efficiency;
    mass_balance_error(k) = m.mass_balance_error;

    fprintf(['%-18s  O_v=%10.5g  netPaEa=%+10.5g  ' ...
             'R_back=%8.5f  w=[%.4f, %.4f], mean=%.4f\n'], ...
        case_names{k}, O_v(k), net_water(k), backflow_ratio(k), ...
        w_min(k), w_max(k), w_mean(k));

    clear result
end
%plot_pressure_distributions(results);
plot_gap_rectification(results)
O_v_over_fixed = O_v / max(O_v(1), eps);

T_ablation = table( ...
    string(case_names), dynamic_flags(:), ...
    g_open_values(:), g_volA_values(:), ...
    O_v, O_v_over_fixed, ...
    net_water, forward_water, backward_water, backflow_ratio, ...
    w_mean, w_min, w_max, ...
    ecs_cleared, pv_efficiency, mass_balance_error, ...
    'VariableNames', { ...
    'Case', 'DynamicGap', ...
    'g_open', 'g_volA', ...
    'O_v', 'O_v_over_fixed', ...
    'NetWaterPaEa', 'ForwardWaterPaEa', 'BackwardWaterEaPa', ...
    'BackflowRatio', ...
    'w_mean', 'w_min', 'w_max', ...
    'ECSClearedFraction', 'PvOutEfficiency', 'MassBalanceError'});

csv_file = fullfile(output_dir, 'sensitivity_01_ablation09.csv');
writetable(T_ablation, csv_file);

if save_mat_file
    save(fullfile(output_dir, 'sensitivity_01_ablation09.mat'), ...
        'T_ablation', 'p_ref', 'base', 'SR_scale_ref');
end

% ---------------- Figure ----------------
labels = categorical(case_names, case_names, 'Ordinal', true);

fig = figure('Color','w', 'Position',[100 100 1150 760]);
tl = tiledlayout(2,2, 'TileSpacing','compact', 'Padding','compact');

nexttile;
bar(labels, O_v_over_fixed);
ylabel('$O_v(T)/O_v^{\mathrm{fixed}}(T)$', 'Interpreter','latex');
title('Cumulative venous output');
grid on;
xtickangle(18);

nexttile;
bar(labels, net_water);
ylabel('$\int_0^T Q_{P_aE_a}\,dt$', 'Interpreter','latex');
title('Net arterial PVS-ECS water exchange');
grid on;
xtickangle(18);

nexttile;
bar(labels, [w_mean, w_max], 'grouped');
ylabel('Gap factor');
title('Mean and maximum gap factors');
legend({'$\overline{w_a}$','$\max w_a$'}, ...
    'Interpreter','latex', 'Location','best');
grid on;
xtickangle(18);

nexttile;
bar(labels, 1-backflow_ratio);
ylabel('$1-R_{\mathrm{back}}$', 'Interpreter','latex');
title('Recovery-phase backflow ratio');
grid on;
xtickangle(18);

%title(tl, 'Mechanism ablation of dynamic arterial gap regulation');

save_figure_300dpi(fig, ...
    fullfile(output_dir, 'Fig_sensitivity_01_ablation09.png'));

fprintf('\nSaved:\n  %s\n  %s\n', csv_file, ...
    fullfile(output_dir, 'Fig_sensitivity_01_ablation09.png'));
