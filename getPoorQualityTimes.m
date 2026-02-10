function [start, stop] = getPoorQualityTimes(event_file)
    %% Function to extract poor-quality data segments
    % Inputs: event_file - Table containing event information
    % Outputs: start - Start times of poor-quality segments
    %          stop  - Stop times of poor-quality segments
    %
    % Written by SD, March 24, 2025

    % Filter rows with poor data quality
    bad_idx = strcmp(event_file.event_category, 'data_quality');
    
    % Extract onset and duration
    start = seconds(event_file.onset(bad_idx) - datetime('2010-01-01T00:00:00'));  % Convert to seconds
    duration = event_file.duration(bad_idx);  % Duration in seconds

    if iscell(duration)
        
        if isempty(duration)
            duration = zeros(0,1);     % empty numeric column vector
        else
            duration = cellfun(@(x) str2double(x), duration,"UniformOutput",true);
            duration = duration(:);
        end
    else
        duration = duration(:);
    end

    % Compute stop times
    stop = start + duration;
end
