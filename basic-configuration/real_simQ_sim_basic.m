function [real_simQ_sim] = real_simQ_sim_basic()
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
    counter = 0;
    status = zeros(1, N);
    belief = zeros(1, num_state);
    
    for si = 1:simu_frames*D
        % Simulate consecutive frames in each experiment
        if counter == 0
            counter = D;
            % Simulate the packet arrival
            % status: 0 (inactive), 1 (active)
            status = rand(1, N) < lambda;
            belief = initial_belief;
        end
        if sum(status) > 0
            % Determine the value of the transmission probability
            [~, ai_opt] = max(belief * qF(:, :, D-counter+1));
            p = action(ai_opt);
            % Simulate the random access
            access = (rand(1, N) < p) .* (status > 0);
            if rand < sigma(sum(access)+1)
                succ_index = datasample(user_index(access > 0), 1);
                status(succ_index) = 0;
                SIMU(SI) = SIMU(SI) + gamma(D-counter+1);
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
            belief = belief * ...
                (obserF(:, :, obser, ai_opt) .* transF(:, :, ai_opt));
            belief = belief / sum(belief);
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