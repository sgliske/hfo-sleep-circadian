%%-------------------------------------
% Create demographics table
% Written by SD
% October 2025

%% Setup and Load data
addpath("U:\shared\users\sdas\2025\Code\HFOs_cyclicity");
%e = load("epochs_data.mat");     %take care of the data structure
e = load("C:\Users\srdas\Documents\epochs_data.mat");     %check data path & load
h = load("C:\Users\srdas\Documents\cyclicity_rate_results.mat");

t_scale = 3600;     %seconds to hours

%% Compute Stats

% TIME: Iterates over fields in 'e'
t = structfun(@(p) median(cellfun(@(x) x.getDuration(), p.valid_Time)), e) / t_scale;

n = structfun(@(p) p(6).N_hfos, h);

fprintf('\n\nTime\n------\n');
fprintf('Sum: %.1f\n', sum(t));
fprintf('Mean: %.1f\n', mean(t));
fprintf('Min: %.1f\n', min(t));
fprintf('Max: %.1f\n', max(t));

%HFO counts
fprintf('\n\nHFOs\n------\n');
fprintf('Sum: %.1f [counts]\n', sum(n))
fprintf('Mean: %.1f [counts]\n', mean(n))
fprintf('Min: %.1f [counts]\n', min(n))
fprintf('Max: %.1f [counts]\n', max(n))