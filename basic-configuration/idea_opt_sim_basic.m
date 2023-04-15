function [idea_opt_sim] = idea_opt_sim_basic(pi_opt)
% Simulate the optimal policy (idealized)
% Declare global variables
% See main.m
global N lambda D sigma gamma
global state initial_belief
global metric_type simu_indept simu_frames

user_index = 1:N;
SIMU = zeros(1, simu_indept);

parfor SI = 1:simu_indept
    % Run independent numerical experiments
    counter = 0;
    status = zeros(1, N)
    
    for si = 1:simu_frames*D
        % Simulate consecutive frames in each experiment
        if counter == 0
            counter = D;
            % Simulate the packet arrival
            % status: 0 (inactive), 1 (active)
            status = rand(1, N) < lambda;
        end
        if sum(status) > 0
            % Determine the value of the transmission probability
            p = pi_opt(sum(status)+1, D-counter+1);
            % Simulate the random access
            access = (rand(1, N) < p) .* (status > 0);
            if rand < sigma(sum(access)+1)
                succ_index = datasample(user_index(access > 0), 1);
                status(succ_index) = 0;
                SIMU(SI) = SIMU(SI) + gamma(D-counter+1);
            end
        end
        counter = counter - 1;
    end
    
end

% Compute the metric
switch metric_type
    case 'UDT'
        idea_opt_sim = sum(SIMU) / simu_indept / simu_frames / D;
	case 'PLR'
        idea_opt_sim = 1 - sum(SIMU) ...
            / simu_indept / simu_frames / dot(initial_belief, state);
    otherwise
        error("Unexpected metric.\n");
end

% Print the metric
fprintf("- idea_opt_sim = %.6f\n", idea_opt_sim);