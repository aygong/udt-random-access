function [real_sta_sim] = unsync_sta_sim(offset)
% Simulate the optimal static scheme (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma
global metric_type simu_indept simu_frames

user_index = 1:N;
action = 0:1e-2:1;
acSIMU = zeros(1, length(action));

for ai = 1:length(action)
    SIMU = zeros(1, simu_indept);
    p = action(ai);
    
    parfor SI = 1:simu_indept
        % Run independent numerical experiments
        counter = randi([0, offset], N, 1);
        status = zeros(N, 1);
        
        for si = 1:simu_frames*D
            % Simulate consecutive frames in each experiment
            end_indexes = user_index(counter == 0);
            for i = 1:length(end_indexes)
                n = end_indexes(i);
                counter(n) = D;
                % Simulate the packet arrival
                % status: 0 (inactive), 1 (active)
                status(n) = rand < lambda;
            end
            % Simulate the random access
            access = (rand(N, 1) < p) .* (status > 0);
            if rand < sigma(sum(access)+1)
                succ_index = datasample(user_index(access > 0), 1);
                status(succ_index) = 0;
                SIMU(SI) = SIMU(SI) + gamma(D-counter(succ_index)+1);
            end
            counter = counter - 1;
        end
    end
    
    % Compute the metric
    acSIMU(ai) = metric_computing(SIMU);
end

% Print the metric
if strcmp(metric_type, 'UDT')
    real_sta_sim = max(acSIMU);
else
    real_sta_sim = min(acSIMU);
end
fprintf("- real_sta_sim = %.6f\n", real_sta_sim);