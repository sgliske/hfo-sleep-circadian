function data = quantify_sleep( doControls, nightHours )
%% function data = quantify_sleep()
%
% Compute quantification of state of vigilance information
%

%% check input
if( nargin < 1 )
  doControls = false;
end
if( nargin < 2 )
  nightHours = [23 7];
end

%% load data

f = load('data/staging.mat');
if( doControls )
  staging = f.control_B_staging;
else
  staging = f.cases_staging; 
end
ID = f.ID;
timeOrigin = f.timeOrigin;
clear f

nSubj = length(staging);
nStages = 6;

%% loop over subjects

overall = zeros(nSubj,nStages);
night   = zeros(nSubj,nStages);
boutLen = zeros(nSubj,nStages);
boutLen6 = zeros(nSubj,nStages);
circAwake  = zeros(nSubj,12);
circNrem234 = zeros(nSubj,12);

nightWidth = diff(nightHours);
if(nightWidth<0)
  nightWidth = nightWidth + 24;
end

nightOffset = 24 - nightHours(1);
nightPeriods = 24/nightWidth;
assert( nightPeriods == floor(nightPeriods) );

for i=1:nSubj
  %% prep
  t = hours(staging{i}.time - timeOrigin);
  s = staging{i}.stage;
  if( ~all(isreal(s)))
    fprintf('Imaginary stage values for subject %s\n', ID{i} );
    I = imag(s) ~= 0;
    s(I) = 6;
  end
  dur = diff(t);
  
  %% overall
  assert( s(end) == 6 );
  overall(i,:) = accumarray( s(1:end-1), dur, [nStages 1], @sum );
  boutLen(i,:) = accumarray( s(1:end-1), dur, [nStages 1], @median );

  %% From 23.00 to 7.00 hour, or whatever is specified in nightHours 
  temp = durPerBin( s, t+24, nightWidth, nightOffset );  % add in 24 hours just to make sure bin numbers are positive
  temp.bin = mod(temp.bin-1,nightPeriods)+1;
  I = temp.bin == 1;
  night(i,:) = accumarray( temp.stage(I), temp.dur(I), [nStages 1]);
    
  t_ = mod(t,24);
  d_ = diff(t_);
  I = t_ < 6;
  I(end) = false;
  d_ = d_(I);
  s_ = s(I);
  boutLen6(i,:) = accumarray( s_, d_, [nStages 1], @median );

  %% 2-hr bins, starting at 1 AM (awake, nrem >= 2)
  temp = durPerBin( s, t+24, 2, 1 );  %% adding a 24 hour offset to t, so that the initial "unscored" mark at the time origin gets a positive bin
  temp.bin = mod(temp.bin-1,12)+1;
  temp2 = accumarray( [temp.stage temp.bin ], temp.dur, [nStages 12], @sum );
  
  circAwake(i,:)   = temp2(5,:) ./ sum(temp2(1:5,:));
  circNrem234(i,:) = sum(temp2(2:3,:)) ./ sum(temp2(1:5,:));

end

data.overall = overall;
data.night = night;
data.boutLen = boutLen;
data.boutLen6 = boutLen6;
data.circAwake = circAwake;
data.circNrem234 = circNrem234;
