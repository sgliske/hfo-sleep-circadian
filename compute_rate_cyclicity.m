function data = compute_rate_cyclicity( pIdx )
%% function data = compute_rate_cyclicity( pIdx )
%
% Computes the rate cyclicity via the method of unfolding.
%
% Depends on the following functions
% - prep_cyclicity_data.m
% - unfolding.m
% - pwc.m
%
% Creates the file
% - rate_cyclicity.mat
%

%% input options
if( nargin < 1 )
  pIdx = 'all';
end

%% load data (if needed)

persistent f
if( isempty(f) )
  f = load('data/detections.mat');
end
nP = length(f.ID);

%% loop over everyone?

if( strcmp( 'all', pIdx ) )
  ticA = tic;
  data = cell(nP,1);
  for pIdx=1:nP
    try
      data{pIdx} = compute_rate_cyclicity(pIdx);
    catch
      fprintf('Error on %d\n', pIdx );
    end
  end
  data = cell2mat(data);
  toc(ticA);
  
  save('data/rate_cyclicity.mat','data');
  return
end

%% identify the data for the given patient

if( ischar(pIdx) )
  pIdx = strcmp( pIdx, f.ID );
  assert( numel(pIdx) == 1 );
else
  assert( pIdx > 0 & pIdx <= nP );
end

%% get data

data = prep_cyclicity_data( f.cases_detections(pIdx) );
N_smearing = 100000;
N_null     = 1000;

%% loop over state of vigilance

tic
nS = length(data);
for s=1:nS
  N_hfos = length( data(s).hfo_start_time );
  fprintf('%d %d %d\n', pIdx, s, N_hfos);
  if( N_hfos < 100 )
    data(s).amp   = nan;
    data(s).zenith = nan;
    data(s).p = nan;
    data(s).n = nan;
    continue;
  end

  %% prep unfolding object
  obj = unfolding( 1 );
  phi_sim = data(s).acceptance.genData( N_smearing ) / data(s).acceptance.max_x * 2*pi;
  obj.compute_smearing_matrix( phi_sim );
  
  %% unfold the HFOs
  obj.unfold( data(s).hfo_start_time * 2*pi );
  
  data(s).amp   = obj.gamma(1);
  data(s).zenith = obj.gamma(2);

  %% check significance
  
  data(s).N_hfos = N_hfos;
  a = zeros(N_null,1);
  for k=1:N_null
     phi_null = data(s).acceptance.genData( N_hfos ) / data(s).acceptance.max_x * 2*pi;
     obj.unfold( phi_null );
     
     a(k) = obj.gamma(1);
  end
  
  data(s).p = mean(data(s).amp < a);

end
toc