function [real_simQ_sim] = unknown_simQ_sim()
% Simulate the simplified QMDP-based policy (realistic)
% Declare global variables
% See main.m
global N lambda D sigma gamma 
global state num_state initial_belief action
global transF obserF qF
global metric_type simu_frames

stateX = repmat(state, N, 1);
NX = ones(N, num_state) * N;
lambdaX = ones(N, num_state);

nf = 1;
num_frames = [];
while nf <= simu_frames
    num_frames = [num_frames, nf]; %#ok<*AGROW>
    nf = nf * 10;
end
simu_repeat = simu_frames ./ num_frames;

user_index = 1:N;
real_simQ_sim = zeros(simu_frames, length(num_frames));

for nf = 1:length(num_frames)
    
    parfor SI = 1:simu_repeat(nf)
        % Run independent numerical experiments
        SIMU = 0;
        counter = 0;
        status = zeros(N, 1);
        static = zeros(N, 1);
        belief = zeros(N, num_state);

        for si = 1:num_frames(nf)*D
            % Simulate consecutive frames in each experiment
            if counter == 0
                counter = D;
                % Simulate the packet arrival
                % status: 0 (inactive), 1 (active)
                status = rand(N, 1) < lambda;
                static = static + status;
                belief = binopdf(stateX, NX, lambdaX .* (static / (floor(si / D) + 1)));
            end
            if sum(status) > 0
                % Determine the value of the transmission probability
                [~, ai_opt] = max(belief * qF(:, :, D-counter+1), [], 2);
                p = action(ai_opt);
                % Simulate the random access
                access = (rand(N, 1) < p') .* (status > 0);
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
                % Update the activity belief
                for n = 1:N
                    belief(n, :) = belief(n, :) * ...
                        (obserF(:, :, obser, ai_opt(n)) .* transF(:, :, ai_opt(n)));
                end
                belief = belief ./ sum(belief, 2);
            end
            counter = counter - 1;
        end
       
        % Compute the metric
        if strcmp(metric_type, 'UDT')
            real_simQ_sim(SI, nf) = SIMU / num_frames(nf) / D;
        else
            real_simQ_sim(SI, nf) = 1 - SIMU / num_frames(nf) / dot(initial_belief, state);
        end
    end
    
    % Print the metric
    fprintf("- log10(num_frames) = %d, real_simQ_sim = %.6f\n", ...
        log10(num_frames(nf)), sum(real_simQ_sim(:, nf) / simu_repeat(nf)));
end

real_simQ_sim = sum(real_simQ_sim, 1) ./ simu_repeat;