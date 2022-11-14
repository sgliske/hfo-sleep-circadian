%% fig 1: Sleep characteristics

plot_sleep;
% depends on
% - quantify_sleep.m
% - durPerBin.m
%
% makes the file
% - plots/sleep.svg

%% fig 2: HFO rates and asymmetries vs. sleep
plot_rates_etc(4); % HFOs
% depends on
% - data/rates_etc.mat
% - scatter_bar.m
%
% makes the file
% - plots/rate_asym.HFO.svg

%% artifact rates, not used but discussed
plot_rates_etc(1);
plot_rates_etc(2);
plot_rates_etc(3);
% depends on
% - data/rates_etc.mat
% - scatter_bar.m
%
% makes the files
% - plots/rate_asym.*.svg

%% artifact asym, not used but discussed
plot_artifact_asym(true);
% depends on
% - data/rates_etc.mat
% - scatter_bar.m
%
% makes the files
% - plots/artifact_asym_SOZ.eps


%% fig 4: HFO rate and 24-hour cyclicity
plot_circ_stats(true)
% depends on
% - rate_cyclicity.mat
%
% makes the file
% - plots/circ_rate.svg

%% fig 5: Example asym cyclicity
plot_asym_cyclicity( 8, 7 );
% depends on
% - asym_cyclicity.mat
%
% makes files
% - plots/rate_asym_*_*.svg

%% fig 5: HFO asymmetries and 24-hour cyclicity
plot_circ_stats(false)
% depends on
% - asym_cyclicity.mat
%
% makes the file
% - plots/circ_asym.svg
