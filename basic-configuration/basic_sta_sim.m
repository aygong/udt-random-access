function [real_sta_sim] = basic_sta_sim(p, half, display)
% Simulate the optimal static scheme (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma
global simu_indept simu_frames

SIMU = zeros(1, simu_indept);

parfor SI = 1:simu_indept
    % Run independent numerical experiments
    counter = 0;
    R = N;
    user_index = 1:R;
    status = zeros(1, R);
    
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
        end
        if sum(status) > 0
            % Simulate the random access
            access = (rand(1, R) < p) .* (status > 0);
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
real_sta_sim = metric_computing(SIMU);

% Print the metric
if display
    fprintf("- real_sta_sim = %.6f\n", real_sta_sim);
end