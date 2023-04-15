function [real_furQ_sim] = real_furQ_sim_heter(pi_furQ)
% Simulate the further simplified QMDP-based policy (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma delta_a
global state initial_belief
global metric_type simu_indept simu_frames

user_index = 1:N;
SIMU = zeros(1, simu_indept);

parfor SI = 1:simu_indept
    % Run independent numerical experiments
    simu = 0;
    counter = 0;
    status = zeros(1, N);
    M = 0;
    a = 0;
    
    for si = 1:simu_frames*D
        % Simulate consecutive frames in each experiment
        if counter == 0
            counter = D;
            % Simulate the packet arrival
            % status: 0 (inactive), 1 (active)
            status = rand(1, N) < lambda(SI, :);
            M = N;
            a = mean(lambda(SI, :));
        end
        if sum(status) > 0
            % Determine the value of the transmission probability
            p = pi_furQ{D-counter+1}(N-M+1, round(a/delta_a)+1);
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
            % Update the approximation on the activity belief
            switch obser
                case 1 
                    % No feedback received
                    MDash = M;
                    aDash = (a - a * p) / (1 - a * p);
                case 2 
                    % ACK received
                    MDash = M - 1;
                    if M > 1
                        aDash = (a - a * p) / (1 - a * p);
                    else
                        aDash = 0;
                    end
                otherwise
                    % NACK received
                    MDash = M;
                    if a * p < 1
                        aDash = ...
                            a - sigma(2) * a * p * (1 - a * p)^(M - 2) ...
                            * (M * a - M * a * p - a + 1) ...
                            - (a - a * p) * (1 - a * p)^(M - 1);
                        aDash = aDash / (1 - (1 - a * p)^M ...
                            - sigma(2) * M * a * p * (1 - a * p)^(M - 1));
                    else
                        aDash = 1;
                    end
            end
            M = MDash;
            a = aDash;
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
real_furQ_sim = sum(SIMU) / simu_indept;
fprintf("- real_furQ_sim = %.6f\n", real_furQ_sim);