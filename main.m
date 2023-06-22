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
% system_assumption: the type of the system assumption
global system_assumption

% Set the number of users
N = 20;
% Set the delivery deadline (slots)
D = 5;

% Set the type of the metric: 'UDT' or 'PLR'
% 'UDT': urgency-dependent throughput (UDT)
% 'PLR': packet loss ratio (PLR)
metric_type = 'UDT';
% Print the metric
switch metric_type
    case 'UDT'
        fprintf("|> Compute the UDT performance.\n");
	case 'PLR'
        fprintf("|> Compute the PLR performance.\n");
    otherwise
        error("Unexpected metric.\n");
end

% Set the type of the channel model: 'collision' or 'capture'
% 'collision': collision model
% 'capture'  : SINR-based capture model
channel_type = 'collision';
% Set the packet success rate
sigma = zeros(1, 1001);
switch channel_type
    case 'collision'
        fprintf("|> Use the collision model.\n");
        sigma(2) = 0.95;
    case 'capture'
        % https://ieeexplore.ieee.org/abstract/document/6952516
        fprintf("|> Use the SINR-based capture model.\n");
        nu = 1;
        kappa = 20;
        sigma(2:end) = exp(-1)^(nu / kappa) ./ (1 + nu).^(0:999);
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

%% Return the UDT/PLR performance
addpath('./basic-configuration')
addpath('./unknown-lambda')
addpath('./heterogeneous-lambdas')
addpath('./unsynchronized-traffic')
addpath('./dynamic-number')

% Set the type of the system assumption
% 'basic-configuration': basic configuration
% 'unknown-lambda': unknown λ
% 'heterogeneous-lambdas': heterogeneous λ_1, λ_2, ..., λ_N
% 'unsynchronized-traffic': unsynchronized periodic traffic
% 'dynamic-number': dynamic N
system_assumption = 'basic-configuration';

switch system_assumption
    case 'basic-configuration'
        fprintf("|> Basic configuration.\n");
        data = run_basic_config();
    case 'unknown-lambda'
        fprintf("|> Unknown λ.\n");
        data = run_unknown_lambda();
    case 'heterogeneous-lambdas'
        fprintf("|> Heterogeneous λ_1, λ_2, ..., λ_N.\n");
        data = run_heter_lambdas();
    case 'unsynchronized-traffic'
        fprintf("|> Unsynchronized periodic traffic.\n");
        data = run_unsync_traffic();
    case 'dynamic-number'
        fprintf("|> Dynamic N.\n");
        data = run_dynamic_number();
    otherwise
        error("Unexpected system assumption.\n");
end