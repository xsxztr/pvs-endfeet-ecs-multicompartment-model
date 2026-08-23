function f = compute_fluxes(t, y, p, cfg)

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

% ------------------------------------------------------------
% Geometry source from arterial vessel
% ------------------------------------------------------------
geom = pvs_geometry_source(t, p, cfg);

S_a = geom.S_R;

% ------------------------------------------------------------
% Volumes
% ------------------------------------------------------------
vol = compute_volumes(t, y, p, cfg, geom);

% ------------------------------------------------------------
% Gap dynamics and arterial gap conductance
% ------------------------------------------------------------
endfoot_norm = vol.endfoot_norm;

% Normalize forward compression source
% if isempty(p.SR_scale)
%     SR_scale = max(abs(S_a), 1e-12);
% else
%     SR_scale = p.SR_scale;
% end
% 
% SR_plus = max(S_a, 0.0);

%stretch_open = p.gap_SR_gain * SR_plus / SR_scale;
SR_scale = p.SR_scale;
stretch_open = p.gap_SR_gain * max(S_a,0) / SR_scale;

if cfg.dynamic_gap
    w_star_raw = p.w0 ...
        + stretch_open ...
        - p.gap_swelling_gain * endfoot_norm;

    w_star = min(max(w_star_raw, p.w_min), p.w_max);
    w_eff = min(max(wa, p.w_min), p.w_max);
else
    w_star_raw = p.w0;
    w_star = p.w0;
    w_eff = p.w0;
end

G_gap_a = p.G_gap_a0 * w_eff^3;

% ------------------------------------------------------------
% Osmotic terms
% ------------------------------------------------------------
[deltaPi_PaA, deltaPi_AEa] = osmotic_terms_extended(p, cfg.osmotic_case);

L_AQP4 = p.L_AQP4_a * cfg.aqp4_scale;

% ------------------------------------------------------------
% Water fluxes
% Sign convention:
% Q_ij > 0 means i -> j
% ------------------------------------------------------------

% Arterial PVS to arterial-side ECS through gap
Q_PaEa = G_gap_a * (pPa - pEa);

% Arterial PVS to endfoot through AQP4-rich membrane
Q_PaA = L_AQP4 * ((pPa - pA) - deltaPi_PaA);

% Endfoot to arterial-side ECS
Q_AEa = p.L_AE_a * ((pA - pEa) - deltaPi_AEa);

% Endfoot to soma/process
Q_AS = p.G_AS * (pA - p.P_soma);

% ECS chain
Q_EaEm = p.G_EaEm * (pEa - pEm);
Q_EmEv = p.G_EmEv * (pEm - pEv);

% Venous drainage: Ev -> Pv
Q_EvPv = p.G_EvPv * (pEv - pPv);

% Arterial PVS external outlet/inlet
Q_Pa_out = p.G_Pa_out * (pPa - p.P_Pa_out);

% Venous PVS outlet
Q_Pv_out = p.G_Pv_out * (pPv - p.P_Pv_out);

% ------------------------------------------------------------
% Save fields
% ------------------------------------------------------------
f.S_a = S_a;

f.pPa = pPa;
f.pPv = pPv;
f.pEa = pEa;
f.pEv = pEv;
f.pEm = pEm;


f.Q_PaEa = Q_PaEa;
f.Q_PaA  = Q_PaA;
f.Q_AEa  = Q_AEa;
f.Q_AS   = Q_AS;

f.Q_EaEm = Q_EaEm;
f.Q_EmEv = Q_EmEv;
f.Q_EvPv = Q_EvPv;

f.Q_Pa_out = Q_Pa_out;
f.Q_Pv_out = Q_Pv_out;

f.w_star_raw = w_star_raw;
f.w_star = w_star;
f.w_eff = w_eff;
f.endfoot_norm = endfoot_norm;

f.G_gap_a = G_gap_a;

% Geometry
f.wave = geom.wave;
f.dwave_dt = geom.dwave_dt;
f.Rv = geom.Rv;
f.Ro = geom.Ro;
f.dRv_dt = geom.dRv_dt;
f.dRo_dt = geom.dRo_dt;
f.Vgeom = geom.Vgeom;
f.dVgeom_dt = geom.dVgeom_dt;

% Volumes
f.VPa = vol.VPa;
f.VA  = vol.VA;
f.VEa = vol.VEa;
f.VEm = vol.VEm;
f.VEv = vol.VEv;
f.VPv = vol.VPv;

end