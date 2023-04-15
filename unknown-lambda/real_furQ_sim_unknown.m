function [real_furQ_sim] = real_furQ_sim_unknown(pi_furQ)
% Simulate the further simplified QMDP-based policy (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma delta_a
global state initial_belief
global metric_type simu_frames

nf = 1;
num_frames = [];
while nf <= simu_frames
    num_frames = [num_frames, nf]; %#ok<*AGROW>
    nf = nf * 10;
end
simu_repeat = simu_frames ./ num_frames;

user_index = 1:N;
real_furQ_sim = zeros(simu_frames, length(num_frames));

for nf = 1:length(num_frames)
    
    for SI = 1:simu_repeat(nf)
        % Run independent numerical experiments
        SIMU = 0;
        counter = 0;
        status = zeros(N, 1);
        static = zeros(N, 1);
        M = zeros(N, 1);
        a = zeros(N, 1);

        for si = 1:num_frames(nf)*D
            % Simulate consecutive frames in each experiment
            if counter == 0
                counter = D;
                % Simulate the packet arrival
                % status: 0 (inactive), 1 (active)
                status = rand(N, 1) < lambda;
                static = static + status;
                M = ones(N, 1) * N;
                a = static / (floor(si / D) + 1);
            end
            if sum(status) > 0
                % Determine the value of the transmission probability
                p = pi_furQ{D-counter+1}(N-M+1, round(a/delta_a)+1);
                % Simulate the random access
                access = (rand(N, 1) < p(1, :)') .* (status > 0);
                if rand < sigma(sum(access)+1)
                    succ_index = datasample(user_index(access > 0), 1);
                    status(succ_index) = 0;
                    SIMU = SIMU + gamma(D-counter+1);
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
                for n = 1:N
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
            end
            counter = counter - 1;
        end
       
        % Compute the metric
        switch metric_type
            case 'UDT'
                real_furQ_sim(SI, nf) = SIMU / num_frames(nf) / D;
            case 'PLR'
                real_furQ_sim(SI, nf) = 1 - ...
                SIMU / num_frames(nf) / dot(initial_belief, state);
            otherwise
                error("Unexpected metric.\n");
        end
    end
    
    % Print the metric
    fprintf("- log10(num_frames) = %d, real_furQ_sim = %.6f\n", ...
        log10(num_frames(nf)), sum(real_furQ_sim(:, nf) / simu_repeat(nf)));
end

real_furQ_sim = sum(real_furQ_sim, 1) ./ simu_repeat;