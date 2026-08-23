clear; clc;close all;

p = params_default();

% ------------------------------------------------------------
% Cases
% ------------------------------------------------------------
cases = {};

base = struct();
base.aqp4_scale = 1.0;
base.osmotic_case = 'none';
%base.tracer_protocol = 'csf_influx';
base.tracer_protocol='ecs_clearance_uniform';

cases{end+1} = set_case(base, 'cardiac_fixed_no_osm', 'cardiac', false);
cases{end+1} = set_case(base, 'sym_fixed_no_osm', 'symmetric', false);
cases{end+1} = set_case(base, 'asym_fixed_no_osm', 'asymmetric', false);

cases{end+1} = set_case(base, 'sym_dynamic_no_osm', 'symmetric', true);
cases{end+1} = set_case(base, 'asym_dynamic_no_osm', 'asymmetric', true);

% ------------------------------------------------------------
% Run
% ------------------------------------------------------------
results = cell(size(cases));

fprintf('\nExtended arterial-ECS-chain-venous model\n\n');

for k = 1:numel(cases)
    cfg = cases{k};
    

switch lower(cfg.pulse_shape)

    case 'cardiac'
        p.pulse_period = 0.2;

    case {'symmetric','asymmetric'}
        p.pulse_period = 10.0;
        p.radius_pulse_fraction = 0.05;
    otherwise
        error('Unknown waveform: %s',cfg.pulse_shape);
end


    p_case = set_SR_scale(p, cfg.pulse_shape);
    % Optional: compute SR scale once per case or set a fixed scale.
    results{k} = run_case(p_case, cfg);
    m = results{k}.metrics;

    fprintf('%-30s meanQ=%+9.4g, forward=%9.4g, backward=%9.4g, net=%+9.4g, MEtotEnd=%8.4g, VenOut=%8.4g, waveAUC=%8.4g\n', ...
        cfg.name, ...
        m.mean_Q_PaEa, ...
        m.forward_water_PaEa, ...
        m.backward_water_EaPa, ...
        m.net_water_PaEa, ...
        m.MEtot_end, ...
        m.tracer_venous_output, ...
        m.wave_auc);

    fprintf('%-30s w=[%.4g, %.4g], mean=%.4g, endfoot_norm=[%+.3g,%+.3g], mean=%+.3g\n', ...
        cfg.name, ...
        m.w_min, m.w_max, m.w_mean, ...
        m.endfoot_norm_min, m.endfoot_norm_max, m.endfoot_norm_mean);

    fprintf('%-30s MEa=%g, MEm=%g, MEv=%g, MPv=%g, VenOut=%g\n', ...
    cfg.name, m.MEa_end, m.MEm_end, m.MEv_end, m.MPv_end, m.tracer_venous_output);

    fprintf('%-30s ECSrem=%.4f, ECSclear=%.4f, VenOut=%.4g (%.3g%%), ArtOut=%.4g (%.3g%%)\n', ...
    cfg.name, ...
    m.ECS_remaining_fraction, ...
    m.ECS_cleared_fraction, ...
    m.tracer_venous_output, ...
    100*m.venous_output_fraction, ...
    m.tracer_arterial_output, ...
    100*m.arterial_output_fraction);

    fprintf('%-30s Jcum: PaEa=%.4g, EaEm=%.4g, EmEv=%.4g, EvPv=%.4g\n', ...
    cfg.name, ...
    m.cum_tracer_PaEa, ...
    m.cum_tracer_EaEm, ...
    m.cum_tracer_EmEv, ...
    m.cum_tracer_EvPv);

    fprintf('%-30s PvEff=%.3f%%, MPv=%.4g, VenOut=%.4g\n', ...
    cfg.name, ...
    100*m.Pv_out_efficiency, ...
    m.MPv_end, ...
    m.tracer_venous_output);


    fprintf('%-30s max_Q_PaEa=%.4g, max_Q_PaA=%.4g,net_water_PaEa = %.4g, net_water_PaA= %.4g\n', ...
    cfg.name, ...
    m.max_Q_PaEa, m.max_Q_PaA,m.net_water_PaEa,m.net_water_PaA);
end

% Plot first dynamic comparison etc.
plot_results_extended(results);

%plot_compare(results,  {'cardiac_fixed_no_osm','sym_fixed_no_osm','asym_fixed_no_osm'} );

%plot_compare(results,  {'cardiac_fixed_no_osm','sym_fixed_no_osm','asym_fixed_no_osm','sym_dynamic_no_osm','asym_dynamic_no_osm'} );
% exportgraphics(gcf, 'CardicvsSym_fixgap_flux.eps', 'ContentType', 'vector');


plot_pressure_distributions(results);