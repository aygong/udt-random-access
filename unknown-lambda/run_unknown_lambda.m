function [data] = run_unknown_lambda()
% Return the UDT/PLR performance
% Declare global variables
% See main.m
global N lambda D delta_p delta_a
global state num_state initial_belief action num_action alpha num_alpha
global transF rewardF obserF qF
global channel_type
global simu_indept simu_frames

% Set the packet arrival rate
lambda = 0.5 / (N / D);

% Set the simulation parameters
simu_indept = 10;
simu_frames = 1e+6;

% Compute the UDT/PLR performance
state = 0:N;
num_state = length(state);
action = 0:delta_p:1;
num_action = length(action);
alpha = 0:delta_a:1;
num_alpha = length(alpha);

[transF, rewardF, obserF] = function_computing();
[qF, pi_furQ] = QF_computing(channel_type);

initial_belief = binopdf(state, N, lambda);

fprintf("\n|> The simplified QMDP-based policy\n");
real_simQ_known = basic_simQ_sim(0);
real_simQ_unknown = unknown_simQ_sim();

if strcmp(channel_type, 'collision')
    fprintf("\n|> The further simplified QMDP-based policy\n");
    real_furQ_known = basic_furQ_sim(pi_furQ, 0);
    real_furQ_unknown = unknown_furQ_sim(pi_furQ);
end

fprintf("\n|> The myopic policy\n");
real_myo_known = basic_myo_sim(0);
real_myo_unknown = unknown_myo_sim();

% Merge the results
data = zeros(6, log10(simu_frames)+1);
data(1, :) = real_simQ_known;
data(2, :) = real_simQ_unknown;
if strcmp(channel_type, 'collision')
    data(3, :) = real_furQ_known;
    data(4, :) = real_furQ_unknown;
end
data(5, :) = real_myo_known;
data(6, :) = real_myo_unknown;