function [deltaPi_PaA, deltaPi_AEa] = osmotic_terms_extended(p, osmotic_case)
% Osmotic pressure differences:
% deltaPi_PaA = Pi_Pa - Pi_A
% deltaPi_AEa = Pi_A - Pi_Ea

switch lower(osmotic_case)

    case {'none','no_osm','no-osm','baseline'}
        deltaPi_PaA = 0.0;
        deltaPi_AEa = 0.0;

    case 'endfoot_high'
        % Pi_A higher than Pi_Pa and Pi_Ea
        % Water tends to enter endfoot.
        deltaPi_PaA = -p.osmotic_pressure;  % Pi_Pa - Pi_A < 0
        deltaPi_AEa =  p.osmotic_pressure;  % Pi_A - Pi_Ea > 0

    case 'pvs_high'
        % Pi_Pa higher than Pi_A
        deltaPi_PaA = p.osmotic_pressure;
        deltaPi_AEa = 0.0;

    otherwise
        error('Unknown osmotic_case: %s', osmotic_case);
end

end