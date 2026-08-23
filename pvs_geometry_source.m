function g = pvs_geometry_source(t, p, cfg)
%PVS_GEOMETRY_SOURCE Geometry-based PVS compression source.
%
% Vgeom(t) = pi * Lseg * (Ro(t)^2 - Rv(t)^2)
% S_R(t)  = - dVgeom/dt
%
% Units:
%   Rv, Ro: um
%   Vgeom: um^3
%   S_R: um^3/s
%
% Positive S_R means PVS is compressed and pressure tends to increase.

[wave, dwave_dt] = vessel_waveform(t, p, cfg.pulse_shape);

if isfield(cfg, 'wave_scale')
    wave = cfg.wave_scale * wave;
    dwave_dt = cfg.wave_scale * dwave_dt;
end

Rv = p.R_v0 * (1.0 + p.radius_pulse_fraction * wave);
dRv_dt = p.R_v0 * p.radius_pulse_fraction * dwave_dt;

Ro = p.R_o0 + p.eta_outer * (Rv - p.R_v0);
dRo_dt = p.eta_outer * dRv_dt;

Vgeom = pi * p.Lseg * (Ro^2 - Rv^2);
dVgeom_dt = 2.0 * pi * p.Lseg * (Ro * dRo_dt - Rv * dRv_dt);

S_R = -dVgeom_dt;

g.wave = wave;
g.dwave_dt = dwave_dt;
g.Rv = Rv;
g.Ro = Ro;
g.dRv_dt = dRv_dt;
g.dRo_dt = dRo_dt;
g.Vgeom = Vgeom;
g.dVgeom_dt = dVgeom_dt;
g.S_R = S_R;
end