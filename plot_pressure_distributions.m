function pressure_table = plot_pressure_distributions(results)
% ============================================================
% Plot compartment-wise pressure distributions
%
% State ordering:
%   y(:,1) = p_Pa
%   y(:,2) = p_A
%   y(:,3) = p_Ea
%   y(:,4) = p_Em
%   y(:,5) = p_Ev
%   y(:,6) = p_Pv
%
% Input:
%   results : cell array returned by run_case
%
% Output:
%   pressure_table : summary statistics over the final waveform period
% ============================================================

comp_labels = {'P_a','A','E_a','E_m','E_v','P_v'};
ncomp = numel(comp_labels);
ncase = numel(results);

case_labels = strings(ncase,1);

Pmean = zeros(ncase,ncomp);
Pmin  = zeros(ncase,ncomp);
Pmax  = zeros(ncase,ncomp);

DPmean = zeros(ncase,4);
DPmin  = zeros(ncase,4);
DPmax  = zeros(ncase,4);

% % ============================================================
% % 1. Pressure time series for each case
% % ============================================================
% for k = 1:ncase
% 
%     r = results{k};
% 
%     case_labels(k) = string(r.cfg.name);
% 
%     t = r.t;
%     P = r.y(:,1:6);
% 
%     figure('Name',['Pressure time series: ', char(case_labels(k))]);
% 
%     tiledlayout(3,2, ...
%         'Padding','compact', ...
%         'TileSpacing','compact');
% 
%     for j = 1:ncomp
% 
%         nexttile;
% 
%         plot(t,P(:,j),'LineWidth',1.1);
% 
%         xlabel('Time');
%         ylabel(['p_{',comp_labels{j},'}']);
% 
%         title(['$',comp_labels{j},'$'], ...
%             'Interpreter','latex');
% 
%         box on;
%     end
% 
%     sgtitle(strrep(char(case_labels(k)),'_','\_'));
% 
% end

% ============================================================
% 2. Statistics over the final waveform period
% ============================================================
% for k = 1:ncase
% 
%     r = results{k};
% 
%     t = r.t;
%     P = r.y(:,1:6);
% 
%     if isfield(r,'p') && isfield(r.p,'pulse_period')
%         T_wave = r.p.pulse_period;
%     elseif isfield(r.cfg,'pulse_period')
%         T_wave = r.cfg.pulse_period;
%     else
%         warning(['Pulse period not found for case ', ...
%             char(case_labels(k)), ...
%             '. Using the final 10%% of the simulation.']);
% 
%         T_wave = 0.1*(t(end)-t(1));
%     end
% 
%     t_start = max(t(1),t(end)-T_wave);
%     idx = t >= t_start;
% 
%     t_window = t(idx);
%     P_window = P(idx,:);
% 
%     for j = 1:ncomp
%         Pmean(k,j) = trapz(t_window,P_window(:,j)) ...
%             /(t_window(end)-t_window(1));
% 
%         Pmin(k,j) = min(P_window(:,j));
%         Pmax(k,j) = max(P_window(:,j));
%     end
% 
%     % Important pressure differences
%     DP = [ ...
%         P_window(:,1)-P_window(:,3), ... % Pa-Ea
%         P_window(:,1)-P_window(:,2), ... % Pa-A
%         P_window(:,2)-P_window(:,3), ... % A-Ea
%         P_window(:,5)-P_window(:,6)];    % Ev-Pv
% 
%     for j = 1:4
%         DPmean(k,j) = trapz(t_window,DP(:,j)) ...
%             /(t_window(end)-t_window(1));
% 
%         DPmin(k,j) = min(DP(:,j));
%         DPmax(k,j) = max(DP(:,j));
%     end
% 
% end

% % ============================================================
% % 3. Mean compartment pressure profile
% % ============================================================
% figure('Name','Mean compartment pressure profile');
% 
% hold on;
% box on;
% 
% for k = 1:ncase
% 
%     plot(1:ncomp,Pmean(k,:),'-o', ...
%         'LineWidth',1.4, ...
%         'DisplayName',strrep(char(case_labels(k)),'_','\_'));
% 
% end
% 
% set(gca, ...
%     'XTick',1:ncomp, ...
%     'XTickLabel',comp_labels);
% 
% xlabel('Compartment');
% ylabel('Mean pressure');
% title('Mean pressure profile over the final waveform period');

% legend('Location','best');

% ============================================================
% 4. Pressure ranges by compartment
% ============================================================
% for j = 1:ncomp
% 
%     figure('Name',['Pressure range: ',comp_labels{j}]);
% 
%     x = 1:ncase;
% 
%     errorbar(x,Pmean(:,j), ...
%         Pmean(:,j)-Pmin(:,j), ...
%         Pmax(:,j)-Pmean(:,j), ...
%         'o','LineWidth',1.2);
% 
%     set(gca, ...
%         'XTick',x, ...
%         'XTickLabel',case_labels);
% 
%     xtickangle(30);
% 
%     ylabel(['p_{',comp_labels{j},'}']);
%     title(['Pressure range in $',comp_labels{j},'$'], ...
%         'Interpreter','latex');
% 
%     box on;
% 
% end

% ============================================================
% 5. Driving pressure differences
% ============================================================
dp_labels = { ...
    'p_{P_a}-p_{E_a}', ...
    'p_{P_a}-p_A', ...
    'p_A-p_{E_a}', ...
    'p_{E_v}-p_{P_v}'};

figure('Name','Mean driving pressure differences');

bar(DPmean);

set(gca, ...
    'XTick',1:ncase, ...
    'XTickLabel',case_labels);

xtickangle(30);

ylabel('Mean pressure difference');

