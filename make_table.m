
f = load('data/input_data.mat');

t = arrayfun( @(x) median(x.validTime), f.cases_detections);
%%
fprintf('\n\nTime\n------\n');
fprintf('Sum: %.1f [hours]\n', sum(t)/60)
fprintf('Mean: %.1f [hours]\n', mean(t)/60)
fprintf('Min: %.1f [hours]\n', min(t)/60)
fprintf('Max: %.1f [hours]\n', max(t)/60)

q = quantile( t, [0.025 0.5 0.975] )/60;
fprintf('Quantiles: %.1f %.1f %.1f\n', q );

%%

n = [data(:,6).N_hfos];

fprintf('\n\nHFOs\n------\n');
fprintf('Sum: %.1f [counts]\n', sum(n))
fprintf('Mean: %.1f [counts]\n', mean(n))
fprintf('Min: %.1f [counts]\n', min(n))
fprintf('Max: %.1f [counts]\n', max(n))

q = quantile( n, [0.025 0.5 0.975] );
fprintf('Quantiles: %.1f %.1f %.1f\n\n', q );
