function [data] = prepping_cyc_data(valid_Time,valid_TimePerStage, patient_ID)
%%
% Function to compute acceptance and prep cyclicity data
% uses both analyzed epochs and qHFOs as inputs. be careful which to use
%

%% loop over state of vigilance combinations
nS = 7;                   % 7 states of vigilance combinations: N1, N2, N3, R, Awake, Overall, NREM
data = cell(1,nS);        % preallocate output

for s = 1:nS

    % Determine data source as per vigilance state
    if (s == 6)    % Overall
        temp = valid_Time;
    elseif s < 6   % individual sleep stage
        temp = valid_TimePerStage(:, s);
    else           % NREM
        temp = [valid_TimePerStage(:,1); valid_TimePerStage(:,2); valid_TimePerStage(:,3)];
    end

    start = cellfun(@(x) x.start,temp,'UniformOutput',false);
    start = vertcat(start{:})/86400;     % seconds to days

    stop = cellfun(@(x) x.stop,temp,'UniformOutput',false);
    stop = vertcat(stop{:})/86400;

    % compute amount of recording for each time it changes
    offset = sum(floor(stop) - floor(start));
    [start,~,I] = unique(rem(start,1));
    start_val = accumarray(I,1);

    [stop,~,I] = unique(rem(stop,1));
    stop_val = accumarray(I,1);

    % determine total number of times each time of day was recorded
    % build raw time & val vectors
    time = [ 0; start; stop; 1];
    val  = [ offset; start_val; -stop_val; -offset ];

    % sort them
    [time,I] = sort(time);
    val = val(I);
    
    [time, ~, ic] = unique(time);
    val = accumarray(ic, val);
    val = cumsum(val);
    assert(val(end) == 0);
    assert(time(end) == 1 );

    % compute piece-wise constant
    acceptance = pwc( time(1:end-1), val(1:end-1), time(end) );

    % store results
    data{s}.acceptance = acceptance;

    %% get qHFO details
    d = getqHFODetails(patient_ID);
    % group HFOs based on vigilance states
    if ( s < 6 )
        I = d.stateOfVigilance == s;
    elseif (s==6)
        I = d.stateOfVigilance >= 1 & d.stateOfVigilance <= 5;
    else
        I = d.stateOfVigilance >= 1 & d.stateOfVigilance <= 3;
    end

    data{s}.hfo_start_time =  mod(days(timeofday(d.startTime(I))), 1);
end

data = cell2mat(data);
% Save data for all patients


end
