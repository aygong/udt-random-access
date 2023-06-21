function [real_sta_sim] = heter_sta_sim()
% Simulate the optimal static scheme (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma
global state initial_belief
global metric_type simu_indept simu_frames

user_index = 1:N;
action = 0:1e-2:1;
acSIMU = zeros(1, length(action));

for ai = 1:length(action)
    SIMU = zeros(1, simu_indept);
    p = action(ai);
    
    parfor SI = 1:simu_indept
        % Run independent numerical experiments
        simu = 0;
        counter = 0;
        status = zeros(1, N);

        for si = 1:simu_frames*D
            % Simulate consecutive frames in each experiment
            if counter == 0
                counter = D;
                % Simulate the packet arrival
                % status: 0 (inactive), 1 (active)
                status = rand(1, N) < lambda(SI, :);
            end
            if sum(status) > 0
                % Simulate the random access
                access = (rand(1, N) < p) .* (status > 0);
                if rand < sigma(sum(access)+1)
                    succ_index = datasample(user_index(access > 0), 1);
                    status(succ_index) = 0;
                    simu = simu + gamma(D-counter+1);
                end
            end
            counter = counter - 1;
        end
        
        % Compute the metric
        if strcmp(metric_type, 'UDT')
            SIMU(SI) = simu / simu_frames / D;
        else
            SIMU(SI) = 1 - simu / simu_frames / dot(initial_belief(SI, :), state);
        end
    end
    
    acSIMU(ai) = sum(SIMU) / simu_indept;
end

% Print the metric
if strcmp(metric_type, 'UDT')
    real_sta_sim = max(acSIMU);
else
    real_sta_sim = min(acSIMU);
end
fprintf("- real_sta_sim = %.6f\n", real_sta_sim);