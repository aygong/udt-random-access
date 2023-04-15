function [real_myo_sim] = real_myo_sim_heter()
% Simulate the myopic policy (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma 
global state num_state initial_belief action
global transF rewardF obserF
global metric_type simu_indept simu_frames

user_index = 1:N;
SIMU = zeros(1, simu_indept);

parfor SI = 1:simu_indept
    % Run independent numerical experiments
    simu = 0;
    counter = 0;
    status = zeros(1, N);
    belief = zeros(1, num_state);
    
    for si = 1:simu_frames*D
        % Simulate consecutive frames in each experiment
        if counter == 0
            counter = D;
            % Simulate the packet arrival
            % status: 0 (inactive), 1 (active)
            status = rand(1, N) < lambda(SI, :);
            belief = initial_belief(SI, :);
        end
        if sum(status) > 0
            % Determine the value of the transmission probability
            [~, ai_opt] = max(belief * rewardF);
            p = action(ai_opt);
            % Simulate the random access
            access = (rand(1, N) < p) .* (status > 0);
            if rand < sigma(sum(access)+1)
                succ_index = datasample(user_index(access > 0), 1);
                status(succ_index) = 0;
                simu = simu + gamma(D-counter+1);
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
    
    % Compute the metric
    switch metric_type
        case 'UDT'
            SIMU(SI) = simu / simu_frames / D;
        case 'PLR'
            SIMU(SI) = 1 - ...
                simu / simu_frames / dot(initial_belief(SI, :), state);
        otherwise
            error("Unexpected metric.\n");
    end
end

% Print the metric
real_myo_sim = sum(SIMU) / simu_indept;
fprintf("- real_myo_sim = %.6f\n", real_myo_sim);