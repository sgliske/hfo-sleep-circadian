function corrected_times = correct_times(time,acq_time)
%%
% This function corrects start or stop times using acquisition times. The
% start times in epochs don't include the absolute date/time of recording

% Written by SD
% April, 2025

% Inputs:
% time - vector of times corresponding to runs
% acq_time - corresponding acquisition time from lay files


% Apply correction for the specified run
corrected_times = seconds(time) + acq_time;
end