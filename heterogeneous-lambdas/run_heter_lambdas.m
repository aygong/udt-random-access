function [data] = run_heter_lambdas()
% Return the UDT/PLR performance
% Declare global variables
% See main.m
global N lambda D delta_p delta_a
global state num_state initial_belief action num_action alpha num_alpha
global transF rewardF obserF qF
global channel_type
global simu_indept simu_frames

% Set the simulation parameters
simu_indept = 1e+3;
simu_frames = 1e+3;

% Set the mean of the packet arrival rate
mean = 0.5 / (N / D);
% Set the halves of the interval length
halves = 0:mean/5:mean;

% Define local variables
X = length(halves);
real_simQ_sim = zeros(1, X);
real_furQ_sim = zeros(1, X);
real_sta_sim = zeros(1, X);
real_myo_sim = zeros(1, X);

% Compute the UDT/PLR performance
state = 0:N;
num_state = length(state);
action = 0:delta_p:1;
num_action = length(action);
alpha = 0:delta_a:1;
num_alpha = length(alpha);

[transF, rewardF, obserF] = function_computing();
[qF, pi_furQ] = QF_computing();

for x = 1:X
    fprintf("\n|> %d / %d: Interval = [%.3f, %.3f]\n", x, X, mean - halves(x), mean + halves(x));
    
    % Generate the packet arrival rates
    lambda = mean + (2 * rand(simu_indept, N) - 1) * halves(x);
    % Compute the joint distributions
    initial_belief = zeros(simu_indept, num_state);
    for SI = 1:simu_indept
        initial_belief(SI, :) = asymmetric_binomial(lambda(SI, :));
    end
    fprintf("|> Finish generating initial beliefs.\n");
    
    real_simQ_sim(x) = heter_simQ_sim();
    
    if strcmp(channel_type, 'collision')
        real_furQ_sim(x) = heter_furQ_sim(pi_furQ);
    end
    
    real_myo_sim(x) = heter_myo_sim();
    
    real_sta_sim(x) = heter_sta_sim();
end

% Merge the results
data = [real_simQ_sim; real_furQ_sim; real_sta_sim; real_myo_sim];