function y0 = initial_condition_extended(p, cfg)

% Pressures and gap
pPa0 = p.P_Pa0;
pA0  = p.P_A0;
pEa0 = p.P_Ea0;
pEm0 = p.P_Em0;
pEv0 = p.P_Ev0;
pPv0 = p.P_Pv0;
wa0  = p.w0;

% Initial concentrations
switch lower(cfg.tracer_protocol)

    case 'csf_influx'
        cPa0 = 1.0;
        cEa0 = 0.0;
        cEm0 = 0.0;
        cEv0 = 0.0;
        cPv0 = 0.0;
        cfg.cPa_out = 1.0;   % tracer-rich CSF reservoir
        cfg.cPv_out = 0.0;   % venous sink

    case 'ecs_clearance_middle'
        cPa0 = 0.0;
        cEa0 = 0.0;
        cEm0 = 1.0;
        cEv0 = 0.0;
        cPv0 = 0.0;
  
    case 'ecs_clearance_uniform'
        cPa0 = 0.0;
        cEa0 = 1.0;
        cEm0 = 1.0;
        cEv0 = 1.0;
        cPv0 = 0.0;
    otherwise
        error('Unknown tracer_protocol: %s', cfg.tracer_protocol);
end

% Initial volumes at baseline
MPa0 = cPa0 * p.Vref_Pa;
MEa0 = cEa0 * p.Vref_Ea;
MEm0 = cEm0 * p.Vref_Em;
MEv0 = cEv0 * p.Vref_Ev;
MPv0 = cPv0 * p.Vref_Pv;

y0 = [
    pPa0;
    pA0;
    pEa0;
    pEm0;
    pEv0;
    pPv0;
    wa0;
    MPa0;
    MEa0;
    MEm0;
    MEv0;
    MPv0
];

end