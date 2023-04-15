function [data] = run_unknown_lambda()
% Return the UDT/PLR performance
% Declare global variables
% See main.m
global N lambda D delta_p delta_a
global state num_state initial_belief action num_action alpha num_alpha
global transF rewardF obserF qF
global metric_type channel_type
global simu_frames

% Print the metric
switch metric_type
    case 'UDT'
        fprintf("|> Compute the UDT performance.\n");
	case 'PLR'
        fprintf("|> Compute the PLR performance.\n");
    otherwise
        error("Unexpected metric.\n");
end
% Set the packet arrival rate
lambda = 0.5 / (N / D);

%% Compute the UDT/PLR performance
state = 0:N;
num_state = length(state);
action = 0:delta_p:1;
num_action = length(action);
alpha = 0:delta_a:1;
num_alpha = length(alpha);

[transF, rewardF, obserF] = function_computing();
[qF, pi_furQ] = real_QFunction(channel_type);

initial_belief = binopdf(state, N, lambda);

real_simQ_known = real_simQ_sim_basic();
real_simQ_unknown = real_simQ_sim_unknown();
fprintf("--------------------------------------------------\n")

if strcmp(channel_type, 'collision')
    real_furQ_known = real_furQ_sim_basic(pi_furQ);
    real_furQ_unknown = real_furQ_sim_unknown(pi_furQ);
    fprintf("--------------------------------------------------\n")
end

real_myo_known = real_myo_sim_basic();
real_myo_unknown = real_myo_sim_unknown();

%% Merge the UDT/PLR performance
data = zeros(6, log10(simu_frames)+1);
data(1, :) = real_simQ_known;
data(2, :) = real_simQ_unknown;
if strcmp(channel_type, 'collision')
    data(3, :) = real_furQ_known;
    data(4, :) = real_furQ_unknown;
end
data(5, :) = real_myo_known;
data(6, :) = real_myo_unknown;