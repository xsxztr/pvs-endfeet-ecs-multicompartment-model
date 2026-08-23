function p = params_default()

% ------------------------------------------------------------
% Geometry and time
% ------------------------------------------------------------
p.R_v0 = 10.0;      % um, arterial vessel radius
p.R_o0 = 12.0;      % um, outer arterial PVS radius
p.Lseg = 100.0;     % um, segment length
p.eta_outer = 0.2;  % outer PVS wall motion factor

p.radius_pulse_fraction = 0.05;
p.pulse_period = 120.0;      % s
p.t_end = 6000.0;             % s

% ------------------------------------------------------------
% Reference arterial PVS volume
% ------------------------------------------------------------
p.Vref_Pa = pi * p.Lseg * (p.R_o0^2 - p.R_v0^2);
p.Vgeom0_Pa = p.Vref_Pa;

% ------------------------------------------------------------
% Reference volumes
% Use V0 = arterial PVS reference volume
% ECS ratio Ea:Em:Ev = 1:4:1
% ------------------------------------------------------------
V0 = p.Vref_Pa;

p.Vref_A  = 0.6 * V0;     % arterial endfoot
p.Vref_Ea = 2.0 * V0;     % arterial-side ECS
p.Vref_Em = 4.0 * V0;     % middle ECS buffer
p.Vref_Ev = 2.0 * V0;     % venous-side ECS
p.Vref_Pv = 1.5 * V0;     % venous PVS

% ------------------------------------------------------------
% Reference pressures
% ------------------------------------------------------------
p.P_Pa0 = 0.0;
p.P_A0  = 0.0;
p.P_Ea0 = 0.0;
p.P_Em0 = 0.0;
p.P_Ev0 = 0.0;
p.P_Pv0 = 0.0;

p.P_soma = 0.0;
p.P_Pa_out = 0.0;
p.P_Pv_out = -5.0;    % venous side lower pressure to favor drainage

% ------------------------------------------------------------
% Effective stiffness and compliance
% C = Vref / K
% ------------------------------------------------------------
p.K_Pa = 1000.0;   % Pa
p.K_A  = 1000.0;   % Pa
p.K_Ea = 500.0;    % Pa
p.K_Em = 500.0;    % Pa
p.K_Ev = 500.0;    % Pa
p.K_Pv = 1000.0;   % Pa

p.C_Pa = p.Vref_Pa / p.K_Pa;
p.C_A  = p.Vref_A  / p.K_A;
p.C_Ea = p.Vref_Ea / p.K_Ea;
p.C_Em = p.Vref_Em / p.K_Em;
p.C_Ev = p.Vref_Ev / p.K_Ev;
p.C_Pv = p.Vref_Pv / p.K_Pv;

% ------------------------------------------------------------
% Hydraulic conductances
% Units: um^3/(Pa*s)
% ------------------------------------------------------------
p.G_gap_a0 = 1.0;     % arterial PVS-Ea gap conductance
p.L_AQP4_a = 0.05;    % arterial PVS-endfoot water conductance
p.L_AE_a   = 0.01;%0.05;    % endfoot-Ea conductance
p.G_AS     = 0.05;    % endfoot-soma/process drainage

p.G_EaEm = 10;       % ECS chain conductance
p.G_EmEv = 10;
p.G_EvPv = 5;       % venous drainage from Ev to venous PVS

p.G_Pa_out = 0.0;     % arterial PVS external connection
p.G_Pv_out = 50.0;     % venous PVS outlet

% ------------------------------------------------------------
% Gap dynamics
% ------------------------------------------------------------
p.w0 = 1.0;
p.w_min = 0.2;
p.w_max = 2.0;
p.tau_gap = 1.0;

% Forward-phase opening and swelling closure
p.gap_SR_gain = 0.3;
p.gap_swelling_gain = 10.0;

% SR normalization. If empty, compute from baseline in code.
p.SR_scale = [];

% ------------------------------------------------------------
% Osmotic pressure
% Units: Pa
% ------------------------------------------------------------
p.osmotic_pressure = 0.0;   % no osmotic baseline

% ------------------------------------------------------------
% Tracer transport coefficients
% Units approximately um^3/s for lumped exchange
% ------------------------------------------------------------
p.D_PaEa = 0.0;    % gap diffusion; can increase later
p.D_EaEm = 1.;%0.5;
p.D_EmEv = 1.;%0.5;
p.D_EvPv = 0.5;%0.2;

% For large extracellular tracers, no direct endfoot tracer pathway
p.D_PaA = 0.0;
p.D_AEa = 0.0;

% Clearance / degradation
p.k_Ea = 0.0;
p.k_Em = 0.0;
p.k_Ev = 0.0;

% External tracer reservoir concentrations
%p.cPa_out = 1.0;   % for CSF influx protocol, upstream CSF tracer
p.cPa_out = 0.0;
p.cPv_out = 0.0;   % venous downstream tracer-free sink

end