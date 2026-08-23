clear; clc; close all;

% ============================================================
% Memory-light aging-associated impairment study
%
% The code runs one case at a time, extracts only summary metrics,
% and discards the full solution before moving to the next case.
% Only three representative combined-aging trajectories are retained,
% and they are downsampled before being saved.
% ============================================================

p0 = params_default();

p0.t_end = 6000.0;
p0.pulse_period = 10.0;
p0.osmotic_pressure = 0.0;

pulse_shape = 'symmetric';
dynamic_gap = true;

epsilon_young = 1.0;
eta_young = 0.20;
alpha_young = 1.0;

% ------------------------------------------------------------
% Young-reference normalization
% ------------------------------------------------------------
p_ref = p0;
p_ref.eta_outer = eta_young;
p_ref = set_SR_scale(p_ref, pulse_shape);
SR_scale_young = p_ref.SR_scale;

fprintf('Young-reference SR scale = %.6g\n', SR_scale_young);

% ------------------------------------------------------------
% Case definitions
% ------------------------------------------------------------
specs = struct('name', {}, 'group', {}, 'xvalue', {}, ...
    'epsilon_ratio', {}, 'eta_outer', {}, 'aqp4_scale', {});

n = 0;

% A. Vessel-motion amplitude sweep
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

% B. Effective PVS boundary-coupling sweep
eta_values = [0.20, 0.50, 0.75];
eta_names = {'eta_0p20', 'eta_0p50', 'eta_0p70'};

for i = 1:numel(eta_values)
    n = n + 1;
    specs(n).name = eta_names{i};
    specs(n).group = 'eta';
    specs(n).xvalue = eta_values(i);
    specs(n).epsilon_ratio = epsilon_young;
    specs(n).eta_outer = eta_values(i);
    specs(n).aqp4_scale = alpha_young;
end

% C. Effective perivascular AQP4 sweep
alpha_values = [1.00, 0.50, 0.10];
alpha_names = {'alpha_1p00', 'alpha_0p50', 'alpha_0p10'};

for i = 1:numel(alpha_values)
    n = n + 1;
    specs(n).name = alpha_names{i};
    specs(n).group = 'alpha';
    specs(n).xvalue = alpha_values(i);
    specs(n).epsilon_ratio = epsilon_young;
    specs(n).eta_outer = eta_young;
    specs(n).aqp4_scale = alpha_values(i);
end

% D. Representative combined-aging phenotypes
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

% ------------------------------------------------------------
% Preallocate summary arrays only
% ------------------------------------------------------------
N = numel(specs);

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

% Keep only downsampled histories for these representative cases.
keep_history_names = {'young', 'moderate_aging', 'advanced_aging'};
max_history_points = 3000;

history = struct('name', {}, 't', {}, 'ME_norm', {}, ...
    'Ov_norm', {}, 'w', {}, 'Sa', {});

fprintf('\nAging-associated symmetric slow-vasomotion study\n\n');

% ------------------------------------------------------------
% Run one case at a time
% ------------------------------------------------------------
for k = 1:N
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

    % Full result exists only for the current case.
    r = run_case(p_case, cfg);
    m = r.metrics;
    Sa = [r.flux.S_a].';

    % Store scalar summary values.
    case_name(k) = string(s.name);
    group_name(k) = string(s.group);
    epsilon_ratio(k) = s.epsilon_ratio;
    eta_outer(k) = s.eta_outer;
    aqp4_scale(k) = s.aqp4_scale;
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

    fprintf(['  ECSclear=%.4f, VenOut=%.4g (%.3g%%), PvEff=%.3f%%, ', ...
             'w=[%.4g, %.4g], mean=%.4g, max|S_a|=%.4g\n'], ...
        m.ECS_cleared_fraction, m.tracer_venous_output, ...
        100*m.venous_output_fraction, 100*m.Pv_out_efficiency, ...
        m.w_min, m.w_max, m.w_mean, max(abs(Sa)));

    % Retain only compact, downsampled trajectories for representative cases.
    if any(strcmp(s.name, keep_history_names))
        nt = numel(r.t);
        nkeep = min(nt, max_history_points);
        idx = unique(round(linspace(1, nt, nkeep)));

        h.name = s.name;
        h.t = r.t(idx);

        ME = r.y(:,9) + r.y(:,10) + r.y(:,11);
        h.ME_norm = ME(idx) / ME(1);

        h.Ov_norm = m.Ov_norm(idx);
        h.w = r.y(idx,7);
        h.Sa = Sa(idx);

        history(end+1) = h; %#ok<SAGROW>
    end

    % Explicitly release the large current-case arrays.
    clear r m Sa p_case cfg base h idx ME
end

% ------------------------------------------------------------
% Save compact outputs only
% ------------------------------------------------------------
summary_table = table(case_name, group_name, epsilon_ratio, ...
    eta_outer, aqp4_scale, max_abs_Sa, w_min, w_max, w_mean, ...
    ECS_clear_pct, VenOut, VenOut_pct, PvEff_pct, ...
    net_water_PaEa, cum_EvPv);

disp(summary_table);

writetable(summary_table, 'aging_effect_summary.csv');

% This MAT file is small: scalar table + three downsampled histories.
save('aging_effect_compact.mat', 'summary_table', 'history', ...
    'specs', 'SR_scale_young');

plot_aging_results_light(summary_table, history);
