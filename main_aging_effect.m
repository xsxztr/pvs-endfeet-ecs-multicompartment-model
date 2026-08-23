clear; clc; close all;

p0 = params_default();

% ============================================================
% Aging-associated impairment study
% Primary waveform: symmetric slow vasomotion
%
% epsilon/epsilon0 -> cfg.wave_scale
% eta_o            -> p_case.eta_outer
% alpha_a          -> cfg.aqp4_scale
% ============================================================

p0.t_end = 6000.0;
p0.pulse_period = 10.0;
p0.osmotic_pressure = 0.0;

pulse_shape = 'symmetric';
dynamic_gap = true;

epsilon_young = 1.0;
eta_young = 0.20;
alpha_young = 1.0;

% Compute the mechanical-source normalization once from the
% young reference case and keep it fixed for every aging case.
p_ref = p0;
p_ref.eta_outer = eta_young;
p_ref = set_SR_scale(p_ref, pulse_shape);
SR_scale_young = p_ref.SR_scale;

fprintf('Young-reference SR scale = %.6g\n', SR_scale_young);

specs = struct('name', {}, 'group', {}, 'xvalue', {}, ...
    'epsilon_ratio', {}, 'eta_outer', {}, 'aqp4_scale', {});

n = 0;

% Vessel-motion amplitude sweep
epsilon_values = [1.00, 0.75, 0.50];
epsilon_names = {'eps_1p00', 'eps_0p75', 'eps_0p50'};
for i = 1:numel(epsilon_values)
    n = n + 1;
    specs(n).name = epsilon_names{i};
    specs(n).group = 'epsilon';
    specs(n).xvalue = epsilon_values(i);
    specs(n).epsilon_ratio = epsilon_values(i);
    specs(n).eta_outer = eta_young;
    specs(n).aqp4_scale = alpha_young;
end

% Effective PVS boundary-coupling sweep
%eta_values = [0.20, 0.50, 0.70, 0.83];
eta_values = [0.20, 0.50, 0.75];
eta_names = {'eta_0p20', 'eta_0p50', 'eta_0p70', 'eta_0p83'};
for i = 1:numel(eta_values)
    n = n + 1;
    specs(n).name = eta_names{i};
    specs(n).group = 'eta';
    specs(n).xvalue = eta_values(i);
    specs(n).epsilon_ratio = epsilon_young;
    specs(n).eta_outer = eta_values(i);
    specs(n).aqp4_scale = alpha_young;
end

% Effective perivascular AQP4 sweep
alpha_values = [1.00, 0.50,  0.10];
alpha_names = {'alpha_1p00', 'alpha_0p50', 'alpha_0p10', 'alpha_0p00'};
for i = 1:numel(alpha_values)
    n = n + 1;
    specs(n).name = alpha_names{i};
    specs(n).group = 'alpha';
    specs(n).xvalue = alpha_values(i);
    specs(n).epsilon_ratio = epsilon_young;
    specs(n).eta_outer = eta_young;
    specs(n).aqp4_scale = alpha_values(i);
end

% Representative combined-aging phenotypes
combined_names = {'young', 'moderate_aging', 'advanced_aging'};
combined_eps = [1.00, 0.75, 0.50];
combined_eta = [0.20, 0.50, 0.75];
combined_alpha = [1.00, 0.50, 0.10];

for i = 1:numel(combined_names)
    n = n + 1;
    specs(n).name = combined_names{i};
    specs(n).group = 'combined';
    specs(n).xvalue = i - 1;
    specs(n).epsilon_ratio = combined_eps(i);
    specs(n).eta_outer = combined_eta(i);
    specs(n).aqp4_scale = combined_alpha(i);
end

results = cell(numel(specs), 1);

fprintf('\nAging-associated symmetric slow-vasomotion study\n\n');

for k = 1:numel(specs)
    s = specs(k);

    p_case = p0;
    p_case.eta_outer = s.eta_outer;
    p_case.SR_scale = SR_scale_young;

    base = struct();
    base.aqp4_scale = s.aqp4_scale;
    base.wave_scale = s.epsilon_ratio;
    base.osmotic_case = 'endfoot_high';
    base.tracer_protocol = 'ecs_clearance_uniform';

    cfg = set_case(base, s.name, pulse_shape, dynamic_gap);

    fprintf('Running %-22s eps=%.2f, eta=%.2f, alpha=%.2f\n', ...
        cfg.name, s.epsilon_ratio, s.eta_outer, s.aqp4_scale);

    results{k} = run_case(p_case, cfg);
    results{k}.aging = s;

    m = results{k}.metrics;
    Sa = [results{k}.flux.S_a].';

    fprintf(['  ECSclear=%.4f, VenOut=%.4g (%.3g%%), PvEff=%.3f%%, ', ...
             'w=[%.4g, %.4g], mean=%.4g, max|S_a|=%.4g\n'], ...
        m.ECS_cleared_fraction, m.tracer_venous_output, ...
        100*m.venous_output_fraction, 100*m.Pv_out_efficiency, ...
        m.w_min, m.w_max, m.w_mean, max(abs(Sa)));
end

N = numel(results);

case_name = strings(N,1);
group_name = strings(N,1);
epsilon_ratio = zeros(N,1);
eta_outer = zeros(N,1);
aqp4_scale = zeros(N,1);
max_abs_Sa = zeros(N,1);
w_min = zeros(N,1);
w_max = zeros(N,1);
w_mean = zeros(N,1);
ECS_clear_pct = zeros(N,1);
VenOut = zeros(N,1);
VenOut_pct = zeros(N,1);
PvEff_pct = zeros(N,1);
net_water_PaEa = zeros(N,1);
cum_EvPv = zeros(N,1);

for k = 1:N
    r = results{k};
    s = r.aging;
    m = r.metrics;

    case_name(k) = string(s.name);
    group_name(k) = string(s.group);
    epsilon_ratio(k) = s.epsilon_ratio;
    eta_outer(k) = s.eta_outer;
    aqp4_scale(k) = s.aqp4_scale;

    Sa = [r.flux.S_a].';
    max_abs_Sa(k) = max(abs(Sa));

    w_min(k) = m.w_min;
    w_max(k) = m.w_max;
    w_mean(k) = m.w_mean;
    ECS_clear_pct(k) = 100*m.ECS_cleared_fraction;
    VenOut(k) = m.tracer_venous_output;
    VenOut_pct(k) = 100*m.venous_output_fraction;
    PvEff_pct(k) = 100*m.Pv_out_efficiency;
    net_water_PaEa(k) = m.net_water_PaEa;
    cum_EvPv(k) = m.cum_tracer_EvPv;
end

summary_table = table(case_name, group_name, epsilon_ratio, ...
    eta_outer, aqp4_scale, max_abs_Sa, w_min, w_max, w_mean, ...
    ECS_clear_pct, VenOut, VenOut_pct, PvEff_pct, ...
    net_water_PaEa, cum_EvPv);

disp(summary_table);

writetable(summary_table, 'aging_effect_summary.csv');
save('aging_effect_results.mat', 'results', 'specs', ...
    'summary_table', 'SR_scale_young');

plot_aging_results(results, summary_table);
