function rect_table = plot_gap_rectification(results)
% ============================================================
% Analyze dynamic-gap hydraulic rectification
%
% Uses the final waveform period for each case.
%
% Required fields:
%   r.t
%   r.y(:,1) = p_Pa
%   r.y(:,3) = p_Ea
%   r.flux(:).G_gap_a
%   r.flux(:).Q_PaEa
%   r.p.pulse_period
%   r.cfg.name
%
% Output:
%   rect_table : summary metrics for each case
% ============================================================

ncase = numel(results);

case_name = strings(ncase,1);

mean_dp = zeros(ncase,1);
effective_dp = zeros(ncase,1);
mean_G = zeros(ncase,1);
mean_Q = zeros(ncase,1);
net_Q_last = zeros(ncase,1);
cov_G_dp = zeros(ncase,1);
flux_identity_error = zeros(ncase,1);

% Store last-period data for plotting
data = struct( ...
    'name', {}, ...
    't', {}, ...
    'phase', {}, ...
    'dp', {}, ...
    'G', {}, ...
    'Q', {});

for k = 1:ncase

    r = results{k};

    name = to_text(r.cfg.name);
    case_name(k) = string(name);

    t = r.t(:);
    P = r.y(:,1:6);

    if isfield(r,'p') && isfield(r.p,'pulse_period')
        T_wave = 10;%r.p.pulse_period;
    else
        error('Missing r.p.pulse_period for case %s.', name);
    end

    t_start = t(end)-T_wave;
    idx = t >= t_start;
    ii = find(idx);

    tw = t(idx);
    dp = P(idx,1)-P(idx,3);

    G = [r.flux(ii).G_gap_a];
    Q = [r.flux(ii).Q_PaEa];

    % Force column-vector orientation
    tw = tw(:);
    dp = dp(:);
    G = G(:);
    Q = Q(:);

    if ~(numel(tw)==numel(dp) && ...
         numel(tw)==numel(G) && ...
         numel(tw)==numel(Q))

        error(['Dimension mismatch in case %s: ', ...
               't=%d, dp=%d, G=%d, Q=%d'], ...
               name, numel(tw), numel(dp), ...
               numel(G), numel(Q));
    end

    window_length = tw(end)-tw(1);

    mean_dp(k) = trapz(tw,dp)/window_length;
    mean_G(k)  = trapz(tw,G)/window_length;
    mean_Q(k)  = trapz(tw,Q)/window_length;

    net_Q_last(k) = trapz(tw,Q);

    denom_G = trapz(tw,G);

    if abs(denom_G) < 1e-14
        effective_dp(k) = NaN;
    else
        effective_dp(k) = trapz(tw,Q)/denom_G;
    end

    cov_G_dp(k) = ...
        mean_Q(k)-mean_G(k)*mean_dp(k);

    flux_identity_error(k) = ...
        max(abs(Q-G.*dp));

    % Normalize time to waveform phase
    phase = (tw-tw(1))/T_wave;

    data(k).name = name;
    data(k).t = tw;
    data(k).phase = phase;
    data(k).dp = dp;
    data(k).G = G;
    data(k).Q = Q;

    fprintf([ ...
        '%-20s mean_dp=%+10.4f, ', ...
        'effective_dp=%+10.4f, ', ...
        'mean_G=%10.4f, mean_Q=%+10.4f, ', ...
        'net_last=%+10.4f, cov=%+10.4f, ', ...
        'max|Q-Gdp|=%.3e\n'], ...
        name, ...
        mean_dp(k), ...
        effective_dp(k), ...
        mean_G(k), ...
        mean_Q(k), ...
        net_Q_last(k), ...
        cov_G_dp(k), ...
        flux_identity_error(k));
end

% ============================================================
% Figure 1: Delta p and G versus waveform phase
% One row per case
% ============================================================
figure('Name','Pressure-conductance time relation');

tl = tiledlayout(ncase,1, ...
    'Padding','compact', ...
    'TileSpacing','compact');

for k = 1:ncase

    nexttile;

    yyaxis left
    plot(data(k).phase,data(k).dp, ...
        'LineWidth',1.3);
    ylabel('\Delta p_{P_aE_a}');

    yline(0,'--');

    yyaxis right
    plot(data(k).phase,data(k).G, ...
        'LineWidth',1.3);
    ylabel('G_{a,\rm gap}');

    title(strrep(data(k).name,'_','\_'));

    if k == ncase
        xlabel('Waveform phase');
    end

    box on;
end

title(tl,'Pressure difference and gap conductance');

% ============================================================
% Figure 2: Q versus waveform phase
% ============================================================
figure('Name','Gap-mediated flux');

hold on;
box on;

for k = 1:ncase
    plot(data(k).phase,data(k).Q, ...
        'LineWidth',1.3, ...
        'DisplayName',strrep(data(k).name,'_','\_'));
end

yline(0,'--');

xlabel('Waveform phase');
ylabel('Q_{P_aE_a}');
title('Gap-mediated flux over the final waveform period');
legend('Location','best');

% ============================================================
% Figure 3: G-delta p phase loops
% ============================================================
figure('Name','Conductance-pressure phase loops');

hold on;
box on;

for k = 1:ncase
    plot(data(k).dp,data(k).G, ...
        'LineWidth',1.4, ...
        'DisplayName',strrep(data(k).name,'_','\_'));
end

xline(0,'--');

xlabel('\Delta p_{P_aE_a}=p_{P_a}-p_{E_a}');
ylabel('G_{a,\rm gap}');
title('Conductance-pressure phase relation');
legend('Location','best');

% ============================================================
% Figure 4: mean versus effective pressure difference
% ============================================================
figure('Name','Rectification summary');

bar([mean_dp,effective_dp]);

set(gca, ...
    'XTick',1:ncase, ...
    'XTickLabel',case_name);

xtickangle(25);

ylabel('Pressure difference');
legend({'Unweighted mean', ...
        'Conductance-weighted effective mean'}, ...
        'Location','best');

title('Pressure driving and dynamic-gap rectification');
box on;

% ============================================================
% Figure 5: decomposition of mean flux
%
% <Q> = <G><dp> + Cov(G,dp)
% ============================================================
adverse_mean_term = mean_G .* mean_dp;

figure('Name','Mean-flux decomposition');

bar([adverse_mean_term,cov_G_dp,mean_Q]);

set(gca, ...
    'XTick',1:ncase, ...
    'XTickLabel',case_name);

xtickangle(25);

ylabel('Contribution to mean gap flux');
legend({ ...
    '\langle G\rangle\langle\Delta p\rangle', ...
    'Cov(G,\Delta p)', ...
    '\langle Q\rangle'}, ...
    'Interpreter','tex', ...
    'Location','best');

title('Mean gap-flux decomposition');
box on;

% ============================================================
% Summary table
% ============================================================
rect_table = table( ...
    case_name, ...
    mean_dp, ...
    effective_dp, ...
    mean_G, ...
    mean_Q, ...
    net_Q_last, ...
    adverse_mean_term, ...
    cov_G_dp, ...
    flux_identity_error);

disp(rect_table);

writetable(rect_table, ...
    'gap_rectification_summary.csv');

end


function txt = to_text(value)

while iscell(value)

    if isempty(value)
        txt = '';
        return;
    end

    value = value{1};
end

txt = char(string(value));

end