function [data, key] = prep_cyclicity_data( d )
%%
%
%
%
%


%% get short hand for the detection structure
%d = f.cases_detections(pIdx);
isHFO = d.detection_type == 4; % HFOs

%% loop over state of vigilance combinations

nS = 7;
data = cell(1,nS);

for s=1:nS
  %% compute valid time
  
  %% shorthand
  getStartTime = @(s,source) cell2mat(arrayfun( @(x) x.start(:), source(d.validChannels,s), 'uniformoutput', false ));
  getStopTime = @(s,source) cell2mat(arrayfun( @(x) x.stop(:), source(d.validChannels,s), 'uniformoutput', false ));
  
  % start and stop time of each segment of valid recording/scoring
  if( s < 6 )
    start = getStartTime(s,d.validTimePerStage);
    stop  = getStopTime(s,d.validTimePerStage);
  elseif( s == 6 ) % Overall
    start = [ ...
      getStartTime(1,d.validTimePerStage); ...
      getStartTime(2,d.validTimePerStage); ...
      getStartTime(3,d.validTimePerStage); ...
      getStartTime(4,d.validTimePerStage); ...
      getStartTime(5,d.validTimePerStage); ...
      ];
    
    stop  = [...
      getStopTime(1,d.validTimePerStage); ...
      getStopTime(2,d.validTimePerStage); ...
      getStopTime(3,d.validTimePerStage); ...
      getStopTime(4,d.validTimePerStage); ...
      getStopTime(5,d.validTimePerStage); ...
      ];
  else % NREM
    start = [ ...
      getStartTime(1,d.validTimePerStage); ...
      getStartTime(2,d.validTimePerStage); ...
      getStartTime(3,d.validTimePerStage); ...
      ];
    
    stop  = [...
      getStopTime(1,d.validTimePerStage); ...
      getStopTime(2,d.validTimePerStage); ...
      getStopTime(3,d.validTimePerStage); ...
      ];
  end
  
  % convert from minutes to days
  start = start(:)/1440;
  stop = stop(:)/1440;
  
  % compute amount of recording for each time it changes
  offset = sum(floor(stop) - floor(start));
  [start,~,I] = unique(rem(start,1));
  start_val = accumarray(I,1);
  
  % combine repeated time values
  [stop,~,I] = unique(rem(stop,1));
  stop_val = accumarray(I,1);
  
  % determine total number of times each time of day was recorded
  time = [ 0; start; stop; 1];
  val  = [ offset; start_val; -stop_val; -offset ];
  [time,I] = sort(time);
  val = val(I);
  val = cumsum(val);
  assert(val(end) == 0);
  assert(time(end) == 1 );
  
  % compute peice-wise constant
  acceptance = pwc( time(1:end-1), val(1:end-1), time(end) );
  
  % store results
  data{s}.acceptance = acceptance;
  
  %% gather HFO events
  if( s < 6 )
    I = isHFO & (d.stateOfVigilance == s );
  elseif( s == 6 )
    I = isHFO & (d.stateOfVigilance >= 1 & d.stateOfVigilance <= 5 );
  else
    I = isHFO & (d.stateOfVigilance >= 1 & d.stateOfVigilance <= 3 );
  end
  
  data{s}.hfo_start_time = mod(d.startTime(I)/1440,1); % convert from minutes to fraction of day
  if( numel(d.SOZ) > 1 )
    data{s}.hfo_in_SOZ   = d.SOZ(d.chanIdx(I));
  else
    data{s}.hfo_in_SOZ   = nan;
  end
  data{s}.hfo_in_SOZ     = data{s}.hfo_in_SOZ(:);
  data{s}.nChan_in_SOZ   = sum(d.SOZ==1);
  data{s}.nChan_not_SOZ  = sum(d.SOZ==0);
  
end

data = cell2mat(data);

%%

key = table();
key.code = (1:7)';
key.name = {'N1','N2','N3','REM','Awake','Overall','NREM'}';

