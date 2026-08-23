clear; clc; close all;

% ============================================================
% Task 3: two-parameter map in
%       alpha_AQP4  and  g_volA
%
% The mechanical opening coefficient and tau_gap are fixed at
% their baseline values. Only the effective AQP4 factor and the
% endfoot-volume-to-gap feedback strength are varied.
%
% Default grid: 11 x 11 = 121 simulations.
% Increase to 21 points per axis for a smoother publication figure.
% ============================================================

check_model_dependencies();

% ---------------- User settings ----------------
output_dir = fullfile(pwd, 'gap_sensitivity_output');
pulse_shape = 'symmetric';
simulation_end_time = 6000.0;  % s

alpha_values = linspace(0.0, 1.0, 11);
g_volA_factors = linspace(0.0, 2.0, 11);

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

p_ref = set_SR_scale(p0, pulse_shape);
SR_scale_ref = p_ref.SR_scale;

g_open_0 = p_ref.gap_SR_gain;
g_volA_0 = p_ref.gap_swelling_gain;
tau_gap_0 = p_ref.tau_gap;

ng = numel(g_volA_factors);
na = numel(alpha_values);

O_v = zeros(ng,na);
net_water = zeros(ng,na);
backflow_ratio = zeros(ng,na);
w_mean = zeros(ng,na);
w_max = zeros(ng,na);
ecs_cleared = zeros(ng,na);
mass_balance_error = zeros(ng,na);

fprintf('\nTwo-parameter sensitivity: alpha_AQP4 x g_volA\n');
fprintf('Grid size: %d x %d = %d simulations\n', ng, na, ng*na);
fprintf('Fixed SR scale = %.8g\n\n', SR_scale_ref);

run_counter = 0;

for ig = 1:ng
    g_volA = g_volA_0 * g_volA_factors(ig);

    for ia = 1:na
        run_counter = run_counter + 1;

        p_case = p_ref;
        p_case.SR_scale = SR_scale_ref;
        p_case.gap_SR_gain = g_open_0;
        p_case.gap_swelling_gain = g_volA;
        p_case.tau_gap = tau_gap_0;

        base_case = base;
        base_case.aqp4_scale = alpha_values(ia);

        cfg = set_case(base_case, ...
            sprintf('alpha_%0.3f_gvol_%0.3f', ...
            alpha_values(ia), g_volA_factors(ig)), ...
            pulse_shape, true);

        result = run_case(p_case, cfg);
        m = result.metrics;

        O_v(ig,ia) = m.tracer_venous_output;
        net_water(ig,ia) = m.net_water_PaEa;
        backflow_ratio(ig,ia) = ...
            m.backward_water_EaPa / max(m.forward_water_PaEa, eps);
        w_mean(ig,ia) = m.w_mean;
        w_max(ig,ia) = m.w_max;
        ecs_cleared(ig,ia) = m.ECS_cleared_fraction;
        mass_balance_error(ig,ia) = m.mass_balance_error;

        fprintf(['[%3d/%3d] gvol/g0=%5.2f  alpha=%4.2f  ' ...
                 'O_v=%10.5g  wmean=%.5f\n'], ...
            run_counter, ng*na, g_volA_factors(ig), ...
            alpha_values(ia), O_v(ig,ia), w_mean(ig,ia));

        clear result
    end
end

% Reference: alpha_AQP4 = 1 and g_volA/g_volA0 = 1.
[~, ia_ref] = min(abs(alpha_values - 1.0));
[~, ig_ref] = min(abs(g_volA_factors - 1.0));
O_v_ref = O_v(ig_ref, ia_ref);
O_v_relative = O_v / max(O_v_ref, eps);

% At each g_volA, quantify the loss relative to alpha_AQP4 = 1.
aqp4_loss_percent = zeros(size(O_v));
for ig = 1:ng
    denominator = max(abs(O_v(ig, ia_ref)), eps);
    aqp4_loss_percent(ig,:) = ...
        100.0 * (O_v(ig, ia_ref) - O_v(ig,:)) / denominator;
end

% Flatten the parameter map for CSV export.
[G_factor_grid, Alpha_grid] = ndgrid(g_volA_factors, alpha_values);
G_value_grid = g_volA_0 * G_factor_grid;

T_map = table( ...
    Alpha_grid(:), G_factor_grid(:), G_value_grid(:), ...
    O_v(:), O_v_relative(:), aqp4_loss_percent(:), ...
    net_water(:), backflow_ratio(:), ...
    w_mean(:), w_max(:), ecs_cleared(:), ...
    mass_balance_error(:), ...
    'VariableNames', { ...
    'alpha_AQP4', 'g_volA_over_baseline', 'g_volA', ...
    'O_v', 'O_v_relative_to_full_baseline', ...
    'AQP4LossPercent_relative_to_alpha1', ...
    'NetWaterPaEa', 'BackflowRatio', ...
    'w_mean', 'w_max', 'ECSClearedFraction', ...
    'MassBalanceError'});

csv_file = fullfile(output_dir, ...
    'sensitivity_03_aqp4_gvol_heatmap.csv');
writetable(T_map, csv_file);

if save_mat_file
    save(fullfile(output_dir, ...
        'sensitivity_03_aqp4_gvol_heatmap.mat'), ...
        'alpha_values', 'g_volA_factors', ...
        'O_v', 'O_v_relative', 'aqp4_loss_percent', ...
        'net_water', 'backflow_ratio', ...
        'w_mean', 'w_max', 'ecs_cleared', ...
        'mass_balance_error', ...
        'p_ref', 'base', 'SR_scale_ref');
end

% ---------------- Figure ----------------
fig = figure('Color','w', 'Position',[60 150 1500 470]);
tl = tiledlayout(1,3, 'TileSpacing','compact', 'Padding','compact');

nexttile;
imagesc(alpha_values, g_volA_factors, O_v_relative);
axis xy;
xlabel('$\alpha_{\mathrm{AQP4}}$', 'Interpreter','latex');
ylabel('$g_{\mathrm{volA}}/g_{\mathrm{volA}}^0$', ...
    'Interpreter','latex');
title('$O_v(T)/O_v^{\mathrm{baseline}}(T)$', ...
    'Interpreter','latex');
colorbar;

nexttile;
imagesc(alpha_values, g_volA_factors, w_mean);
axis xy;
xlabel('$\alpha_{\mathrm{AQP4}}$', 'Interpreter','latex');
ylabel('$g_{\mathrm{volA}}/g_{\mathrm{volA}}^0$', ...
    'Interpreter','latex');
title('Mean arterial gap factor');
colorbar;

nexttile;
imagesc(alpha_values, g_volA_factors, aqp4_loss_percent);
axis xy;
xlabel('$\alpha_{\mathrm{AQP4}}$', 'Interpreter','latex');
ylabel('$g_{\mathrm{volA}}/g_{\mathrm{volA}}^0$', ...
    'Interpreter','latex');
title('Loss relative to $\alpha_{\mathrm{AQP4}}=1$ (\%)', ...
    'Interpreter','latex');
colorbar;

title(tl, ...
    'AQP4 sensitivity depends on endfoot-volume-to-gap coupling');

save_figure_300dpi(fig, ...
    fullfile(output_dir, ...
    'Fig_sensitivity_03_aqp4_gvol_heatmap.png'));

fprintf('\nReference O_v(alpha=1, gvol/g0=1) = %.8g\n', O_v_ref);
fprintf('Saved:\n  %s\n  %s\n', csv_file, ...
    fullfile(output_dir, ...
    'Fig_sensitivity_03_aqp4_gvol_heatmap.png'));
