function results_all = compute_cyclicity_rate(ID)
% Calculates HFO cyclicity rate for all patients in epochs_data structure.
%
% This function uses an 'unfolding' approach to account for recording biases
% and calculates the amplitude (amp) and phase (zenith) of HFOs across different 
% vigilance states.

% Written by SD, August 2025

%% Load data

epochs_data = load("U:\shared\users\sdas\2025\Code\HFOs_cyclicity\results\epochs_data.mat");
%epochs_data = load(fullfile("U:\shared\users\sdas\2025\Code\HFOs_cyclicity",sprintf('epochs_data_%s.mat',ID)));
%epochs_data = epochs_data.epochs_data;

%% Initialize parameters
N_smearing = 100000;
N_null     = 1000;

results_all = struct();
prepped_all = struct();

%--- pick patients to run ---%
allIDs = fieldnames(epochs_data);
if nargin<1 || strcmpi(ID,'all')
    patient_list = allIDs;
    singleRun = false;
else
    % ensure they gave it without 'sub-'
    if startsWith(ID,'sub-')
        ID = extractAfter(ID,'sub-');
    end
    if ~ismember(ID, allIDs)
        error('Patient "%s" not found in epochs_data.', ID);
    end
    patient_list = {ID};
    singleRun = true;
end

%% Loop through patients
for p = 1:numel(patient_list)
    
    tic
    patient_ID = patient_list{p};
    fprintf('Computing cyclicity rate for %s\n', patient_ID);

    % try
        valid_Time = epochs_data.(patient_ID).valid_Time;
        valid_TimePerStage = epochs_data.(patient_ID).valid_TimePerStage;

        % Prepare the data for this patient
        fprintf('Prepping cyclicity data for %s',patient_ID);
        tic
        data = prepping_cyc_data(valid_Time, valid_TimePerStage, patient_ID);
        toc
        prepped_all.(patient_ID) = data;

        nS = length(data);
        %results = struct();
        results = repmat(struct('amp',nan,'zenith',nan,'p',nan,'N_hfos',nan), nS, 1);

        for s = 1:nS     %% 7 states of vigilance combinations: N1, N2, N3, R, Awake, Overall, NREM
            tic
            N_hfos = length(data(s).hfo_start_time);
            fprintf('%s Stage %d N_hfo: %d\n', patient_ID, s, N_hfos);

            if N_hfos < 100
                results(s).amp = nan;
                results(s).zenith = nan;
                results(s).p = nan;
                results(s).N_hfos = N_hfos;
                continue;
            end

            % Unfolding
            obj = unfolding(1);
            phi_sim = data(s).acceptance.genData(N_smearing) / data(s).acceptance.max_x * 2*pi;
            obj.compute_smearing_matrix(phi_sim);

            % Unfold HFOs
            obj.unfold(data(s).hfo_start_time * 2*pi);

            results(s).amp = obj.gamma(1);
            results(s).zenith = obj.gamma(2);
            results(s).amp_uncorr = obj.gamma_uncor(1);
            results(s).zenith_uncorr= obj.gamma_uncor(2);

            % Significance
            results(s).N_hfos = N_hfos;
            a = zeros(N_null, 1);
            for k = 1:N_null
                phi_null = data(s).acceptance.genData(N_hfos) / data(s).acceptance.max_x * 2*pi;
                obj.unfold(phi_null);
                a(k) = obj.gamma(1);
            end
            results(s).p = mean(results(s).amp < a);
            toc
        end

        results_all.(patient_ID) = results;

    % catch ME
    %     fprintf('Skipping %s due to error: %s\n', patient_ID, ME.message);
    %     continue;
    % end
    toc
end

%% Save
if singleRun
    % per-patient files
    fn1 = sprintf('prepped_cyclicity_%s.mat',    patient_ID);
        fn2 = sprintf('cyclicity_rate_%s.mat',       patient_ID);
        save(fn1,'-struct','prepped_all', patient_ID);
        save(fn2,'-struct','results_all',  patient_ID);
        fprintf('Saved single‑pt files: %s, %s\n', fn1, fn2);
    else
        % all patients together
        save('U:\shared\users\sdas\2025\Code\HFOs_cyclicity\results\prepped_cyclicity_data.mat','-struct','prepped_all');
        save('U:\shared\users\sdas\2025\Code\HFOs_cyclicity\results\cyclicity_rate_results.mat',  '-struct','results_all');
        fprintf('Saved all‑pt files: prepped_cyclicity_data.mat, cyclicity_rate_results.mat\n');
end
end
