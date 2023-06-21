function [data] = run_unsync_traffic()
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
simu_indept = 1e+3;
simu_frames = 1e+3;

% Set the maximum time offsets
offsets = 0:D-1;

% Define local variables
X = length(offsets);
real_simQ_sim = zeros(1, X);
real_furQ_sim = zeros(1, X);
real_sta_sim = zeros(1, X);

% Compute the UDT/PLR performance
state = 0:N;
num_state = length(state);
action = 0:delta_p:1;
num_action = length(action);
alpha = 0:delta_a:1;
num_alpha = length(alpha);

[transF, rewardF, obserF] = function_computing();
[qF, pi_furQ] = QF_computing(channel_type);

for x = 1:X
    fprintf("\n|> %d / %d: Maximum time offsets = %d\n", x, X, offsets(x));
    
    initial_belief = binopdf(state, N, lambda);
    
    real_simQ_sim(x) = unsync_simQ_sim(offsets(x));

    if strcmp(channel_type, 'collision')
        real_furQ_sim(x) = unsync_furQ_sim(pi_furQ, offsets(x));
    end

    real_sta_sim(x) = unsync_sta_sim(offsets(x));
end

% Merge the results
data = [real_simQ_sim; real_furQ_sim; real_sta_sim];