function data = compute_asym_cyclicity()
%% function data = compute_asym_cyclicity()
%
% Computes the cyclicity of the HFO asymmetry with respect to the SOZ,
% using circular KDEs and a least squares fit.
%
% depends on the following functions
% - prep_cyclicity_data.m
% - circKDE.m
%
% Creates the file
% - asym_cyclicity.mat
%

%% load data

ticA = tic;
f = load('data/detections.mat');
nP = length(f.ID);
toc(ticA);

%% prep
matrix = @(x) [ones(size(x)) cos(x) sin(x)];

nKDE = 100;
x = linspace( 0, 24, nKDE + 1 )';
x = x(1:end-1);
X = matrix(x/24*2*pi);

%% loop over everyone

ticB = tic;
nS = 7;
data = cell(nP,nS);
N_iters = 1000;

for pIdx=1:nP
  fprintf('On %d of %d\n', pIdx, nP );
  
  %% get short hand for the detection structure
  d = f.cases_detections(pIdx);
  data_in = prep_cyclicity_data( d );

  assert( nS == length(data_in) )
 
  %% loop over state of vigilance combinations
  for s=1:nS
    
    %% prep for 24-hour asymmetry computation
    ticC = tic;
    vt = d.validTimeDurPerStage(d.validChannels,:);
    if( all(all(vt == vt(1,:))) && numel(d.SOZ) > 1 && ~isempty(data_in(s).hfo_start_time) )
      % same amount of valid time per channel, so can ignore time when
      % computing asymmetry  

      nIn = sum( data_in(s).hfo_in_SOZ );
      nOut = sum( ~data_in(s).hfo_in_SOZ );
      
      fprintf('\t%d/%d %d/%d: %6d %6d\n\t', pIdx, nP, s, nS, nIn, nOut );
      
      rand_mag = nan(N_iters,1);
      for k=1:N_iters+1
        if( k>N_iters)
          % real data
          tIn  = data_in(s).hfo_start_time( data_in(s).hfo_in_SOZ );
          tOut = data_in(s).hfo_start_time( ~data_in(s).hfo_in_SOZ );
        else
          % simulated data (uniform within acceptance)
          tIn = data_in(s).acceptance.genData( nIn );
          tOut = data_in(s).acceptance.genData( nOut );
        end
        
        [~,yIn] = circKDE( tIn, 1, 100 );
        [~,yOut] = circKDE( tOut, 1, 100 );
        
        yIn = yIn * nIn / 24 / 60 / data_in(s).nChan_in_SOZ;
        yOut = yOut * nOut / 24 / 60 / data_in(s).nChan_not_SOZ;
        
        I = yIn + yOut > 0.5;
        if( mean(I) < 0.75 )
          continue;
        end
        
        a = (yIn-yOut)./(yIn+yOut);
        alpha = X(I,:) \ a(I)';
        
        if(  k>N_iters )
          data{pIdx,s}.selected = I;
          data{pIdx,s}.asym = a;
          data{pIdx,s}.yIn = yIn;
          data{pIdx,s}.yOut = yOut;
          data{pIdx,s}.alpha = alpha';
          
          data{pIdx,s}.zenith = atan2(alpha(3),alpha(2));
          data{pIdx,s}.mag    = sqrt(sum(alpha(2:3).^2));
          data{pIdx,s}.class_1 = d.class_1;
          data{pIdx,s}.rand_mag = rand_mag;
        else
          %fprintf('%4d %.3f %.3f %.3f\n', k, alpha(1), alpha(2), alpha(3) );
          rand_mag(k) = sqrt(sum(alpha(2:3).^2));
        end
      end
      toc(ticC)
    else
      data{pIdx,s} = [];
    end
  end
end

fprintf('Total for the loop:\n\t');
toc(ticB);

%%
%data = cell2mat(data);
save('data/asym_cyclicity.mat','data');

fprintf('Total processing time:\n\t');
toc(ticA);


