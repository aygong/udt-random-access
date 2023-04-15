function [data] = run_heter_lambdas()
% Return the UDT/PLR performance
% Declare global variables
% See main.m
global N lambda D delta_p delta_a
global state num_state initial_belief action num_action alpha num_alpha
global transF rewardF obserF qF
global metric_type channel_type
global simu_indept

% Print the metric
switch metric_type
    case 'UDT'
        fprintf("|> Compute the UDT performance.\n");
	case 'PLR'
        fprintf("|> Compute the PLR performance.\n");
    otherwise
        error("Unexpected metric.\n");
end
% Set the mean of the packet arrival rate
mean = 0.5 / (N / D);
% Set the half of the interval length
halves = 0:mean/5:mean;

%% Define local variables
real_simQ_sim = zeros(1, 20);
real_furQ_sim = zeros(1, 20);
real_sta_sim = zeros(1, 20);
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

for x = 1:length(halves)
    fprintf("\n|> %d / %d: Mean = %.4f, Interval = [%.4f, %.4f]\n", ...
        x, length(halves), mean, mean - halves(x), mean + halves(x));
    
    % Generate a simu_indept-by-N matrix of uniformly distributed 
    % random numbers between mean - halves(x) and mean + halves(x)
    lambda = mean + (2 * rand(simu_indept, N) - 1) * halves(x);
    % Compute the joint distributions of Bernoulli random variables
    initial_belief = zeros(simu_indept, num_state);
    for SI = 1:simu_indept
        initial_belief(SI, :) = asymmetric_binomial(lambda(SI, :));
    end
    fprintf("-> Finish generating initial beliefs.\n");
    
    real_simQ_sim(x) = real_simQ_sim_heter();
    
    if strcmp(channel_type, 'collision')
        real_furQ_sim(x) = real_furQ_sim_heter(pi_furQ);
    end
    
    real_myo_sim(x) = real_myo_sim_heter();
    
    real_sta_sim(x) = real_sta_sim_heter();
end

%% Merge the UDT/PLR performance
data = zeros(4, 20);
data(1, :) = real_simQ_sim(1, :);
data(2, :) = real_furQ_sim(1, :);
data(3, :) = real_sta_sim(1, :);
data(4, :) = real_myo_sim(1, :);