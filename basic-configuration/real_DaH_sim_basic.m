function [real_DaH_sim] = real_DaH_sim_basic()
% Simulate the D&H scheme (realistic)
% https://ieeexplore.ieee.org/abstract/document/8642954
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
    status = zeros(1, N);
    p = 0;
    
    for si = 1:simu_frames*D
        % Simulate consecutive frames in each experiment
        if counter == 0
            counter = D;
            % Simulate the packet arrival
            % status: 0 (inactive), 1 (active)
            status = rand(1, N) < lambda;
            p = 1;
        end
        if sum(status) > 0
            % Simulate the random access
            access = (rand(1, N) < p) .* (status > 0);
            if rand < sigma(sum(access)+1)
                succ_index = datasample(user_index(access > 0), 1);
                status(succ_index) = 0;
                SIMU(SI) = SIMU(SI) + gamma(D-counter+1);
                % ACK received
                p = min(1, p * 2);
            else
                if sum(access) > 0
                    % NACK received
                    p = p / 2;
                end
            end
        end
        counter = counter - 1;
    end
    
end

% Compute the metric
switch metric_type
    case 'UDT'
        real_DaH_sim = sum(SIMU) / simu_indept / simu_frames / D;
	case 'PLR'
        real_DaH_sim = 1 - sum(SIMU) ...
            / simu_indept / simu_frames / dot(initial_belief, state);
    otherwise
        error("Unexpected metric.\n");
end

% Print the metric
fprintf("- real_D&H_sim = %.6f\n", real_DaH_sim);