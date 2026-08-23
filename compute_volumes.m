function vol = compute_volumes(t, y, p, cfg, geom)
% Compute instantaneous effective volumes.

pPa = y(1);
pA  = y(2);
pEa = y(3);
pEm = y(4);
pEv = y(5);
pPv = y(6);

% Arterial PVS: geometric volume + pressure-dependent storage
VPa = p.Vref_Pa ...
    + (geom.Vgeom - p.Vgeom0_Pa) ...
    + p.C_Pa * (pPa - p.P_Pa0);

VA = p.Vref_A ...
    + p.C_A * (pA - p.P_A0);

VEa = p.Vref_Ea ...
    + p.C_Ea * (pEa - p.P_Ea0);

VEm = p.Vref_Em ...
    + p.C_Em * (pEm - p.P_Em0);

VEv = p.Vref_Ev ...
    + p.C_Ev * (pEv - p.P_Ev0);

VPv = p.Vref_Pv ...
    + p.C_Pv * (pPv - p.P_Pv0);

% Safety lower bounds
VPa = max(VPa, 0.05 * p.Vref_Pa);
VA  = max(VA,  0.05 * p.Vref_A);
VEa = max(VEa, 0.05 * p.Vref_Ea);
VEm = max(VEm, 0.05 * p.Vref_Em);
VEv = max(VEv, 0.05 * p.Vref_Ev);
VPv = max(VPv, 0.05 * p.Vref_Pv);

vol.VPa = VPa;
vol.VA  = VA;
vol.VEa = VEa;
vol.VEm = VEm;
vol.VEv = VEv;
vol.VPv = VPv;

vol.endfoot_norm = (VA - p.Vref_A) / p.Vref_A;

end