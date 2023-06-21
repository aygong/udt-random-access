function [real_sta_sim] = dynamic_sta_sim(half)
% Simulate the optimal static scheme (realistic)
% Declare global variables
% See main.m
global metric_type

action = 0:1e-2:1;
acSIMU = zeros(1, length(action));

WB = waitbar(0, 'DynamicSta Starting');
for ai = 1:length(action)
    acSIMU(ai) = basic_sta_sim(action(ai), half, false);
    waitbar(ai / length(action), WB, sprintf('DynamicSta: %d / %d', ai, length(action)));
end
close(WB)

% Print the metric
if strcmp(metric_type, 'UDT')
    real_sta_sim = max(acSIMU);
else
    real_sta_sim = min(acSIMU);
end
fprintf("- real_sta_sim = %.6f\n", real_sta_sim);