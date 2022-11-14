function data = compute_rates_etc()
%%
%
%
%

%%
f = load('data/detections.mat');

%% prep
nD = height(f.detectionKey);
nP = length(f.cases_detections);

data.detectionKey = f.detectionKey;
data.stateOfVigilanceKey = f.stateOfVigilanceKey;
assert( all( strcmp( f.stateOfVigilanceKey.value, {'N1','N2','N3','REM','Awake','Unknown'}')));

overallKey = 6;
N234key = 7;
data.stateOfVigilanceKey.value{6} = 'Overall';
data.stateOfVigilanceKey(end+1,:) = {7, 'N2+'};

nV = height(data.stateOfVigilanceKey);
assert( nV == 7);

data.rate = nan(nP,nV,nD);
data.asym_SOZ = nan(nP,nV,nD);
data.asym_RV = nan(nP,nV,nD);

%%
for i=1:nD
  %fprintf('Working on %s\n', f.detectionKey.value{i});

  for j=1:nP
    % select the correct detection type
    I = f.cases_detections(j).detection_type == i;

    % compute counts
    nChan = length(f.cases_detections(j).validTimeDur);
    counts = accumarray( [f.cases_detections(j).chanIdx(I), f.cases_detections(j).stateOfVigilance(I)], 1, [nChan nV] );

    % make combinations
    counts(:,end-1) = sum(counts(:,1:6),2);
    counts(:,end) = sum(counts(:,2:3),2);

    validTimeDur = [...
      f.cases_detections(j).validTimeDurPerSleepStage, ...
      f.cases_detections(j).validTimeDur, ...
      sum(f.cases_detections(j).validTimeDurPerSleepStage(:,2:3),2)
      ];

    % compute rate
    rate = counts ./ validTimeDur;
    validChan = f.cases_detections(j).validChannels;
    data.rate(j,:,i) = mean( rate(validChan,:) );

    % asymmetry
    SOZ = f.cases_detections(j).SOZ;
    if( all(isfinite(SOZ)))
      a = mean( rate(SOZ&validChan,:) );
      b = mean( rate(~SOZ&validChan,:) );
      data.asym_SOZ(j,:,i) = (a-b) ./ (a+b);
    end

    RV = f.cases_detections(j).RV;
    if( all(isfinite(RV)))
      a = mean( rate(RV&validChan,:) );
      b = mean( rate(~RV&validChan,:) );
      data.asym_RV(j,:,i) = (a-b) ./ (a+b);
    end
    
  end
end

save('data/rates_etc.mat', '-struct', 'data');


