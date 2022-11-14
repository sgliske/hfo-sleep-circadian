function plot_artifact_asym( doSOZ )
%%
%
%
%

if( nargin < 1 )
  doSOZ = true;  % if false, do RV
end

%% compute
f = load('data/rates_etc.mat');

%% prep
fig = gcf;
fig.Position(3:4) = [1200 250];

%% plot
hoffset1 = 0.12;
hoffset2 = 0.02;
awidth = (1-hoffset1-2.5*hoffset2)/3

voffset = 0.1;
aheight = 0.65;

% plot
clf
for i=1:3
  if( doSOZ )
    X = f.asym_SOZ(:,:,i);
    xL = 'SOZ Asymmetry';
  else
    X = f.asym_RV(:,:,i);
    xL = 'RV Asymmetry';
  end
  labelVG = f.stateOfVigilanceKey.value;

  % differences
  idx1 = [7 7 7 6 6 5];
  idx2 = [6 5 4 5 4 4];
  X2 = X(:,idx1) - X(:,idx2);

  labelVG{end} = '(N2+)';
  labelVG2 = arrayfun( @(i) [ labelVG{idx1(i)} '-' labelVG{idx2(i)} ], 1:length(idx1), 'UniformOutput',false);

  axes('Position', [hoffset1+(i-1)*(awidth+hoffset2), 1-aheight-voffset, awidth, aheight ]);
  scatter_bar( X2, labelVG2, true, [-1.1 1.9]);
  xlabel( [ '\Delta ' xL ]);
  if( i>1 )
    yticklabels('');
  end

  addLetter(char('A'+i-1), [-0.005 -0.11]);
  g = gca;
  g.Box = 'off';
  g.FontSize = 14;

end

%%

if( doSOZ )
  print('plots/artifact_asym_SOZ.eps','-depsc');
else
  print('plots/artifact_asym_RV.eps','-depsc');
end
