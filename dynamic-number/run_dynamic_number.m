function [data] = run_dynamic_number()
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
simu_frames = 1e+5;

% Set the halves of the interval length
halves = 0:N/5:N;

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
[~, pi_furQ] = QF_computing(channel_type);

for x = 1:X
    fprintf("\n|> %d / %d: Interval = [%d, %d]\n", x, X, N - halves(x), N + halves(x));
    
    state = 0:(N+halves(x));
    num_state = length(state);
    
    [transF, rewardF, obserF] = function_computing();
    [qF, ~] = QF_computing(channel_type);
    
    % Compute the mixture distribution
    initial_belief = zeros(1, num_state);
    for R = N-halves(x):N+halves(x)
        initial_belief(1:R+1) = initial_belief(1:R+1) + binopdf(0:R, R, lambda) / (2 * halves(x) + 1);
    end
    
    real_simQ_sim(x) = basic_simQ_sim(halves(x));
    
    if strcmp(channel_type, 'collision')
        real_furQ_sim(x) = basic_furQ_sim(pi_furQ, halves(x));
    end
    
    real_myo_sim(x) = basic_myo_sim(halves(x));
    
    real_sta_sim(x) = dynamic_sta_sim(halves(x));
end

% Merge the results
data = [real_simQ_sim; real_furQ_sim; real_sta_sim; real_myo_sim];