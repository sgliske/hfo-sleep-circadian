function plot_circ_stats( doRate )


%% gather data

if( doRate )
  f = load('data/rate_cyclicity.mat');
  data = f.data;
  [nP,nS] = size(data);
  
  %% quick fix
  for i=1:nP
    for j=1:nS
      if( isempty(data(i,j).N_hfos) )
        data(i,j).N_hfos = nan;
      end
    end
  end
  
  %% copy out
  %n   = reshape([data.N_hfos],nP,nS);
  p   = reshape([data.p],nP,nS);
  phi = reshape([data.zenith],nP,nS);
  mag = reshape([data.amp],nP,nS);

  %% reduce to just NREM and Awake
  p = p(:,[7 5]);
  phi = phi(:,[7 5]);
  mag = mag(:,[7 5]);
  
  color = [0 0.4470 0.741];
  
else
  %% load data
  f = load('data/asym_cyclicity.mat');
  data = f.data;
  %if( ~isstruct(f.data) )
  %  data = cell2mat(f.data);
  %else
  %  data = f.data;
  %end
  
  %% prep (reshape) data
  [nP,nS]  = size(data);
  
  %n = arrayfun( @(x) length(x.event_time), data );
  %valid = n > 100;
  
  p     = nan(nP,2);
  phi   = nan(nP,2);  
  mag   = nan(nP,2);
  class_1 = nan(nP,1);
  
  order = [7 5]; % nrem and awake
  for pIdx=1:nP
    for k=1:2
      d = data{pIdx,order(k)};
      if( ~isempty(d) )
          mag(pIdx,k) = d.mag;
          phi(pIdx,k) = d.zenith;
          class_1(pIdx,k) = d.class_1;
          p(pIdx,k) = mean( d.mag < d.rand_mag );
      end
    end
  end

  % focus on class 1
  %I = class_1 == 1;  % false for ~isfinite(class_1) and ~class_1
  %mag(~I) = nan;  % due to nans, this is not the same as ~= 1
  %phi(~I) = nan;  % due to nans, this is not the same as ~= 1
  %p(~I) = nan;    % due to nans, this is not the same as ~= 1

  color = [0 0.4470 0.0741];

end

%%

fig = gcf;
fig.Position(3:4) = [900 600];
  
titles = {'NREM', 'Awake' };
clf

alpha = 0.05;
for i=1:2
   subplot(2,3, 3*i-2 );
   polarscatter( phi(:,i), mag(:,i), 20, (p(:,i)<0.05).*color,'filled' );
   fprintf('Number significant: %d of %d\n', sum(p(:,i)<0.05), sum(isfinite(p(:,i))) );
   
   g = gca;
   g.ThetaDir = 'clockwise';
   g.ThetaZeroLocation = 'top';
   g.ThetaTick = 0:30:360;
   g.ThetaTickLabel = 0:2:24;
   g.RLim = [0 0.7];
   g.RTick = [0.2:0.2:1];
   g.RAxisLocation = 165;
   %title(titles{i});
   
   addLetter( char(3*i-2+'A'-1), [-0.05 0] );
   
   %%
   subplot(2,3,3*i-1 )
   I = p(:,i) < alpha;
   h2 = polarhistogram( phi(I,i), linspace(0,2*pi,13) );
   h2.FaceColor = color;
   h2.EdgeColor = 'k';
   h2.FaceAlpha = 1;

   g = gca;
   g.ThetaDir = 'clockwise';
   g.ThetaZeroLocation = 'top';
   g.ThetaTick = 0:30:360;
   g.ThetaTickLabel = 0:2:24;
   g.RTick = 2:2:8;
   g.RLim = [0 7];
   g.RAxisLocation = 165;
   %g.RTick = 1:2:10;
   
   N1 = sum(I);
   N2 = sum(isfinite(p(:,i)));
   fprintf('%s %d/%d significant, (p=%.4g)\n', titles{i}, N1, N2, binocdf( N1, N2, alpha, 'upper' ));
   
   addLetter( char(3*i-1+'A'-1), [-0.05 0] );

   %%
   subplot(2,3,3*i)

   h3 = histogram( mag(I,i), linspace(0,0.7,8) );
   h3.FaceAlpha = 1;
   h3.FaceColor = color;
   
   xlabel('Magnitude');
   ylabel('Counts');
   ylim([0 25]);

   addLetter( char(3*i+'A'-1), [-0.065 0] );

end

for i=1:6
  subplot(2,3,i);
  g = gca;
  g.FontSize = 12;
  g.Box = 'off';
end

%%

if( doRate )
  print('plots/circ_rate.svg','-dsvg');
else
  print('plots/circ_asym.svg','-dsvg');
end
