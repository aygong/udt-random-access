function [data] = run_basic_config()
% Return the UDT/PLR performance
% Declare global variables
% See main.m
global N lambda D delta_p delta_a
global state num_state initial_belief action num_action alpha num_alpha
global transF rewardF obserF qF
global metric_type channel_type urgency_type
global simu_switch simu_indept simu_frames

% Set the packet arrival rates
if strcmp(metric_type, 'UDT')
    lambdas = 0.1/(N/D):0.1/(N/D):0.8/(N/D);
else
    lambdas = 0.1/(N/D):0.01/(N/D):0.2/(N/D);
end

% Set the simulation parameters
simu_switch = true;
simu_indept = 10;
simu_frames = 1e+6;

% Define local variables
X = length(lambdas);
idea_opt_ana = zeros(1, X);
idea_opt_sim = zeros(1, X);
real_simQ_sim = zeros(1, X);
real_furQ_sim = zeros(1, X);
real_sta_ana = zeros(1, X);
real_sta_sim = zeros(1, X);
real_DaH_sim = zeros(1, X);
real_DaH_ana = zeros(1, X);
real_myo_sim = zeros(1, X);

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
    lambda = lambdas(x);
    fprintf("\n|> %d / %d: N = %d, D = %d, Load = %.2f\n", x, X, N, D, N * lambda / D);

    initial_belief = binopdf(state, N, lambda);

    [idea_opt_ana(x), pi_opt] = basic_opt_ana();
    if simu_switch == true
        idea_opt_sim(x) = basic_opt_sim(pi_opt);
        fprintf("~ Error = %.2f%%\n", (idea_opt_ana(x) - idea_opt_sim(x)) / idea_opt_ana(x) * 100);
    end

    real_simQ_sim(x) = basic_simQ_sim(0);

    if strcmp(channel_type, 'collision')
        real_furQ_sim(x) = basic_furQ_sim(pi_furQ, 0);
    end
    
    real_myo_sim(x) = basic_myo_sim(0);
    
    [real_sta_ana(x), pi_sta] = basic_sta_ana();
    if simu_switch == true
        real_sta_sim(x) = basic_sta_sim(pi_sta, 0, true);
        fprintf("~ Error = %.2f%%\n", (real_sta_ana(x) - real_sta_sim(x)) / real_sta_ana(x) * 100);
    end

    real_DaH_sim(x) = basic_DaH_sim();
    if strcmp(metric_type, 'PLR') && strcmp(urgency_type, 'one')
        real_DaH_ana(x) = basic_DaH_ana();
        fprintf("~ Error = %.2f%%\n", (real_DaH_ana(x) - real_DaH_sim(x)) / real_DaH_ana(x) * 100);
    end
end

% Merge the results
data = zeros(6, X);
data(1:4, :) = [idea_opt_ana; real_simQ_sim; real_furQ_sim; real_sta_ana];
if strcmp(metric_type, 'UDT')
    data(5, :) = real_DaH_sim;
else
    data(5, :) = real_DaH_ana;
end
data(6, :) = real_myo_sim;