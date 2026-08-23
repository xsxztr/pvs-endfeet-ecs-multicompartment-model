function check_model_dependencies()
%CHECK_MODEL_DEPENDENCIES Verify that the required model files are visible.

required_functions = {
    'params_default'
    'set_case'
    'set_SR_scale'
    'run_case'
    'initial_condition_extended'
    'rhs_model'
    'compute_fluxes'
    'compute_metrics_extended'
    };

missing = {};

for k = 1:numel(required_functions)
    if exist(required_functions{k}, 'file') ~= 2
        missing{end+1} = required_functions{k}; %#ok<AGROW>
    end
end

if ~isempty(missing)
    error(['The following required model files are not on the MATLAB path: ' ...
        strjoin(missing, ', ')]);
end

end
