function [real_myo_sim] = basic_myo_sim(half)
% Simulate the myopic policy (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma 
global num_state initial_belief action
global transF rewardF obserF
global simu_indept simu_frames

SIMU = zeros(1, simu_indept);

parfor SI = 1:simu_indept
    % Run independent numerical experiments
    counter = 0;
    R = N;
    user_index = 1:R;
    status = zeros(1, R);
    belief = zeros(1, num_state);
    
    for si = 1:simu_frames*D
        % Simulate consecutive frames in each experiment
        if counter == 0
            counter = D;
            % Return the number of users
            R = randi([N - half, N + half]);
            user_index = 1:R;
            % Simulate the packet arrival
            % status: 0 (inactive), 1 (active)
            status = rand(1, R) < lambda;
            belief = initial_belief;
        end
        if sum(status) > 0
            % Determine the value of the transmission probability
            [~, ai_opt] = max(belief * rewardF);
            p = action(ai_opt);
            % Simulate the random access
            access = (rand(1, R) < p) .* (status > 0);
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
            belief = belief * (obserF(:, :, obser, ai_opt) .* transF(:, :, ai_opt));
            belief = belief / sum(belief);
        end
        counter = counter - 1;
    end
    
end

% Compute the metric
real_myo_sim = metric_computing(SIMU);

% Print the metric
fprintf("- real_myo_sim = %.6f\n", real_myo_sim);