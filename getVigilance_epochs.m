function epochs_data = getVigilance_epochs(ID)     
%%
% Function to get the state of vigilance corresponding to analyzed epochs (preprocessed iEEG data)
% Uses analyzed epochs as input
% Input:
%   ID - String: 'all' to process all patients, or 'umich****' for a specific ID.
% Written by Das
% Modified November 2025

%% Define paths
addpath('U:\shared\database\ieeg-UM\code\matlab');          % add path where assistive matlab functions are stored
addpath('U:\shared\users\sdas\2025\Code\HFOs_cyclicity');

% Database paths
raw_data_path = 'U:\shared\database\ieeg-UM\rawdata';
glap_path = 'U:\shared\database\ieeg-UM\derivatives\glap-h5\qHFO_v3.1_Staba_updated';   % path where h5 files are stored

%% Patient selection & filtering
raw_data_dir = dir(raw_data_path);
raw_data_dir = {raw_data_dir([raw_data_dir.isdir]).name};
J = contains(raw_data_dir, 'sub');
patients = raw_data_dir(J);

% Limit to only patients with qHFO data up to umich0136
patients = patients(cellfun(@(x) str2double(extractAfter(x, 'sub-umich')) <= 136, patients));

bad_pts = {'umich0039','umich0053', 'umich0120'};   % exclude patients with bad data: these patients had daylight savings time change

if strcmpi(ID, 'all')
    patient_list = patients;
else
    if ~startsWith(ID, 'sub-')
        ID = ['sub-' ID];
    end
    patient_list = {ID};
end

% Exclude bad patients
mask = true(size(patient_list));
for k = 1:numel(bad_pts)
    bad = bad_pts{k};
    % If patient_list entries contain that bad ID (with or without 'sub-')
    mask = mask & ~contains(patient_list, bad);
end
patient_list = patient_list(mask);

%% Loop through all patients
epochs_data = struct();

for pIdx = 1:length(patient_list)
    tic
    patient = patient_list{pIdx};
    patient_ID = erase(patient, 'sub-');

    fprintf('Processing %s\n', patient);

    % Detect session
    ses_dir = dir(fullfile(raw_data_path, patient, 'ses-ieeg*'));
    if isempty(ses_dir)
        error('No ses-ieeg* directory found for %s', patient);
    end
    session = ses_dir(1).name;  % e.g., 'ses-ieeg01' or 'ses-ieeg02'

    %% Construct file paths
    % Read event and scan files for timing synchronization
    event_file_path = fullfile(raw_data_path, patient, session, 'ieeg', [patient '_' session '_events.tsv']);
    event_file = readtable(event_file_path, 'FileType', 'delimitedtext', 'DatetimeType', 'text');

    % Handle inconsistent millisecond formats
    onset_str = event_file.onset;
    onset_dt = NaT(size(onset_str));
    for i = 1:length(onset_str)
        if contains(onset_str{i}, '.')
            onset_dt(i) = datetime(onset_str{i}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS');
        else
            onset_dt(i) = datetime(onset_str{i}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
        end
    end
    onset_dt.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSS';
    event_file.onset = onset_dt;

    lay_file_path = fullfile(raw_data_path, patient, session, 'ieeg', [patient '_' session '_scans.tsv']);
    lay_file_scans = readtable(lay_file_path, 'FileType', 'delimitedtext');

    %% Get epochs from all runs
    patient_files = dir(fullfile(glap_path, [patient '_' session '_task-all_*_glap-qHFO_v3.1_Staba_updated.h5']));
    epochs.start_time = [];
    epochs.stop_time = [];
    epochs.chanIdx = [];

    for i = 1:length(patient_files)
        file_template = fullfile(glap_path, patient_files(i).name);
        info = h5info(file_template);

        % Extract Group Names
        groupNames = {info.Groups.Name};

        % Check if analyzedEpochs is present or not
        if ~any(strcmp(groupNames, '/analyzedEpochs'))
            fprintf('Missing analyzedEpochs in %s. Skipping.\n', file_template);
            continue
        end

        epochs_struct = load_glap_h5(file_template, 'analyzedEpochs');
        if isempty(epochs_struct)|| ~isfield(epochs_struct,'analyzedEpochs')
            fprintf('Missing analyzedEpochs in %s. Skipping.\n', file_template);
            continue
        end

        start_time = epochs_struct.analyzedEpochs.start_time;
        stop_time = epochs_struct.analyzedEpochs.stop_time;
        acq_time = lay_file_scans.acq_time(i);             %the absolute time when the run started

        corrected_start_times = correct_times(start_time, acq_time);
        corrected_stop_times = correct_times(stop_time, acq_time);

        epochs.start_time = [epochs.start_time; corrected_start_times];
        epochs.stop_time = [epochs.stop_time; corrected_stop_times];
        epochs.chanIdx = [epochs.chanIdx; epochs_struct.analyzedEpochs.chanIdx];
    end
    
    % Convert to relative seconds
    epochs.start_time_sec = seconds(epochs.start_time - min(epochs.start_time));
    epochs.stop_time_sec = seconds(epochs.stop_time - min(epochs.start_time));

    %% Analyzed epochs per channel and artifact removal
    tbl = get_electrode_channel_table(patient_ID);
    nChan = find((strcmpi(tbl.type, 'seeg') | strcmpi(tbl.type, 'ecog')) & strcmpi(tbl.status, 'good'), 1, 'last');   % channel validation
    valid_Time = cell(nChan, 1);

    for c = 1:nChan
        I = epochs.chanIdx == c;
        if any(I)
            valid_Time{c} = InfDimBool(epochs.start_time_sec(I), epochs.stop_time_sec(I));
        else
            valid_Time{c} = InfDimBool();
        end
    end

    % Remove poor quality times
    [poorQstart, poorQstop] = getPoorQualityTimes(event_file);
    if any(poorQstart)
        for c = 1:nChan
            valid_Time{c}.setFalse(poorQstart, poorQstop);
        end
    end

    % Exclude Ictal Periods (+/- 30 min buffer for interictal purity)
    [szTimes, szType, duration] = load_seizureTimes(event_file);
    I = szType == 's';
    if any(I)
        szStart = szTimes(I, 1);
        szStop = szTimes(I, 2);
        I = szStop == szStart;
        szStop(I) = szStart(I) + duration(I);
        szStart = szStart - 1800;
        szStop = szStop + 1800;
        for c = 1:nChan
            valid_Time{c}.setFalse(szStart, szStop);
        end
    end

    %% Extract per vigilance state
    sleepTimes = getVigilanceStates(event_file);
    valid_TimePerStage = cell(nChan, 5);

    for c = 1:nChan
        [validStart, validStop] = valid_Time{c}.getRange();
        for s = 1:5            % N1, N2, N3, REM, awake
            valid_TimePerStage{c, s} = InfDimBool(validStart, validStop);
            valid_TimePerStage{c, s}.and(sleepTimes(s));
        end
    end

    %% Store results
    epochs_data.(patient_ID).valid_Time = valid_Time;
    epochs_data.(patient_ID).valid_TimePerStage = valid_TimePerStage;

    toc
end

% Save for all patients
save('U:\shared\users\sdas\2025\Code\HFOs_cyclicity\results\epochs_data.mat','-struct','epochs_data');

end
