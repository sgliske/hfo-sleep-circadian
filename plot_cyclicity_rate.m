
% Code to plot the cyclicity results
% %%
% 
% % -------------------
% %   Plot HFO rate cyclicity (NREM & Awake) from results_all structure
% %
% %   Written by SD • May-2025
% 

results_all = load("C:\Users\srdas\Documents\cyclicity_rate_results.mat");
patient_list = fieldnames(results_all);
nP = numel(patient_list);

amp = nan(nP,2);
zen = nan(nP,2);
pval = nan(nP,2);

idxNREM = 7;
idxAwake = 5;

for p = 1:nP
    s = results_all.(patient_list{p});
    amp(p,1) = s(idxNREM).amp;
    amp(p,2) = s(idxAwake).amp;
    zen(p,1) = s(idxNREM).zenith;
    zen(p,2) = s(idxAwake).zenith;
    pval(p,1) = s(idxNREM).p;
    pval(p,2) = s(idxAwake).p;
end

alpha = 0.05;
colorNREM = [0 0.4470 0.741];
colorAwake = [0.8500 0.3250 0.0980];
titles = {'NREM', 'Awake'};

figure('Color','w','Position',[50 50 1400 650]);

tl = tiledlayout(2,3,'TileSpacing','tight','Padding','tight');

fig_labels = {'A','B','C','D','E','F'};
label_idx = 1;

for k = 1:2 
    num_total = length(pval(:,k));
    sig = pval(:,k) < alpha;
    fprintf('\n Number significant: %d of %d in %s\n', sum(sig), num_total, titles{k});

    if k == 1                   %choose the windows in each stage as per the plots
        num_sig = 79;      %count of subjects with peak during NREM stage between 6 pm and 4 am
        num_total = length(pval(:,k));
        p = 10/24;         
        color = colorNREM;
        window_name = 'Night (18:00-4:00)';
    else
        num_sig = 47;      %count of subjects with peak 
        num_total = length(pval(:,k));
        p = 4/24; 
        color = colorAwake;
        window_name = 'Day (14:00-18:00)';
    end
    p_binom = binocdf(num_sig,num_total,p,'upper');
    fprintf('%s: %d/%d subjects significant (p=%.4g, binomial test) in %s \n', ...
             titles{k}, num_sig, num_total, p_binom, window_name);

    subplot(2,3,3*k-2);
    polarscatter(zen(:,k), amp(:,k), 30, sig.*color,'filled');
    title([titles{k} ' – polar scatter'], FontSize=15);
    g = gca;
    g.ThetaDir = 'clockwise';
    g.ThetaZeroLocation = 'top';
    g.ThetaTick = 0:30:360;
    g.ThetaTickLabel = 0:2:24;
    g.RLim = [0 0.8];
    g.RTick = 0.2:0.2:0.8;
    g.RAxisLocation = 165;
    add_panel_label(gca, fig_labels{label_idx});
    label_idx = label_idx + 1;

    subplot(2,3,3*k-1);
    h = polarhistogram(zen(sig,k),linspace(0,2*pi,13),'FaceColor',color,'EdgeColor','k','FaceAlpha',1);
    title([titles{k} ' – zenith'], FontSize=15);
    g = gca;
    g.ThetaDir = 'clockwise';
    g.ThetaZeroLocation = 'top';
    g.ThetaTick = 0:30:360;
    g.ThetaTickLabel = 0:2:24;
    g.RLim = [0 25];
    g.RTick = 3:4:25;
    g.RAxisLocation = 165;
    add_panel_label(gca, fig_labels{label_idx});
    label_idx = label_idx + 1;

    subplot(2,3,3*k);
    histogram(amp(sig,k),linspace(0,0.7,8),'FaceColor',color,'EdgeColor','k','FaceAlpha',1);
    xlabel('Magnitude'); ylabel('Counts');
    title([titles{k} ' – magnitude'], FontSize=15);
    ylim([0 45]);
    add_panel_label(gca, fig_labels{label_idx});
    label_idx = label_idx + 1;
end

set(findall(gcf,'Type','axes'),'FontSize',15,'Box','off');

outDir = ['plots' filesep];
if ~exist(outDir,'dir'); mkdir(outDir); end
outFile = [outDir 'Cyclicity.svg'];
print(outFile,'-dsvg');
fprintf('Figure saved → %s\n', outFile);

function add_panel_label(ax, label)
    text(ax, 0.02, 0.95, label, ...
        'Units','normalized', ...
        'FontSize',16, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','top');
end


