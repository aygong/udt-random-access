function [data] = run_unsync_traffic()
% Return the UDT/PLR performance
% Declare global variables
% See main.m
global N lambda D delta_p delta_a
global state num_state initial_belief action num_action alpha num_alpha
global transF rewardF obserF qF
global metric_type channel_type

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
% Set the maximum time offsets
offsets = 0:D-1;

%% Define local variables
real_simQ_sim = zeros(1, 20);
real_furQ_sim = zeros(1, 20);
real_sta_sim = zeros(1, 20);

%% Compute the UDT/PLR performance
state = 0:N;
num_state = length(state);
action = 0:delta_p:1;
num_action = length(action);
alpha = 0:delta_a:1;
num_alpha = length(alpha);

[transF, rewardF, obserF] = function_computing();
[qF, pi_furQ] = real_QFunction(channel_type);

for x = 1:length(offsets)
    fprintf("\n|> %d / %d: Maximum time offsets = %d\n", ...
        x, length(offsets), offsets(x));
    
    initial_belief = binopdf(state, N, lambda);
    
    real_simQ_sim(x) = real_simQ_sim_unsync(offsets(x));

    if strcmp(channel_type, 'collision')
        real_furQ_sim(x) = real_furQ_sim_unsync(pi_furQ, offsets(x));
    end

    real_sta_sim(x) = real_sta_sim_unsync(offsets(x));
end

%% Merge the UDT/PLR performance
data = zeros(3, 20);
data(1, :) = real_simQ_sim(1, :);
data(2, :) = real_furQ_sim(1, :);
data(3, :) = real_sta_sim(1, :);