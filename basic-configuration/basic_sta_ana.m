function [real_sta_ana, pi_sta] = basic_sta_ana()
% Analyze the optimal static scheme (realistic)
% Declare global variables
% See main.m
global D gamma
global state initial_belief action num_action
global transF rewardF
global metric_type

% Compute the total expected reward from slot 1 to slot D
V_sta = zeros(1, num_action);
for ai = 1:num_action % ai - the index of the action
    belief = initial_belief;
    for t = 1:D
        V_sta(ai) = V_sta(ai) + gamma(t) * dot(belief, rewardF(:, ai));
        belief = belief * transF(:, :, ai);
    end
end

% Compute an optimal fixed and identical transmission probability
[real_sta_ana, pi_sta] = max(V_sta);
pi_sta = action(pi_sta);

% Compute the metric
switch metric_type
    case 'UDT'
        real_sta_ana = real_sta_ana / D;
	case 'PLR'
        real_sta_ana = 1 - real_sta_ana / dot(initial_belief, state);
    otherwise
        error("Unexpected metric.\n");
end

% Print the metric
fprintf("+ real_sta_ana = %.6f\n", real_sta_ana);