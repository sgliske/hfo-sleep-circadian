function [szTimes, type, duration] = load_seizureTimes(event_file)
%% Extract clinical-seizure times from events table
%   • returns times in *seconds* from 2010-01-01 00:00:00
%   • replaces 'n/a' (or empty cell) with 300 s
%   Written by Srijita, updated June-2025
%
% Outputs
%   szTimes  –  [ N×2 ]  [start stop]   (seconds)
%   type     –  char(N,1)  all 's'      (clinical seizures)
%   duration –  [ N×1 ]  numeric seconds

% ------------------------------------------------------------------------
isSz = strcmp(event_file.event_category,'seizure') & ...
       strcmp(event_file.event_type ,'clinical');

if ~any(isSz)          % === no seizures recorded ========================
    szTimes  = zeros(0,2);
    type     = char(zeros(0,1));
    duration = zeros(0,1);
    return
end

% --- onset (numeric seconds) -------------------------------------------
onset_sec = seconds(event_file.onset(isSz) ...
           - datetime('2010-01-01T00:00:00'));

% --- duration ----------------------------------------------------------
raw_dur = event_file.duration(isSz);

if isnumeric(raw_dur)                           % already numeric column
    duration = str2double(raw_dur);

elseif iscell(raw_dur)                          % cell column
    duration = zeros(numel(raw_dur),1);
    for k = 1:numel(raw_dur)
        d = raw_dur{k};

        if isempty(d) || (ischar(d) && strcmpi(d,'n/a'))
            duration(k) = 300;                  % default to 5 min
        else                                    % numeric in cell or char-num
            duration(k) = str2double(d);
        end
    end
else
    error('Unexpected datatype in duration column: %s', class(raw_dur));
end

% --- stop --------------------------------------------------------------
stop_sec = onset_sec + duration;

% --- outputs -----------------------------------------------------------
szTimes = [onset_sec, stop_sec];
type    = repmat('s', numel(onset_sec), 1);
end
