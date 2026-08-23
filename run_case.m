function result = run_case(p, cfg)

% Initial conditions
y0 = initial_condition_extended(p, cfg);

tspan = [0, p.t_end];

opts = odeset('RelTol',1e-7,'AbsTol',1e-9);

[t, y] = ode15s(@(t,y) rhs_model(t, y, p, cfg), tspan, y0, opts);

% Recompute fluxes
flux = repmat(compute_fluxes(t(1), y(1,:).', p, cfg), numel(t), 1);

for n = 1:numel(t)
    flux(n) = compute_fluxes(t(n), y(n,:).', p, cfg);
end

metrics = compute_metrics_extended(t, y, flux, p, cfg);

result.t = t;
result.y = y;
result.flux = flux;
result.metrics = metrics;
result.cfg = cfg;
result.p = p;
end