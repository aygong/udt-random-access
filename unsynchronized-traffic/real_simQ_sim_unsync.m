function [real_simQ_sim] = real_simQ_sim_unsync(offset)
% Simulate the simplified QMDP-based policy (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma 
global state num_state initial_belief action
global transF obserF qF
global metric_type simu_indept simu_frames

user_index = 1:N;
SIMU = zeros(1, simu_indept);

parfor SI = 1:simu_indept
    % Run independent numerical experiments
    counter = randi([0, offset], N, 1);
    status = zeros(N, 1);
    belief = zeros(N, num_state);
    
    for si = 1:simu_frames*D
        % Simulate consecutive frames in each experiment
        end_indexes = user_index(counter == 0);
        for i = 1:length(end_indexes)
            n = end_indexes(i);
            counter(n) = D;
            % Simulate the packet arrival
            % status: 0 (inactive), 1 (active)
            status(n) = rand < lambda;
            belief(n, :) = initial_belief;
        end
        % Determine the value of the transmission probability
        active_indexes = user_index(status > 0);
        ai_opt = zeros(N, 1);
        p = zeros(N, 1);
        for i = 1:length(active_indexes)
            n = active_indexes(i);
            [~, ai_opt(n)] = max(belief(n, :) * qF(:, :, D-counter(n)+1));
            p(n) = action(ai_opt(n));
        end
        % Simulate the random access
        access = (rand(N, 1) < p) .* (status > 0);
        if rand < sigma(sum(access)+1)
            succ_index = datasample(user_index(access > 0), 1);
            status(succ_index) = 0;
            SIMU(SI) = SIMU(SI) + gamma(D-counter(succ_index)+1);
            % ACK received
            obser = 2;
        else
            if sum(access) == 0
                % No feedback received
                obser = 1;
            else
                % NACK received
                obser = 3;
            end
        end
        % Update the activity belief
        update_indexes = user_index(status > 0);
        for i = 1:length(update_indexes)
            n = update_indexes(i);
            belief(n, :) = belief(n, :) * ...
                (obserF(:, :, obser, ai_opt(n)) .* transF(:, :, ai_opt(n)));
            belief(n, :) = belief(n, :) / sum(belief(n, :));
        end
        counter = counter - 1;
    end
    
end

% Compute the metric
switch metric_type
    case 'UDT'
        real_simQ_sim = sum(SIMU) / simu_indept / simu_frames / D;
	case 'PLR'
        real_simQ_sim = 1 - sum(SIMU) ...
            / simu_indept / simu_frames / dot(initial_belief, state);
    otherwise
        error("Unexpected metric.\n");
end

% Print the metric
fprintf("- real_simQ_sim = %.6f\n", real_simQ_sim);