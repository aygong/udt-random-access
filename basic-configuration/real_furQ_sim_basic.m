function [real_furQ_sim] = real_furQ_sim_basic(pi_furQ)
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
            status = rand(1, N) < lambda;
            M = N;
            a = lambda;
        end
        if sum(status) > 0
            % Determine the value of the transmission probability
            p = pi_furQ{D-counter+1}(N-M+1, round(a/delta_a)+1);
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
    
end

% Compute the metric
switch metric_type
    case 'UDT'
        real_furQ_sim = sum(SIMU) / simu_indept / simu_frames / D;
	case 'PLR'
        real_furQ_sim = 1 - sum(SIMU) ...
            / simu_indept / simu_frames / dot(initial_belief, state);
    otherwise
        error("Unexpected metric.\n");
end

% Print the metric
fprintf("- real_furQ_sim = %.6f\n", real_furQ_sim);