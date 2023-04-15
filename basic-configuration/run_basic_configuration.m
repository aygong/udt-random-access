function [data] = run_basic_configuration()
% Return the UDT/PLR performance
% Declare global variables
% See main.m
global N lambda D delta_p delta_a
global state num_state initial_belief action num_action alpha num_alpha
global transF rewardF obserF qF
global metric_type channel_type
global simu_switch

% Print the metric
% Set the packet arrival rate according to the metric
switch metric_type
    case 'UDT'
        fprintf("|> Compute the UDT performance.\n");
        lambdas = 0.1/(N/D):0.1/(N/D):0.8/(N/D);
	case 'PLR'
        fprintf("|> Compute the PLR performance.\n");
        lambdas = 0.1/(N/D):0.01/(N/D):0.2/(N/D);
    otherwise
        error("Unexpected metric.\n");
end

%% Define local variables
idea_opt_ana = zeros(1, 20);
idea_opt_sim = zeros(1, 20);
real_simQ_sim = zeros(1, 20);
real_furQ_sim = zeros(1, 20);
real_sta_ana = zeros(1, 20);
real_sta_sim = zeros(1, 20);
real_DaH_sim = zeros(1, 20);
real_DaH_ana = zeros(1, 20);
real_myo_sim = zeros(1, 20);

%% Compute the UDT/PLR performance
state = 0:N;
num_state = length(state);
action = 0:delta_p:1;
num_action = length(action);
alpha = 0:delta_a:1;
num_alpha = length(alpha);

[transF, rewardF, obserF] = function_computing();
[qF, pi_furQ] = real_QFunction(channel_type);

for x = 1:length(lambdas)
    lambda = lambdas(x);
    fprintf("\n|> %d / %d: N = %d, D = %d, Load = %.2f\n", ...
        x, length(lambdas), N, D, N * lambda / D);

    initial_belief = binopdf(state, N, lambda);

    [idea_opt_ana(x), pi_opt] = idea_opt_ana_basic();
    if simu_switch == true
        idea_opt_sim(x) = idea_opt_sim_basic(pi_opt);
        fprintf("~ Error = %.2f%%\n", ...
            (idea_opt_ana(x) - idea_opt_sim(x)) / idea_opt_ana(x) * 100);
    end

    real_simQ_sim(x) = real_simQ_sim_basic();

    if strcmp(channel_type, 'collision')
        real_furQ_sim(x) = real_furQ_sim_basic(pi_furQ);
    end
    
    real_myo_sim(x) = real_myo_sim_basic();
    
    [real_sta_ana(x), pi_sta] = real_sta_ana_basic();
    if simu_switch == true
        real_sta_sim(x) = real_sta_sim_basic(pi_sta);
        fprintf("~ Error = %.2f%%\n", ...
            (real_sta_ana(x) - real_sta_sim(x)) / real_sta_ana(x) * 100);
    end

    real_DaH_sim(x) = real_DaH_sim_basic();
    if strcmp(metric_type, 'PLR')
        real_DaH_ana(x) = real_DaH_ana_basic();
        fprintf("~ Error = %.2f%%\n", ...
            (real_DaH_ana(x) - real_DaH_sim(x)) / real_DaH_ana(x) * 100);
    end
end

%% Merge the UDT/PLR performance
data = zeros(6, 20);
data(1, :) = idea_opt_ana(1, :);
data(2, :) = real_simQ_sim(1, :);
data(3, :) = real_furQ_sim(1, :);
data(4, :) = real_sta_ana(1, :);
if strcmp(metric_type, 'UDT')
    data(5, :) = real_DaH_sim(1, :);
else
    data(5, :) = real_DaH_ana(1, :);
end
data(6, :) = real_myo_sim(1, :);