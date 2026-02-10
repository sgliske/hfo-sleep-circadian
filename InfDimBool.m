classdef InfDimBool < handle
%% classdef InfDimBool < handle
%
% Member functions (all operate inplace)
%
% obj = InfDimBool(start, stop)                % constructor
% obj.setTrue( start, stop )                   % set range true
% obj.setFalse( start, stop )                  % set range false
% obj.invert()                                 % invert (logical NOT)
% obj.or( this, that )                         % inplace logical OR
% obj.and( this, that )                        % inplace logical AND
% [start, stop] = obj.getRange()               % get range where it is true
% dur = obj.getDuration()                      % duration of true values
% overlaps = obj.checkOverlaps( start, stop )  %
%

  properties (SetAccess = private, Hidden = true )
    TOLERANCE
  end

  properties (SetAccess = private, Hidden = false )
    start
    stop
  end

  methods
    
    %% constructor
    function this = InfDimBool( start, stop )
      this.start = [];
      this.stop = [];
      this.TOLERANCE = 1/50000;
      
      if( nargin > 0 )
        narginchk(2,2);
        this = setTrue( this, start, stop );
      end
    end
    
    %% set range to true
    function this = setTrue( this, start, stop )
      %% check
      assert( length(start) == length(stop) );
      
      %% copy
      this.start = [this.start; start(:)];
      this.stop  = [this.stop;  stop(:)];
      
      %% clean
      [this.start, this.stop] = this.cleanUp( this.start, this.stop );
    end
    
    %% set range to false
    function this = setFalse( this, start, stop )

      if( isempty( this.start ) )
        % is already entirely false
        return
      end
      assert( length(start) == length(stop) );
      [start, stop] = cleanUp( this, start, stop );

      %% loop over each section of true values
      for i=1:length(start)
        overlaps = this.start < stop(i) & this.stop > start(i);
        if( any(overlaps) )
          keep = true(length(this.start),1);
          for k=find(overlaps)'
            assert(numel(k)==1);
            
            if( this.start(k) < start(i) )  % this starts first
              if( this.stop(k) < stop(i) )  % this stops first as well
                this.stop(k) = start(i);
              else                          % this contains start(i) to stop(i) as a subset
                this.start(end+1) = stop(i);
                this.stop(end+1) = this.stop(k);
                this.stop(k) = start(i);
              end
            else                            % this starts second
              if( this.stop(k) < stop(i) )   % this is fully contained in start(i) to stop(i)
                keep(k) = false;
              else                          % this ends second as well
                this.start(k) = stop(i);
              end
            end
          end
          
          % remove sections
          if( any(~keep) )
            this.start = this.start(keep);
            this.stop  = this.stop(keep);

            if( isempty( this.start ) )
              % nothing else left to set false
              return
            end
          end
        end
      end
      
      %% clean up
      [this.start, this.stop] = cleanUp( this, this.start, this.stop );
    end


    %% inplace inverse (logical not)
    function this = invert( this )
        newStart = [-Inf; this.stop ];
        newStop  = [ this.start; Inf];

        if( newStop(1) == -Inf )
          newStart = newStart(2:end);
          newStop = newStop(2:end);
        end

        if( newStart(end) == Inf )
          newStart = newStart(1:end-1);
          newStop = newStop(1:end-1);
        end

        this.start = newStart;
        this.stop  = newStop;
    end

    %% inplace logical and
    function this = and( this, that )
       notThat = InfDimBool( that.start, that.stop );
       notThat.invert();

       this.setFalse( notThat.start, notThat.stop );
    end

    %% inplace logical or
    function this = or( this, that )
       this.setTrue( that.start, that.stop );
    end

    %% get the range
    function [start, stop] = getRange( this )
      start = this.start;
      stop  = this.stop;
    end
    
    %% get the duration
    function dur = getDuration( this )
      dur = sum(this.stop-this.start);
    end

    %% check which ranges in the input overlap with any true values
    function overlap = checkOverlaps( this, start, stop )
       n = numel(start);
       assert( numel(stop)==n );
       overlap = false(n,1);

       for i=1:n
         temp = InfDimBool( start(i), stop(i) );
         dur1 = temp.getDuration();
         temp.setFalse( this.start, this.stop );
         overlap(i) = temp.getDuration() ~= dur1;
       end
    end

    %% private utility function    
    function [start, stop] = cleanUp( this, start, stop )

      %% shape
      start = start(:);
      stop = stop(:);
      
      %% sort
      [start,I] = sort(start);
      stop = stop(I);
      
      %% merge
      num = size(start,1);
      keep = true(num,1);
      for k=2:num
        if( start(k) <= stop(k-1) + this.TOLERANCE )  % check if merge
          keep(k-1) = false;
          start(k) = start(k-1);
          stop(k) = max( stop(k-1:k) );
        end
      end
      %%
      start = start(keep);
      stop  = stop(keep);
      
      %% remove short
      keep = stop - start > 0;
      start = start(keep);
      stop  = stop(keep);
      
    end
    
    
    
  end
  
end
