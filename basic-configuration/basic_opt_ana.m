function [idea_opt_ana, pi_opt] = basic_opt_ana()
% Analyze the optimal policy (idealized)
% Declare global variables
% See main.m
global D gamma
global state num_state initial_belief action num_action
global transF rewardF
global metric_type

% Compute the expected total reward from slot 1 to slot D
% U_opt : the value function corresponding to the optimal policy
% pi_opt: the optimal policy
U_opt = zeros(num_state, D+1);
pi_opt = zeros(num_state, D);
actransF = zeros(num_state, num_action);
for t = D:-1:1
    for si = 1:num_state
        actransF(:, :) = transF(si, :, :);
        acU = gamma(t) * rewardF(si, :) + transpose(U_opt(:, t+1)) * actransF;
        [U_opt(si, t), pi_opt(si, t)] = max(acU);
        pi_opt(si, t) = action(pi_opt(si, t));
    end
end

% Compute the metric
switch metric_type
    case 'UDT'
        idea_opt_ana = dot(initial_belief, U_opt(:, 1)) / D;
    case 'PLR'
        idea_opt_ana = 1 - dot(initial_belief, U_opt(:, 1)) / dot(initial_belief, state);
    otherwise
        error("Unexpected metric.\n");
end

% Print the metric
fprintf("+ idea_opt_ana = %.6f\n", idea_opt_ana);