function cfg = set_case(base, name, pulse_shape, dynamic_gap)

cfg = base;
cfg.name = name;
cfg.pulse_shape = pulse_shape;
cfg.dynamic_gap = dynamic_gap;

% ------------------------------------------------------------
% External tracer reservoir concentrations
% ------------------------------------------------------------
switch lower(cfg.tracer_protocol)

    case 'csf_influx'
        % CSF tracer is supplied from the arterial PVS reservoir.
        cfg.cPa_out = 1.0;
        cfg.cPv_out = 0.0;

    case {'ecs_clearance_uniform', 'ecs_clearance_middle'}
        % Clearance protocol: external reservoirs are tracer-free.
        cfg.cPa_out = 0.0;
        cfg.cPv_out = 0.0;

    otherwise
        error('Unknown tracer_protocol: %s', cfg.tracer_protocol);
end

end