legend(dp_labels, ...
    'Interpreter','latex', ...
    'Location','best');

title('Driving pressure differences over the final waveform period');

box on;

% ============================================================
% 6. Time series of important pressure differences
% ============================================================
for q = 1:4

    figure('Name',['Pressure difference: ',dp_labels{q}]);

    hold on;
    box on;

    for k = 1:ncase

        r = results{k};

        t = r.t;
        P = r.y(:,1:6);

        switch q
            case 1
                dp = P(:,1)-P(:,3);
            case 2
                dp = P(:,1)-P(:,2);
            case 3
                dp = P(:,2)-P(:,3);
            case 4
                dp = P(:,5)-P(:,6);
        end

        plot(t,dp,'LineWidth',1.1, ...
            'DisplayName', ...
            strrep(char(case_labels(k)),'_','\_'));

    end

    xlabel('Time');
    ylabel(dp_labels{q},'Interpreter','latex');
    title(dp_labels{q},'Interpreter','latex');

    legend('Location','best');
end

% ============================================================
% 7. Summary table
% ============================================================
pressure_table = table(case_labels);

for j = 1:ncomp

    pressure_table.([comp_labels{j},'_mean']) = Pmean(:,j);
    pressure_table.([comp_labels{j},'_min'])  = Pmin(:,j);
    pressure_table.([comp_labels{j},'_max'])  = Pmax(:,j);

end

pressure_table.dP_PaEa_mean = DPmean(:,1);
pressure_table.dP_PaEa_min  = DPmin(:,1);
pressure_table.dP_PaEa_max  = DPmax(:,1);

pressure_table.dP_PaA_mean = DPmean(:,2);
pressure_table.dP_PaA_min  = DPmin(:,2);
pressure_table.dP_PaA_max  = DPmax(:,2);

pressure_table.dP_AEa_mean = DPmean(:,3);
pressure_table.dP_AEa_min  = DPmin(:,3);
pressure_table.dP_AEa_max  = DPmax(:,3);

pressure_table.dP_EvPv_mean = DPmean(:,4);
pressure_table.dP_EvPv_min  = DPmin(:,4);
pressure_table.dP_EvPv_max  = DPmax(:,4);


%%

%%
dp_mean   = zeros(ncase,1);
dp_eff    = zeros(ncase,1);
cov_Gdp   = zeros(ncase,1);
Q_mean    = zeros(ncase,1);
G_mean    = zeros(ncase,1);
net_Q_last = zeros(ncase,1);

for k = 1:ncase

    r = results{k};

    t = r.t(:);
    P = r.y(:,1:6);

    T_wave = r.p.pulse_period;
    idx = t >= t(end)-T_wave;

    flux_idx = find(idx);

    tw = t(idx);
    dp = P(idx,1)-P(idx,3);

    Ggap = [r.flux(flux_idx).G_gap_a];
    Qgap = [r.flux(flux_idx).Q_PaEa];

    tw   = tw(:);
    dp   = dp(:);
    Ggap = Ggap(:);
    Qgap = Qgap(:);

    if ~(numel(tw)==numel(dp) && ...
         numel(tw)==numel(Ggap) && ...
         numel(tw)==numel(Qgap))

        error(['Dimension mismatch: ', ...
            't=%d, dp=%d, G=%d, Q=%d'], ...
            numel(tw),numel(dp), ...
            numel(Ggap),numel(Qgap));
    end

    window_length = tw(end)-tw(1);

    dp_mean(k) = trapz(tw,dp)/window_length;
    G_mean(k)  = trapz(tw,Ggap)/window_length;
    Q_mean(k)  = trapz(tw,Qgap)/window_length;

    net_Q_last(k) = trapz(tw,Qgap);

    denom_G = trapz(tw,Ggap);

    if abs(denom_G) < 1e-14
        dp_eff(k) = NaN;
    else
        % Since Qgap = Ggap .* dp
        dp_eff(k) = trapz(tw,Qgap)/denom_G;
    end

    cov_Gdp(k) = ...
        Q_mean(k)-G_mean(k)*dp_mean(k);

    % Check flux identity
    flux_error = max(abs(Qgap-Ggap.*dp));

    case_name =  string(r.cfg.name);

    fprintf('%-20s mean_dp=%+10.4f, effective_dp=%+10.4f,mean_G=%10.4f, mean_Q=%+10.4f,net_last=%+10.4f, cov=%+10.4f, max|Q-Gdp|=%.3e\n', ...
        case_name, ...
        dp_mean(k), ...
        dp_eff(k), ...
        G_mean(k), ...
        Q_mean(k), ...
        net_Q_last(k), ...
        cov_Gdp(k), ...
        flux_error);
end

figure;
bar([dp_mean,dp_eff]);

set(gca,'XTick',1:ncase,'XTickLabel',case_labels);
xtickangle(25);

ylabel('Pressure difference');
legend({'Unweighted mean',...
        'Conductance-weighted effective mean'}, ...
        'Location','best');

title('Pressure driving and dynamic-gap rectification');
box on;  



figure; hold on; box on;
for k = 1:numel(results)
    r = results{k};
    t = r.t(:);
    T_wave = r.p.pulse_period;
    idx = t >= t(end)-T_wave;

    dp = r.y(idx,1) - r.y(idx,3);
    G  = [r.flux(idx).G_gap_a].';

    plot(dp, G, 'LineWidth', 1.4, 'DisplayName', string(r.cfg.name));
end
xlabel('\Delta P_{P_aE_a}');
ylabel('G_{a,gap}');
title('Conductance-pressure phase relation');
legend('Location','best');
grid on;
%writetable(pressure_table, ...
    % 'pressure_distribution_summary.csv');

end