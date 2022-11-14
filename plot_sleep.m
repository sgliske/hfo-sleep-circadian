function plot_sleep_v2()
%% function plot_sleep()
%
%
%

%% prep

fig = gcf;
fig.Position(3:4) = [900 600];

%% load values

nightHours = [23 7 ];  
nightKey = sprintf('%.2f-%.2f hr', nightHours(1), nightHours(2) );

tic
dataC = quantify_sleep(false, nightHours );  % cases
dataB = quantify_sleep(true, nightHours );   % control B
toc

%%
f = load('data/staging.mat','control_A_fracSleep');
  
%% prep
stageNames = {'NREM-1', 'NREM-2', 'NREM-3', 'REM','Awake'};
cohortNames = {'Control A, all time', 'Epilepsy Cohort, all time', ['Epilepsy Cohort, ' nightKey], ['Control B Cohort, ' nightKey ]};

% convert to minutes, discard unscored
dataB.boutLen = dataB.boutLen(:,1:5)*60;
dataB.boutLen6 = dataB.boutLen6(:,1:5)*60;
dataC.boutLen = dataC.boutLen(:,1:5)*60;
dataC.boutLen6 = dataC.boutLen6(:,1:5)*60;
c = colors();
clf

%% just mean

voffset = 0.05;
hoffset = 0.25;
aheight = 0.18;
awidth = 0.74;
axes('Position', [hoffset, 1-aheight-voffset, awidth, aheight ]);
%subplot(3,1,1)

Y = [
  nanmean(dataC.overall(:,1:5) ./ nansum(dataC.overall(:,1:5),2));
  nanmean(dataC.night(:,1:5) ./ nansum(dataC.night(:,1:5),2));
  nanmean(dataB.night(:,1:5) ./ nansum(dataB.night(:,1:5),2));
  ]; %#ok<*NANSUM,*NANMEAN> 

s = sum(Y,2);
Y = Y ./ s;

% plot

for i=1:3
    %%
    subplot(3,3,i)
    h = pie(Y(i,:));

    h(1).FaceColor = c.orange;
    h(3).FaceColor = c.blue;
    h(5).FaceColor = c.yellow;
    h(9).FaceColor = c.green;
    h(7).FaceColor = c.pink;

    for j=1:5
        h(2*j).String = [h(2*j).String ', ' stageNames{j}];
    end
    if( i==2 )
        h(6).HorizontalAlignment = 'right';
        h(8).HorizontalAlignment = 'left';
        h(10).Position = h(10).Position + [0 0.2 0];
    end
    if( i==3 )
        h(4).Position = h(4).Position - [0 0.2 0];
    end

    if( i==1 )
        addLetter( 'A' ); %) Epilepsy Cohort, full 24-hours');
    elseif( i==2 )
        addLetter( 'B' ); %[ 'B) Epilepsy Cohort, ' nightKey ]);
    else
        addLetter( 'C' ); %[ 'C) Epilepsy Cohort, ' nightKey ]);
    end
end

%

n = [ ...
  length(f.control_A_fracSleep),...
  size(dataC.overall,1),...
  size(dataC.night,1),...
  size(dataB.night,1)...
]';  

% Ye is standard error on the mean
s = [1; s(:)];
Ye = [
  [nan(1,4), nanstd(f.control_A_fracSleep)];
  nanstd(dataC.overall(:,1:5) ./ nansum(dataC.overall(:,1:5),2));
  nanstd(dataC.night(:,1:5) ./ nansum(dataC.night(:,1:5),2));
  nanstd(dataB.night(:,1:5) ./ nansum(dataB.night(:,1:5),2));
  ] ./ sqrt(n) ./ s; 

Y = [[nan(1,4) 1-nanmean(f.control_A_fracSleep)]; Y];

% confidence intervals for the mean
CI_L = Y - 1.96*Ye;
CI_H = Y + 1.96*Ye;

% display
[n,m] = size(Y);
hrs = [24 24 8 8];
fprintf('Mean and 95%% CI of number of hours per each state of vigilance\n');
for i=1:n
  for j=1:m
      if( ~isfinite(Y(i,j)) )
          continue
      end
    fprintf('%31s %6s : %6.3f (%6.3f - %6.3f)\n', cohortNames{i}, stageNames{j}, Y(i,j)*hrs(i), CI_L(i,j)*hrs(i), CI_H(i,j)*hrs(i) );
  end
end

%% Bout lengths

axes('Position', [hoffset-0.02, 2/3-aheight-voffset, awidth, aheight ]);
h = bar([nanmean(dataC.boutLen6); nanmean(dataB.boutLen6)]');

h(1).FaceColor = c.skyBlue;
h(2).FaceColor = c.black;

g = gca;
g.Box = 'off';
g.FontSize = 14;
g.XTickLabel = stageNames;
ylabel({'Median','Bout Length','[min]'})
g.YGrid = 'on';
ylim([0 24]);

%legend(cohortNames(3:4),'Orientation','horizontal','Location','northoutside');
legend(cohortNames(3:4),'Location','eastoutside');
addLetter('D',[-0.21 0]);

for i=1:5
  p = ranksum( dataC.boutLen6(:,i), dataB.boutLen6(:,i) );
  fprintf('%5s p=%.6f\n', stageNames{i}, p );
end

%% Time of day

hoffset = 0.12;
ax(1) = axes('Position', [hoffset,     1/3-aheight-voffset, awidth/2, aheight ]);
ax(2) = axes('Position', [hoffset+0.5, 1/3-aheight-voffset, awidth/2, aheight ]);

for i=1:2
%%
  axes(ax(i)); %#ok<LAXES> 
  addLetter(char('D'+i));
  hold on

  x = 1:2:24;
  if( i==1 )
    y1 = 1-nanmean(dataC.circAwake);
  else
    y1 = nanmean(dataC.circNrem234);
  end
  h = stairs([x x+24], [y1 y1]);
  h.Color = c.skyBlue;
  h.LineStyle = '-';

  if( i==1 )
    y2 = 1-nanmean(dataB.circAwake);
  else
    y2 = nanmean(dataB.circNrem234);
  end
  y2(5:10) = 0;  % region of data with almost no data

  h = stairs([x x+24],[y2 y2]);
  h.Color = c.black;
  h.LineStyle = '-.';

  xlim([1 46.9])
  ylim([0 1.0])

  xticks(0:4:48);
  xticklabels(mod(xticks(),24));

  g = gca;
  g.FontSize = 14;
  xlabel('Time of Day [hours]');
  g.Box = 'off';

  if( i==1 )
    ylabel({'Probability','Asleep'});
  else
    ylabel({'Probability','NREM >1'});
  end
end
hold off

temp = cell(2,1);
idx = [2 4];
for i=1:length(idx)
  k = find( cohortNames{idx(i)}==',',1);
  temp{i} = cohortNames{idx(i)}(1:k-1);
end

axis(ax(2));
h = legend( temp,'Location','northeast');
%h.Position(1:2) = h.Position(1:2) - [0.45 0.1];
h.Position(1:2) = [0.78 0.26];

%% save

print('plots/sleep.svg','-dsvg');

