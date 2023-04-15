clc, clear

%% Declare global variables
% N      : the number of users
% lambda : the packet arrival rate
% D      : the delivery deadline (slots)
% sigma  : the packet success rate
% gamma  : the urgency function
% delta_p: the sampling interval to ...
%          discretize the range of values of p
% delta_a: the sampling interval to ...
%          discretize the range of values of α
global N lambda D sigma gamma delta_p delta_a
% state         : {0,1,...,N}
% num_state     : the cardinality of the set {0,1,...,N}
% initial_belief: the initial activity belief
% action        : {0,Δp,2Δp,...,1}
% num_action    : the cardinality of the set {0,Δp,2Δp,...,1}
% alpha         : {0,Δα,2Δα,...,1}
% num_alpha     : the cardinality of the set {0,Δα,2Δα,...,1}
global state num_state initial_belief action num_action alpha num_alpha
% transF : the state transition function
% rewardF: the reward function
% obserF : the observation function
% qF     : the optimal Q-functions
global transF rewardF obserF qF
% metric_type : the type of the metric
% channel_type: the type of the channel model
% urgency_type: the type of the urgency function
global metric_type channel_type urgency_type
% simu_switch: the simulation switch
% simu_indept: the number of independent numerical experiments
% simu_frames: the number of consecutive frames in each experiment
global simu_switch simu_indept simu_frames

% Set the number of users
N = 50;
% Set the delivery deadline (slots)
D = 5;

% Set the type of the metric: 'UDT' or 'PLR'
% 'UDT': urgency-dependent throughput (UDT)
% 'PLR': packet loss ratio (PLR)
metric_type = 'UDT';

% Set the type of the channel model: 'collision' or 'capture'
% 'collision': collision model
% 'capture'  : SINR-based capture model
channel_type = 'collision';
% Set the packet success rate
sigma = zeros(1, N+1);
switch channel_type
    case 'collision'
        fprintf("|> Use the collision model.\n");
        sigma(2) = 0.95;
    case 'capture'
        % https://ieeexplore.ieee.org/abstract/document/6952516
        fprintf("|> Use the SINR-based capture model.\n");
        nu = 1;
        kappa = 20;
        sigma(2:N+1) = exp(-1)^(nu / kappa) ./ (1 + nu).^(0:N-1);
    otherwise
        error("Unexpected channel model.\n");
end

% Set the type of the urgency function: '-0.1', '0.95', or 'one'
% '-0.1': Γ_t = t^(-0.1)
% '0.95': Γ_t = 0.95^(t-1)
% 'one' : Γ_t = 1
urgency_type = '-0.1';
% Set the urgency function
switch urgency_type
    case '-0.1'
        fprintf("|> Use Γ_t = t^(-0.1).\n");
        gamma = (1:D).^(-0.1);
    case '0.95'
        fprintf("|> Use Γ_t = 0.95^(t-1).\n");
        gamma = 0.95.^(0:D-1);
    case 'one'
        fprintf("|> Use Γ_t = 1.\n");
        gamma = ones(1, D);
    otherwise
        error("Unexpected urgency function.\n");
end

% Set the sampling interval
delta_p = 1e-3;
delta_a = 1e-5;

% Set the simulation parameters
simu_switch = true;
simu_indept = 10;
simu_frames = 1e+6;

%% Return the UDT/PLR performance
addpath('./basic-configuration')
addpath('./unknown-lambda')
addpath('./heterogeneous-lambdas')
addpath('./unsynchronized-traffic')

% system_assumption: the type of the system assumption
% Set the type of the system assumption: 1, 2, 3, or 4
% 1: basic-configuration
% 2: unknown-lambda
% 3: heterogeneous-lambdas
% 4: unsynchronized-traffic
system_assumption = 1;

switch system_assumption
    case 1
        data = run_basic_configuration();
    case 2
        data = run_unknown_lambda();
    case 3
        data = run_heter_lambdas();
    case 4
        data = run_unsync_traffic();
    otherwise
        error("Unexpected system assumption.\n");
end