function times = getVigilanceStates(event_file)
    %% Function to extract sleep stage times from event data
    % Inputs: event_file - Table containing event information
    % Outputs: times - Struct array (6 stages) with start/stop times in SECONDS
    %
    % Sleep Stages:
    % 1: N1 (Stage 1 sleep)
    % 2: N2 (Stage 2 sleep)
    % 3: N3 (Stage 3 sleep, deep sleep)
    % 4: REM sleep
    % 5: Wake
    % 6: Unknown
    %
    % Written by SD, March 24, 2025

    %% Initialize output
    times = repmat(struct('start', [], 'stop', []), 6, 1);

    %% Define sleep stage mapping
    sleepStages = {'N1', 'N2', 'N3', 'REM', 'wake', 'unknown'};

    %% Filter only vigilance events
    is_sleep_event = strcmp(event_file.event_category, 'vigilance');
    sleep_events = event_file(is_sleep_event, :);

    %% Loop through sleep stages
    for i = 1:6
        % Get events of this stage
        stage_idx = strcmp(sleep_events.event_type, sleepStages{i});
        stage_events = sleep_events(stage_idx, :);

        if isempty(stage_events)
            continue; % Skip if no events for this stage
        end

        % Convert onset to seconds relative to first event
        start_times = seconds(stage_events.onset - datetime('2010-01-01T00:00:00'));
        stop_times = start_times + stage_events.duration; 

        % Store in struct
        times(i).start = start_times;
        times(i).stop = stop_times;
    end
end
