clear; clc; close all;

p = params_default();

% ------------------------------------------------------------
% AQP4 regulation test
% ------------------------------------------------------------
p.t_end = 6000.0;

% Important: turn on osmotic feedback.
% If this remains zero, changing AQP4 may have only a weak effect.
p.osmotic_pressure = 1.0;    % start with 1.0; later test 2, 5, 10 if needed

alpha_list = [1.0, 0.5, 0.1, 0.0];

cases = {};

for ia = 1:numel(alpha_list)

    alpha = alpha_list(ia);

    base = struct();
    base.aqp4_scale = alpha;
    base.osmotic_case = 'endfoot_high';
    base.tracer_protocol = 'ecs_clearance_uniform';

    % case_name = sprintf('asym_dynamic_aqp4_%g_endfoot_high', alpha);
    % 
    % cases{end+1} = set_case(base, case_name, 'asymmetric', true);

    case_name = sprintf('sym_dynamic_aqp4_%g_endfoot_high', alpha);

    cases{end+1} = set_case(base, case_name, 'symmetric', true);


end

% ------------------------------------------------------------
% Run
% ------------------------------------------------------------
results = cell(size(cases));

%fprintf('\nAQP4 sensitivity sweep: dynamic asymmetric waveform\n\n');
fprintf('\nAQP4 sensitivity sweep: dynamic symmetric waveform\n\n');
for k = 1:numel(cases)

    cfg = cases{k};

    p_case = set_SR_scale(p, cfg.pulse_shape);

    fprintf('Running %s\n', cfg.name);

    results{k} = run_case(p_case, cfg);

    m = results{k}.metrics;

    fprintf('%-38s aqp4=%g, ECSclear=%.4f, VenOut=%.4g (%.3g%%), PvEff=%.3f%%\n', ...
        cfg.name, ...
        cfg.aqp4_scale, ...
        m.ECS_cleared_fraction, ...
        m.tracer_venous_output, ...
        100*m.venous_output_fraction, ...
        100*m.Pv_out_efficiency);

    fprintf('%-38s w=[%.4g, %.4g], mean=%.4g, endfoot_norm=[%+.3g,%+.3g], mean=%+.3g\n', ...
        cfg.name, ...
        m.w_min, m.w_max, m.w_mean, ...
        m.endfoot_norm_min, m.endfoot_norm_max, m.endfoot_norm_mean);

    fprintf('%-38s MEa=%g, MEm=%g, MEv=%g, MPv=%g, VenOut=%g\n', ...
        cfg.name, ...
        m.MEa_end, m.MEm_end, m.MEv_end, m.MPv_end, m.tracer_venous_output);

    fprintf('%-38s Jcum: PaEa=%.4g, EaEm=%.4g, EmEv=%.4g, EvPv=%.4g\n\n', ...
        cfg.name, ...
        m.cum_tracer_PaEa, ...
        m.cum_tracer_EaEm, ...
        m.cum_tracer_EmEv, ...
        m.cum_tracer_EvPv);
end

% ------------------------------------------------------------
% Plot
% ------------------------------------------------------------
plot_results_extended(results);

% plot_compare(results, { ...
%     'asym_dynamic_aqp4_1_endfoot_high', ...
%     'asym_dynamic_aqp4_0.5_endfoot_high', ...
%     'asym_dynamic_aqp4_0.1_endfoot_high', ...
%     'asym_dynamic_aqp4_0_endfoot_high'});

plot_compare(results, { ...
    'sym_dynamic_aqp4_1_endfoot_high', ...
    'sym_dynamic_aqp4_0.5_endfoot_high', ...
    'sym_dynamic_aqp4_0.1_endfoot_high', ...
    'sym_dynamic_aqp4_0_endfoot_high'});