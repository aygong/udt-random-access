function [real_DaH_ana] = real_DaH_ana_basic()
% Simulate the D&H scheme (idealized)
% https://ieeexplore.ieee.org/abstract/document/8642954
% Declare global variables
% See main.m
global N D sigma
global state initial_belief

aver_success = zeros(1, N+1);
for n = 1:N
    transF = zeros(n*(D+1)+D, n*(D+1)+D);
    for i = 0:(n-1)
        for m1 = 1:D
            p = 0.5^(m1 - 1);
            % Case: ACK received
            transF(i*(D+1)+m1, (i+1)*(D+1)+max(1, m1-1)) = ...
                dot(sigma(2:n-i+1), binopdf(1:n-i, n-i, p));
            % Case: No feedback received
            transF(i*(D+1)+m1, i*(D+1)+m1) = (1 - p)^(n - i);
            % Case: NACK received
            transF(i*(D+1)+m1, i*(D+1)+(m1+1)) = 1 - ...
                transF(i*(D+1)+m1, (i+1)*(D+1)+max(1, m1-1)) - ...
                transF(i*(D+1)+m1, i*(D+1)+m1);
        end
    end
    
    % Compute the canonical form of the transition matrix
    Q = transF(1:n*(D+1), 1:n*(D+1));
    Y = transF(1:n*(D+1), (n*(D+1)+1):(n*(D+1)+D));
    Q1 = Q^D;
    
    % Compute the expected number of successful packets
    alpha = zeros(1, n);
    for i = 1:n-1
        alpha(i) = sum(Q1(1, (i*(D+1)+1):(i+1)*(D+1)));
    end
    for k = 0:D-1
        Q2 = Q^k * Y;
        alpha(n) = alpha(n) + sum(Q2(1, 1:D));
    end
    aver_success(n+1) = (1:n) * alpha';
end

% Compute the metric
real_DaH_ana = 1 - ...
    dot(initial_belief, aver_success) / dot(initial_belief, state);

% Print the metric
fprintf("+ real_D&H_ana = %.6f\n", real_DaH_ana);