function [transF, rewardF, obserF] = function_computing()
% Declare global variables
% See main.m
global sigma
global state num_state action num_action

% Create the state transition function and reward function
transF = zeros(num_state, num_state, num_action);
rewardF = zeros(num_state, num_action);

parfor ai = 1:num_action
    par4TransF = zeros(num_state, num_state);
    eta = zeros(1, num_state);
    p = action(ai);
    for si = 1:num_state
        n = state(si);
        % Compute eta
        eta(si) = dot(sigma(1:si), binopdf(0:n, n, p));
        % Compute the reward function
        rewardF(si, ai) = eta(si);
        % Compute the state transition function
        par4TransF(si, max(1, si-1)) = eta(si);
        par4TransF(si, si) = 1 - eta(si);
    end
    transF(:, :, ai) = par4TransF;
end

% Create the observation function
obserF = zeros(num_state, num_state, 3, num_action);

parfor ai = 1:num_action
    par4obserF = zeros(num_state, num_state, 3);
    eta = zeros(1, num_state);
    p = action(ai);
    for si = 1:num_state
        n = state(si);
        % Compute η
        eta(si) = dot(sigma(1:si), binopdf(0:n, n, p));
        % Compute the observation function
        for sj = 1:si
            switch state(si) - state(sj)
                case 0
                    if eta(si) < 1
                        % No feedback received
                        par4obserF(si, sj, 1) = (1 - p)^n / (1 - eta(si));
                        % NACK received
                        par4obserF(si, sj, 3) = 1 - par4obserF(si, sj, 1);
                    end
                case 1
                    % ACK received
                    par4obserF(si, sj, 2) = 1;
                otherwise
                    continue
            end
        end
    end
    obserF(:, :, :, ai) = par4obserF;
end