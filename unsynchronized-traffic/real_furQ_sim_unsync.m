function [real_furQ_sim] = real_furQ_sim_unsync(pi_furQ, offset)
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
    counter = randi([0, offset], N, 1);
    status = zeros(N, 1);
    M = zeros(N, 1);
    a = zeros(N, 1);
    
    for si = 1:simu_frames*D
        % Simulate consecutive frames in each experiment
        end_indexes = user_index(counter == 0);
        for i = 1:length(end_indexes)
            n = end_indexes(i);
            counter(n) = D;
            % Simulate the packet arrival
            % status: 0 (inactive), 1 (active)
            status(n) = rand < lambda;
            M(n) = N;
            a(n) = lambda;
        end
        % Determine the value of the transmission probability
        active_indexes = user_index(status > 0);
        p = zeros(N, 1);
        for i = 1:length(active_indexes)
            n = active_indexes(i);
            p(n) = pi_furQ{D-counter(n)+1}(N-M(n)+1, round(a(n)/delta_a)+1);
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
        % Update the approximation on the activity belief
        update_indexes = user_index(status > 0);
        for i = 1:length(update_indexes)
            n = update_indexes(i);
            switch obser
                case 1 
                    % No feedback received
                    MDash = M(n);
                    aDash = (a(n) - a(n) * p(n)) / (1 - a(n) * p(n));
                case 2 
                    % ACK received
                    MDash = M(n) - 1;
                    if M(n) > 1
                        aDash = (a(n) - a(n) * p(n)) / (1 - a(n) * p(n));
                    else
                        aDash = 0;
                    end
                otherwise
                    % NACK received
                    MDash = M(n);
                    if a(n) * p(n) < 1
                        aDash = ...
                            a(n) - sigma(2) * a(n) * p(n) * (1 - a(n) * p(n))^(M(n) - 2) ...
                            * (M(n) * a(n) - M(n) * a(n) * p(n) - a(n) + 1) ...
                            - (a(n) - a(n) * p(n)) * (1 - a(n) * p(n))^(M(n) - 1);
                        aDash = aDash / (1 - (1 - a(n) * p(n))^M(n) ...
                            - sigma(2) * M(n) * a(n) * p(n) * (1 - a(n) * p(n))^(M(n) - 1));
                    else
                        aDash = 1;
                    end
            end
            M(n) = MDash;
            a(n) = min(1, max(0, aDash));
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