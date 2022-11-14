function [data,total] = durPerBin( stage, time, width, offset )
%% data = window( stage, time, width, offset )
%
% units for time, width, and offset are arbitrary, much must be consistant
%

%% check
assert(issorted(time));

%% compute bin number
bin = floor((time-offset)/width)+1;
nBins = max(bin);
assert(min(bin)>0);

%% add in markers for the start of each sleep period
edgeBins = (1:nBins+1)';
edgeTimes = (edgeBins-1)*width+offset;

[edgeTimes, I] = setdiff( edgeTimes, time);
if( length(I) < length(edgeBins) || any(~I) )
  edgeBins = edgeBins(I);
end

time = [time; edgeTimes];
bin = [bin; edgeBins];
stage = [stage; -1*ones(size(edgeBins))];

%% sort
[time,I] = sort(time);
stage = stage(I);
bin = bin(I);

% start with unknown unless otherwise specified
if( stage(1) == -1 )
  stage(1) = 6;
end

% fix stage for edges
while( true )
  I = find(stage == -1);
  if( isempty(I) )
    break
  else
    stage(I) = stage(I-1);
  end
end

%% compute duration and drop last tag
data.stage = stage(1:end-1);
data.time  = time(1:end-1);
data.dur   = diff(time);
data.bin   = bin(1:end-1);

%% accumulate
total = accumarray( [data.stage data.bin], data.dur);
assert( all(nansum(total)==width | ~isfinite(sum(total) )));

