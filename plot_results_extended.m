function plot_results_extended(results)

% if ~exist(outdir, 'dir')
%     mkdir(outdir);
% end


figure; hold on;

for k = 1:3
    r = results{k};
    t = r.t;
    flux = r.flux;

    wave = [flux.wave].';

    % S_a = [flux.S_a].';
    % subplot(2,1,1)
    plot(t,wave, 'LineWidth', 1.5, 'DisplayName', r.cfg.name);
    xlabel('Time (s)');
    ylabel('$f(t)$', 'Interpreter', 'latex');
    xlim([0,10])
    legend('Location','best');
    title('Vascular waveform');
    grid on;
    box on;
    hold on;

    % subplot(2,1,2)
    % plot(t,S_a, 'LineWidth', 1.5, 'DisplayName', r.cfg.name);
    % xlabel('Time (s)');
    % ylabel('$S_a$', 'Interpreter', 'latex');
    % xlim([0,10])
    % legend('Location','best');
    % title('Vascular compression source');
    % grid on;
    % box on;
    % hold on;

end

 
figure; hold on;

for k = 1:numel(results)
    r = results{k};
    t = r.t;
    y = r.y;
    flux = r.flux;

    VEa = [flux.VEa].';
    VEm = [flux.VEm].';
    VEv = [flux.VEv].';

    MEa = y(:,9);
    MEm = y(:,10);
    MEv = y(:,11);

    MEtot = MEa + MEm + MEv;

    plot(t, MEtot/MEtot(1), 'LineWidth', 1.5, 'DisplayName', r.cfg.name);
end

xlabel('Time (s)');
ylabel('Total ECS tracer mass ratio MEtot/Metot(0)');
legend('Location','best');
%title('Total ECS tracer mass ');
grid on;


figure; hold on 
for k = 1:numel(results)
    r = results{k};
    t = r.t;
    m = r.metrics;

    Ov_norm = m.Ov_norm(:);

    plot(t, Ov_norm, ...
        'LineWidth', 1.2, ...
        'DisplayName', strrep(r.cfg.name, '_', '\_'));
end

xlabel('Time (s)');
ylabel('$O_v(t)/M_E(0)$', 'Interpreter', 'latex');
legend('Location','best');
title('Cumulative venous output over time');
grid on;
box on;

figure; hold on;

for k = 1:numel(results)
    r = results{k};
    t = r.t;
    flux = r.flux;

    Q = [flux.Q_PaEa].';

    plot(t, Q, 'LineWidth', 1.2, 'DisplayName', r.cfg.name);
end

xlabel('Time (s)');
ylabel('Q_{P_aE_a} (\mum^3/s)');
legend('Location','best');
title('Arterial PVS to ECS water flux');
grid on;

figure; hold on;

for k = 1:numel(results)
    r = results{k};
    t = r.t;
    flux = r.flux;

    w = [flux.w_eff].';

    plot(t, w, 'LineWidth', 1.2, 'DisplayName', r.cfg.name);
end

xlabel('Time (s)');
ylabel('w_a(t)');
legend('Location','best');
title('Dynamic arterial gap');
grid on;

figure; hold on;

for k = 1:numel(results)
    r = results{k};
    t = r.t;
    y = r.y;
    flux = r.flux;

    cEa = y(:,9)  ./ [flux.VEa].';
    cEm = y(:,10) ./ [flux.VEm].';
    cEv = y(:,11) ./ [flux.VEv].';

    plot(t, cEa, '--', 'LineWidth', 1.0, 'DisplayName', [r.cfg.name ' cEa']);
    plot(t, cEm, '-',  'LineWidth', 1.0, 'DisplayName', [r.cfg.name ' cEm']);
    plot(t, cEv, ':',  'LineWidth', 1.0, 'DisplayName', [r.cfg.name ' cEv']);
end

xlabel('Time (s)');
ylabel('ECS concentrations');
legend('Location','best');
title('Spatial ECS concentrations');
grid on;

end



