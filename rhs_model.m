function dydt = rhs_model(t, y, p, cfg)

% ------------------------------------------------------------
% Unpack state
% ------------------------------------------------------------
pPa = y(1);
pA  = y(2);
pEa = y(3);
pEm = y(4);
pEv = y(5);
pPv = y(6);
wa  = y(7);

MPa = y(8);
MEa = y(9);
MEm = y(10);
MEv = y(11);
MPv = y(12);

% ------------------------------------------------------------
% Compute fluxes
% ------------------------------------------------------------
f = compute_fluxes(t, y, p, cfg);

% ------------------------------------------------------------
% Pressure dynamics
% ------------------------------------------------------------
dpPa = (f.S_a - f.Q_PaEa - f.Q_PaA - f.Q_Pa_out) / p.C_Pa;

dpA = (f.Q_PaA - f.Q_AEa - f.Q_AS) / p.C_A;

dpEa = (f.Q_PaEa + f.Q_AEa - f.Q_EaEm) / p.C_Ea;

dpEm = (f.Q_EaEm - f.Q_EmEv) / p.C_Em;

dpEv = (f.Q_EmEv - f.Q_EvPv) / p.C_Ev;

dpPv = (f.Q_EvPv - f.Q_Pv_out) / p.C_Pv;

% ------------------------------------------------------------
% Gap dynamics
% ------------------------------------------------------------
if cfg.dynamic_gap
    dwa = (f.w_star - wa) / p.tau_gap;
else
    dwa = 0.0;
end

% ------------------------------------------------------------
% Concentrations using instantaneous volumes
% ------------------------------------------------------------
cPa = MPa / f.VPa;
cEa = MEa / f.VEa;
cEm = MEm / f.VEm;
cEv = MEv / f.VEv;
cPv = MPv / f.VPv;

% ------------------------------------------------------------
% Tracer fluxes
% ------------------------------------------------------------
J_PaEa = upwind_tracer_flux(f.Q_PaEa, cPa, cEa) ...
       + p.D_PaEa * (cPa - cEa);

J_EaEm = upwind_tracer_flux(f.Q_EaEm, cEa, cEm) ...
       + p.D_EaEm * (cEa - cEm);

J_EmEv = upwind_tracer_flux(f.Q_EmEv, cEm, cEv) ...
       + p.D_EmEv * (cEm - cEv);

J_EvPv = upwind_tracer_flux(f.Q_EvPv, cEv, cPv) ...
       + p.D_EvPv * (cEv - cPv);

% Arterial PVS boundary tracer flux.
% Upwind with upstream CSF reservoir concentration p.cPa_out.
J_Pa_out = upwind_tracer_flux(f.Q_Pa_out, cPa,cfg.cPa_out);

% Venous PVS outlet to tracer-free reservoir
J_Pv_out = upwind_tracer_flux(f.Q_Pv_out, cPv,cfg.cPv_out);

% ------------------------------------------------------------
% Tracer mass dynamics
% ------------------------------------------------------------
dMPa = -J_PaEa - J_Pa_out;

dMEa =  J_PaEa - J_EaEm - p.k_Ea * MEa;

dMEm =  J_EaEm - J_EmEv - p.k_Em * MEm;

dMEv =  J_EmEv - J_EvPv - p.k_Ev * MEv;

dMPv =  J_EvPv - J_Pv_out;

% ------------------------------------------------------------
% Pack
% ------------------------------------------------------------
dydt = [
    dpPa;
    dpA;
    dpEa;
    dpEm;
    dpEv;
    dpPv;
    dwa;
    dMPa;
    dMEa;
    dMEm;
    dMEv;
    dMPv
];

end