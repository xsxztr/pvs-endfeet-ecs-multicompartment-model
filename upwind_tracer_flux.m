function J = upwind_tracer_flux(Q_ij, c_i, c_j)
% Q_ij > 0 means flow from i to j.
% J > 0 means tracer flux from i to j.

Q_plus = max(Q_ij, 0.0);
Q_minus = max(-Q_ij, 0.0);

J = Q_plus * c_i - Q_minus * c_j;

end