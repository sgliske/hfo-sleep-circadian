%% overall rates and asymmetries

tic
compute_rates_etc();
toc
% depends on 
% - data/detections.mat
%
% creates files
% - data/rates_etc.mat

%% cyclicity of HFO rates (~30 minutes)

compute_rate_cyclicity('all')
% depends on the following functions
% - prep_cyclicity_data.m
% - unfolding.m
% - pwc.m
%
% Creates the file
% - rate_cyclicity.mat
%

%% cyclicity of HFO SOZ Asymmetries (~25 seconds)

compute_asym_cyclicity();
% depends on the following functions
% - prep_cyclicity_data.m
% - circKDE.m
%
% Creates the file
% - asym_cyclicity.mat
%

%% make the plots
make_plots; % more comments within this file
