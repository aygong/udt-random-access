function [qF, pi_furQ] = QF_computing(ch_type)
% Compute the Q-functions
% Declare global variables
% See main.m
global D gamma
global state num_state action num_action alpha num_alpha
global transF rewardF

% Compute the myopic policy
pi_myo = zeros(1, num_state);
for si = 1:num_state
    [~, pi_myo(si)] = max(rewardF(si, :));
end

% Compute the expected total reward from slot 1 to slot D
U_myo = zeros(num_state, D+1);
for t = D:-1:1
    for si = 1:num_state
        U_myo(si, t) = gamma(t) * rewardF(si, pi_myo(si)) ...
            + transF(si, :, pi_myo(si)) * U_myo(:, t+1);
    end
end

% Compute the optimal Q-functions
qF = zeros(num_state, num_action, D);
for t = 1:D
    for ai = 1:num_action
        qF(:, ai, t) = rewardF(:, ai) + transF(:, :, ai) * U_myo(:, t+1);
    end
end

% Compute the further simplified QMDP-based policy
pi_furQ = {};
if strcmp(ch_type, 'collision')
    for t = 1:D
        pi_furQ = [pi_furQ, zeros(t, num_alpha)];
        for si = num_state:-1:max(1, num_state-t+1)
            M = state(si);
            par4pi = zeros(1, num_alpha);
            parfor fi = 1:num_alpha
                f = alpha(fi);
                [~, ai_opt] = max(binopdf(0:M, M, f) * qF(1:M+1, :, t));
                par4pi(fi) = action(ai_opt);
            end
            pi_furQ{t}(num_state-si+1, :) = par4pi;
        end
    end
end