function plot_compare(results, names)

figure;

colors = lines(numel(names));
labels = cell(size(names));

% subplot(3,1,1); hold on; box on;
% for k = 1:numel(names)
%     r = get_result(results, names{k});
%     labels{k} = strrep(r.cfg.name, '_', '\_');
%     plot(r.t, [r.flux.S_a].', 'Color', colors(k,:), 'LineWidth', 1.2);
% end
% ylabel('S_a');
% title(ttl);
% legend(labels, 'Location','best');

%subplot(3,1,2); hold on; box on;
% for k = 1:numel(names)
%     r = get_result(results, names{k});
%     dP = [r.flux.pPa].' - [r.flux.pEa].';
%     plot(r.t, dP, 'Color', colors(k,:), 'LineWidth', 1.2);
% end
% ylabel('p_{Pa} - p_{Ea}');

subplot(2,2,1);
hold on; box on;
for k = 1:numel(names)
    r = get_result(results, names{k});
    plot(r.t, [r.flux.Q_PaEa].', 'Color', colors(k,:), 'LineWidth', 1.2);
end
ylabel('Q_{PaEa}');

xlabel('Time(s)');
xlim([0,600]);

subplot(2,2,2);
hold on; box on;
for k = 1:numel(names)
    r = get_result(results, names{k});
    plot(r.t, [r.flux.Q_EaEm].', 'Color', colors(k,:), 'LineWidth', 1.2);
end
ylabel('Q_{EaEm}');

xlabel('Time(s)');
xlim([0,600]);

subplot(2,2,3);
hold on; box on;
for k = 1:numel(names)
    r = get_result(results, names{k});
    plot(r.t, [r.flux.Q_EmEv].', 'Color', colors(k,:), 'LineWidth', 1.2);
end
ylabel('Q_{EmEv}');

xlabel('Time(s)');
xlim([0,600]);

subplot(2,2,4);
hold on; box on;
for k = 1:numel(names)
    r = get_result(results, names{k});
    plot(r.t, [r.flux.Q_EvPv].', 'Color', colors(k,:), 'LineWidth', 1.2);
end
ylabel('Q_{EvPv}');
xlabel('Time(s)');
xlim([0,600]);

%print(gcf, filename, '-dpng', '-r200');

%% Forward, backward, and net water exchange: P_a <-> E_a

% names = {'cardiac_fixed_no_osm', ...
%          'sym_fixed_no_osm', ...
%          'asym_fixed_no_osm'};
%names = {'cardiac_fixed_no_osm','sym_fixed_no_osm','asym_fixed_no_osm','sym_dynamic_no_osm','asym_dynamic_no_osm'};

 case_labels = {'Cardiac fixed', 'Symmetric fixed', ...
     'Asymmetric fixed', 'Symmetric dynamic',...
     'Asymmetric dynamic'};
%case_labels = names;
Q_forward  = [];
Q_backward = [];
Q_net      = [];

for k = 1:numel(names)
    r = get_result(results, names{k});

    Q_forward  = [Q_forward,  r.metrics.forward_water_PaEa];
    Q_backward = [Q_backward, r.metrics.backward_water_EaPa];
    Q_net      = [Q_net,      r.metrics.net_water_PaEa];
end

xx = categorical(case_labels);
xx = reordercats(xx, case_labels);

figure;

tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% ------------------------------------------------------------
% Panel (a): forward and backward exchange
% ------------------------------------------------------------
nexttile;
Y1 = [Q_forward; Q_backward]';

bar(xx, Y1, 'grouped');

ylabel('Cumulative water exchange');
title('(a) Forward and backward exchange');

legend({'$\int (Q_{P_aE_a})^+ dt$', ...
        '$\int (Q_{P_aE_a})^- dt$'}, ...
        'Interpreter','latex', ...
        'Location','best');

grid on;
box on;

% ------------------------------------------------------------
% Panel (b): net exchange
% ------------------------------------------------------------
nexttile;
bar(xx, Q_net);

ylabel('Net water exchange');
title('(b) Net $P_a \rightarrow E_a$ exchange', 'Interpreter','latex');

grid on;
box on;


%%
% names = {'cardiac_fixed_no_osm', ...
%          'sym_fixed_no_osm', ...
%          'asym_fixed_no_osm'};
% 
% case_labels = {'Cardiac', 'Symmetric', 'Asymmetric'};

MEtot_end = [];
MPa_end   = [];
MPv_end   = [];
Ov_out    = [];
ME0       = [];

for k = 1:numel(names)
    r = get_result(results, names{k});

    MEtot_end = [MEtot_end, r.metrics.MEtot_end];
    MPa_end   = [MPa_end,   r.metrics.MPa_end];
    MPv_end   = [MPv_end,   r.metrics.MPv_end];
    Ov_out    = [Ov_out,    r.metrics.tracer_venous_output];
    ME0       = [ME0,       r.metrics.MEtot_initial];
end

% Normalize by initial ECS tracer mass
Y = [MPa_end; MEtot_end; MPv_end; Ov_out]';
Y = 100 * (Y ./ ME0');   % percent of initial ECS tracer mass

figure;
xx = categorical(case_labels);
xx = reordercats(xx, case_labels);

bar(xx, Y, 'stacked');

ylabel('Fraction of initial ECS tracer mass (%)');
title('Final tracer distribution and venous output');

legend({'Arterial PVS storage $M_{P_a}(T)$', ...
        'Remaining ECS mass $M_E(T)$', ...
        'Venous PVS storage $M_{P_v}(T)$', ...
        'Venous output $O_v(T)$'}, ...
        'Interpreter','latex', ...
        'Location','bestoutside');

grid on;
box on;
%%
% names = {'cardiac_fixed_no_osm', ...
%          'sym_fixed_no_osm', ...
%          'asym_fixed_no_osm'};
% 
% case_labels = {'Cardiac', 'Symmetric', 'Asymmetric'};

cum_tracer_PaEa = [];
cum_tracer_EaEm = [];
cum_tracer_EmEv = [];
cum_tracer_EvPv = [];
ME0 = [];

for k = 1:numel(names)
    r = get_result(results, names{k});

    cum_tracer_PaEa = [cum_tracer_PaEa, r.metrics.cum_tracer_PaEa];
    cum_tracer_EaEm = [cum_tracer_EaEm, r.metrics.cum_tracer_EaEm];
    cum_tracer_EmEv = [cum_tracer_EmEv, r.metrics.cum_tracer_EmEv];
    cum_tracer_EvPv = [cum_tracer_EvPv, r.metrics.cum_tracer_EvPv];

    ME0 = [ME0, r.metrics.MEtot_initial];
end

% Normalize by initial ECS tracer mass, optional but recommended
Y = [cum_tracer_PaEa; ...
     cum_tracer_EaEm; ...
     cum_tracer_EmEv; ...
     cum_tracer_EvPv]';

Y = 100 * (Y ./ ME0');   % percentage of initial ECS tracer mass

figure;
xx = categorical(case_labels);
xx = reordercats(xx, case_labels);

bar(xx, Y, 'grouped');
yline(0, 'k-', 'LineWidth', 1.0);

ylabel('Cumulative tracer flux / initial ECS mass (%)');
title('Cumulative internal tracer fluxes along the chain');

legend({'$J_{P_aE_a}^{cum}$', ...
        '$J_{E_aE_m}^{cum}$', ...
        '$J_{E_mE_v}^{cum}$', ...
        '$J_{E_vP_v}^{cum}$'}, ...
        'Interpreter', 'latex', ...
        'Location', 'bestoutside');

grid on;
box on;
end


function r = get_result(results, name)
for i = 1:numel(results)
    if strcmp(results{i}.cfg.name, name)
        r = results{i};
        return;
    end
end
error('Result not found: %s', name);
end