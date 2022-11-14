function plot_rates_etc( detectionType )
%%
%
%
%

if( nargin < 1 )
   detectionType = 4; % HFOs
end

%% prep
fig = gcf;
fig.Position(3:4) = [900 600];

%% compute
f = load('data/rates_etc.mat');
rate = f.rate(:,:,detectionType);
asym = f.asym_SOZ(:,:,detectionType);

%% divide canvas
ax = cell(2,2);
hoffset = 0.15;
awidth = 0.32;
voffset = 0.05;
aheight = 0.33;

clf
for i=1:2
  for j=1:2
   ax{i,j} = axes('Position', [hoffset+(i-1)*0.5, 0.5*(3-j)-aheight-voffset, awidth, aheight ]);
  end
end

%% plot
for i=1:2
  if( i == 1)
    X = rate;
    xL = 'Rate [counts/min]';
  else
    X = asym;
    xL = 'SOZ Asymmetry';
  end

  %
  axes(ax{i,1});
 
  labelVG = strrep(f.stateOfVigilanceKey.value,'N','NREM');
  scatter_bar( X, labelVG, false);
  xlabel(xL);

  addLetter(char('A'+i-1), [-0.18+i*0.01 0]);
  g = gca;
  g.Box = 'off';
  g.FontSize = 14;


  % differences
  idx1 = [7 7 7 6 6 5];
  idx2 = [6 5 4 5 4 4];
  X2 = X(:,idx1) - X(:,idx2);

  labelVG{end} = '(NREM2+)';
  labelVG2 = arrayfun( @(i) [ labelVG{idx1(i)} '-' labelVG{idx2(i)} ], 1:length(idx1), 'UniformOutput',false);

  axes(ax{i,2});
  %if( i==1 )
  %  xlimits = [-0.3 0.9];
  %%else
  %  xlimits = [-1.8 1.8];
  %end
  xlimits = [ ...
    min(X2(:)) - 0.08, ...
    max(X2(:)) + 0.25    ]

  scatter_bar( X2, labelVG2, true, xlimits );

  xlim(xlimits);
  xlabel( [ '\Delta ' xL ]);

  addLetter(char('A'+i+1), [-0.18+i*0.01 0]);
  g = gca;
  g.Box = 'off';
  g.FontSize = 14;
  g.YAxis.FontSize = 12;

end

%%

print(['plots/rate_asym.' f.detectionKey.value{detectionType} '.svg'],'-dsvg');

