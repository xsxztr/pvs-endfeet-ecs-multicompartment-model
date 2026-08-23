function p = set_SR_scale(p, pulse_shape)

tt = linspace(0, p.pulse_period, 5000);
SR = zeros(size(tt));

cfg_tmp.pulse_shape = pulse_shape;

for i = 1:numel(tt)
    geom = pvs_geometry_source(tt(i), p, cfg_tmp);
    SR(i) = geom.S_R;
end

p.SR_scale = max(abs(SR)) + eps;

end