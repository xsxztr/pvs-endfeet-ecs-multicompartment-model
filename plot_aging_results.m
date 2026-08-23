function plot_aging_results(results, summary_table)
%PLOT_AGING_RESULTS Summary plots for the aging-associated study.

figure('Name', 'Aging parameter sensitivity', 'Color', 'w');
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

groups = ["epsilon", "eta", "alpha"];
xlabels = {'$\epsilon/\epsilon_0$', '$\eta_o$', '$\alpha_{\mathrm{AQP4}}$'};

for j = 1:3
    group = groups(j);
    mask = summary_table.group_name == group;

    if group == "epsilon"
        x = summary_table.epsilon_ratio(mask);
    elseif group == "eta"
        x = summary_table.eta_outer(mask);
    else
        x = summary_table.aqp4_scale(mask);
    end

    [x, order] = sort(x);

    ven = summary_table.VenOut(mask);
    ven = ven(order);

    wbar = summary_table.w_mean(mask);
    wbar = wbar(order);

    nexttile(j);
    plot(x, ven, '-o', 'LineWidth', 1.4, 'MarkerSize', 6);
    xlabel(xlabels{j}, 'Interpreter', 'latex');
    ylabel('$O_v(T)$', 'Interpreter', 'latex');
    title(sprintf('%s sensitivity: venous output', group));
    grid on; box on;

    nexttile(j+3);
    plot(x, wbar, '-o', 'LineWidth', 1.4, 'MarkerSize', 6);
    xlabel(xlabels{j}, 'Interpreter', 'latex');
    ylabel('$\overline{w_a}$', 'Interpreter', 'latex');
    title(sprintf('%s sensitivity: mean gap factor', group));
    grid on; box on;
end

mask = summary_table.group_name == "combined";
T = summary_table(mask, :);

desired = ["young", "moderate_aging", "advanced_aging"];
order = zeros(numel(desired),1);
for i = 1:numel(desired)
    order(i) = find(T.case_name == desired(i), 1);
end
T = T(order,:);

labels = categorical({'Young', 'Moderate aging', 'Advanced aging'}, ...
    {'Young', 'Moderate aging', 'Advanced aging'});

figure('Name', 'Combined aging phenotype', 'Color', 'w');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
bar(labels, T.VenOut);
ylabel('$O_v(T)$', 'Interpreter', 'latex');
title('Cumulative venous output');
grid on; box on;

nexttile;
bar(labels, T.ECS_clear_pct);
ylabel('$C_E(T)$ (\%)', 'Interpreter', 'latex');
title('ECS cleared fraction');
grid on; box on;

nexttile;
bar(labels, [T.w_mean, T.w_max], 'grouped');
ylabel('Gap factor');
title('Dynamic gap response');
legend({'$\overline{w_a}$', '$w_{a,\max}$'}, ...
    'Interpreter', 'latex', 'Location', 'best');
grid on; box on;

nexttile;
bar(labels, T.max_abs_Sa);
ylabel('$\max |S_a|$', 'Interpreter', 'latex');
title('Mechanical PVS source');
grid on; box on;

figure('Name', 'Combined aging time histories', 'Color', 'w');
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

case_names = cellstr(T.case_name);
display_names = {'Young', 'Moderate aging', 'Advanced aging'};

nexttile; hold on; box on;
for i = 1:numel(case_names)
    r = get_result_local(results, case_names{i});
    MEtot = r.y(:,9) + r.y(:,10) + r.y(:,11);
    plot(r.t, MEtot/MEtot(1), 'LineWidth', 1.3, ...
        'DisplayName', display_names{i});
end
xlabel('Time (s)');
ylabel('$M_E(t)/M_E(0)$', 'Interpreter', 'latex');
title('Total ECS tracer mass');
legend('Location', 'best');
grid on;

nexttile; hold on; box on;
for i = 1:numel(case_names)
    r = get_result_local(results, case_names{i});
    plot(r.t, r.metrics.Ov_norm, 'LineWidth', 1.3, ...
        'DisplayName', display_names{i});
end
xlabel('Time (s)');
ylabel('$O_v(t)/M_E(0)$', 'Interpreter', 'latex');
title('Cumulative venous output');
legend('Location', 'best');
grid on;

nexttile; hold on; box on;
for i = 1:numel(case_names)
    r = get_result_local(results, case_names{i});
    plot(r.t, r.y(:,7), 'LineWidth', 1.1, ...
        'DisplayName', display_names{i});
end
xlabel('Time (s)');
ylabel('$w_a(t)$', 'Interpreter', 'latex');
title('Dynamic arterial gap');
legend('Location', 'best');
grid on;

end

function r = get_result_local(results, name)
for k = 1:numel(results)
    if strcmp(results{k}.cfg.name, name)
        r = results{k};
        return;
    end
end
error('Result "%s" was not found.', name);
end
