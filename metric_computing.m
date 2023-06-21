function [metric] = metric_computing(SIMU)
% Compute the metric
% Declare global variables
% See main.m
global D
global state initial_belief
global metric_type simu_indept simu_frames

if strcmp(metric_type, 'UDT')
    metric = sum(SIMU) / simu_indept / simu_frames / D;
else
    metric = 1 - sum(SIMU) / simu_indept / simu_frames / dot(initial_belief, state);
end

end

