function m = compute_metrics_extended(t, y, flux, p, cfg)
 
% Water fluxes
Q_PaEa = [flux.Q_PaEa].';
Q_EvPv = [flux.Q_EvPv].';
Q_Pv_out = [flux.Q_Pv_out].';

Q_EaEm = [flux.Q_EaEm].';
Q_EmEv = [flux.Q_EmEv].';

Q_PaA = [flux.Q_PaA].';

% Volumes
VPa = [flux.VPa].';
VEa = [flux.VEa].';
VEm = [flux.VEm].';
VEv = [flux.VEv].';
VPv = [flux.VPv].';

% Masses
MPa = y(:,8);
MEa = y(:,9);
MEm = y(:,10);
MEv = y(:,11);
MPv = y(:,12);

% Concentrations
cPa = MPa ./ VPa;
cEa = MEa ./ VEa;
cEm = MEm ./ VEm;
cEv = MEv ./ VEv;
cPv = MPv ./ VPv;

% Water metrics: arterial PVS -> Ea
m.forward_water_PaEa = trapz(t, max(Q_PaEa, 0));
m.backward_water_EaPa = trapz(t, max(-Q_PaEa, 0));
m.net_water_PaEa = trapz(t, Q_PaEa);
m.net_water_PaA = trapz(t, Q_PaA);
m.mean_Q_PaEa = trapz(t, Q_PaEa) / (t(end) - t(1));

m.mean_Q_EvPv = trapz(t, Q_EvPv) / (t(end) - t(1));

m.max_Q_PaEa = max(Q_PaEa);
m.max_Q_PaA = max(Q_PaA);

m.forward_water_EaEm = trapz(t, max(Q_EaEm,0));
m.forward_water_EmEv = trapz(t, max(Q_EmEv,0));
m.forward_water_EvPv = trapz(t, max(Q_EvPv,0));
m.forward_water_PvOut = trapz(t, max(Q_Pv_out,0));

% Venous drainage water
m.forward_water_EvPv = trapz(t, max(Q_EvPv,0));
m.net_water_EvPv = trapz(t, Q_EvPv);
m.venous_out_water = trapz(t, max(Q_Pv_out,0));

% Tracer-relevant arterial flux
m.tracer_forward_Pa_to_Ea = trapz(t, max(Q_PaEa,0).*cPa);
m.tracer_backward_Ea_to_Pa = trapz(t, max(-Q_PaEa,0).*cEa);
m.tracer_net_PaEa_adv = m.tracer_forward_Pa_to_Ea - m.tracer_backward_Ea_to_Pa;

% Tracer output through venous PVS
J_Pv_out = zeros(size(t));
for k = 1:numel(t)
    J_Pv_out(k) = upwind_tracer_flux(flux(k).Q_Pv_out, cPv(k), p.cPv_out);
end
m.tracer_venous_output = trapz(t, max(J_Pv_out,0));

J_Pv_out_pos = max(J_Pv_out, 0);




% Total ECS tracer mass
MEtot = MEa + MEm + MEv;
Mtot = MPa + MEa + MEm + MEv + MPv;


% Cumulative venous output
Ov_cum = cumtrapz(t, J_Pv_out_pos);
% Normalize by initial ECS tracer mass
m.Ov_norm = Ov_cum / MEtot(1);

m.MEa_end = MEa(end);
m.MEm_end = MEm(end);
m.MEv_end = MEv(end);
m.MEtot_end = MEtot(end);
m.MPa_end = MPa(end);
m.MPv_end = MPv(end);

m.MEtot_initial = MEtot(1);
m.MEtot_change = MEtot(end) - MEtot(1);

% Clearance metric if initial ECS mass > 0
if MEtot(1) > 0
    m.ECS_remaining_fraction = MEtot(end) / MEtot(1);
    m.ECS_cleared_fraction = 1 - m.ECS_remaining_fraction;
else
    m.ECS_remaining_fraction = NaN;
    m.ECS_cleared_fraction = NaN;
end

% Gap diagnostics
w_eff = [flux.w_eff].';
endfoot_norm = [flux.endfoot_norm].';

m.w_min = min(w_eff);
m.w_max = max(w_eff);
m.w_mean = mean(w_eff);

m.endfoot_norm_min = min(endfoot_norm);
m.endfoot_norm_max = max(endfoot_norm);
m.endfoot_norm_mean = mean(endfoot_norm);

% Wave
wave = [flux.wave].';
m.wave_auc = trapz(t, max(wave,0));


m.Mtot_initial = Mtot(1);
m.Mtot_end = Mtot(end);
m.Mtot_loss = Mtot(1) - Mtot(end);


J_Pa_out = zeros(size(t));
J_Pv_out = zeros(size(t));

for k = 1:numel(t)
    J_Pa_out(k) = upwind_tracer_flux(flux(k).Q_Pa_out, cPa(k), cfg.cPa_out);
    J_Pv_out(k) = upwind_tracer_flux(flux(k).Q_Pv_out, cPv(k), cfg.cPv_out);
end

m.tracer_arterial_output = trapz(t, max(J_Pa_out,0));
m.tracer_venous_output = trapz(t, max(J_Pv_out,0));
m.tracer_total_output = m.tracer_arterial_output + m.tracer_venous_output;

m.arterial_output_fraction = m.tracer_arterial_output / MEtot(1);
m.venous_output_fraction = m.tracer_venous_output / MEtot(1);


m.PVS_stored_end = MPa(end) + MPv(end);
m.PVS_stored_fraction = m.PVS_stored_end / MEtot(1);

J_PaEa = zeros(size(t));
J_EaEm = zeros(size(t));
J_EmEv = zeros(size(t));
J_EvPv = zeros(size(t));

for k = 1:numel(t)
    J_PaEa(k) = upwind_tracer_flux(flux(k).Q_PaEa, cPa(k), cEa(k)) ...
              + p.D_PaEa * (cPa(k) - cEa(k));

    J_EaEm(k) = upwind_tracer_flux(flux(k).Q_EaEm, cEa(k), cEm(k)) ...
              + p.D_EaEm * (cEa(k) - cEm(k));

    J_EmEv(k) = upwind_tracer_flux(flux(k).Q_EmEv, cEm(k), cEv(k)) ...
              + p.D_EmEv * (cEm(k) - cEv(k));

    J_EvPv(k) = upwind_tracer_flux(flux(k).Q_EvPv, cEv(k), cPv(k)) ...
              + p.D_EvPv * (cEv(k) - cPv(k));
end


 

m.cEa_end = cEa(end);
m.cEm_end = cEm(end);
m.cEv_end = cEv(end);
m.cPv_end = cPv(end);


m.cum_tracer_PaEa = trapz(t, J_PaEa);
m.cum_tracer_EaEm = trapz(t, J_EaEm);
m.cum_tracer_EmEv = trapz(t, J_EmEv);
m.cum_tracer_EvPv = trapz(t, J_EvPv);

Msys = MPa + MEa + MEm + MEv + MPv;
m.Msys_initial = Msys(1);
m.Msys_end = Msys(end);
m.Msys_loss = Msys(1) - Msys(end);

m.total_output = m.tracer_arterial_output + m.tracer_venous_output;
m.mass_balance_error = m.Msys_loss - m.total_output;
m.Pv_out_efficiency = m.tracer_venous_output / max(m.MPv_end + m.tracer_venous_output, eps);

end