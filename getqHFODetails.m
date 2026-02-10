function d = getqHFODetails(patient_ID)
%%
% Function to get qHFO details for all runs
% Uses qHFOs as inputs
% Written by Das, April 2025
%

%% Define path and input data
addpath('U:\shared\database\ieeg-UM\code\matlab');
addpath('U:\shared\users\sdas\2025\Code\HFOs_cyclicity');

% Base directory where all rawdata is stored
raw_data_path = 'U:\shared\database\ieeg-UM\rawdata';
% path where h5 files are stored
glap_path = 'U:\shared\database\ieeg-UM\derivatives\glap-h5\qHFO_v3.1_Staba_updated';

% Standardize patient ID to include 'sub-'
if ~startsWith(patient_ID, 'sub-')
    pt_ID = ['sub-' patient_ID];
end

% Detect session
ses_dir = dir(fullfile(raw_data_path, pt_ID, 'ses-ieeg*'));
if isempty(ses_dir)
    error('No ses-ieeg* directory found for %s', pt_ID);
end
session = ses_dir(1).name;  % e.g., 'ses-ieeg01' or 'ses-ieeg02'

% lay file for acq time
lay_file_path = fullfile(raw_data_path,pt_ID, session, 'ieeg', ...
   [pt_ID '_' session '_scans.tsv']);
lay_file_scans = readtable(lay_file_path, 'FileType', 'delimitedtext');
%% Get qHFOs for all runs
patient_files = dir(fullfile(glap_path, [pt_ID '_' session '_task-all_*_glap-qHFO_v3.1_Staba_updated.h5']));

% Initialize storage
start_time = [];
stop_time = [];
vigilance = [];

for i = 1:length(patient_files)
    run_str = regexp(patient_files(i).name, 'run-(\d+)', 'tokens');
    run_num = str2double(run_str{1}{1});  % Extract run number

    file = fullfile(glap_path, patient_files(i).name);

    try
        info = h5info(file);
        group_names = {info.Groups.Name};
        if any(strcmp(group_names, '/qHFO_v3'))
            % Match lay file by run number
            match_row = contains(lay_file_scans.filename, sprintf('run-%02d', run_num));
            if ~any(match_row)
                warning(['Run ' num2str(run_num) ' not found in scans.tsv, skipping.']);
                continue;
            end
            acq_time = lay_file_scans.acq_time(match_row);

            % Load the data file
            qhfo_data = load_glap_h5(file, 'qHFO_v3');

            % Extract fields
            start = qhfo_data.qHFO_v3.start_time;
            stop = qhfo_data.qHFO_v3.stop_time;

            each_vigilance = qhfo_data.qHFO_v3.vigilance;

            % Correct times
            corrected_start = correct_times(start, acq_time);
            corrected_stop = correct_times(stop, acq_time);

            % Append to overall lists
            start_time = [start_time; corrected_start];
            stop_time = [stop_time; corrected_stop];
            vigilance = [vigilance; each_vigilance];

        end
    catch ME
        warning(['Could not process file: ' file ', skipping.']);
        disp(ME.message);
        continue
    end
end


% Output structured data
d = struct();
d.startTime = start_time;
d.stopTime = stop_time;
d.stateOfVigilance = vigilance;


end