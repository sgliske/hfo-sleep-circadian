function [x_,y_] = circKDE( x, period, n )
%% function [x_,y_] = circKDE( x, period, n )
%
% KDE with circular boundary conditions
%
%

% density
x_ = linspace( -period, period, 2*n + 1 );
[y_,~,bw] = ksdensity( mod(x+period/2,period)-period/2, x_ );

% reduce bandwidth if needed
thres = 0.001;
while( y_(1) > thres || y_(end) > thres )
  bw = bw * 0.99;
  [y_,~,bw] = ksdensity( mod(x+period/2,period)-period/2, x_, 'Bandwidth', bw );
end

% boundary conditions
x_ = x_(n+1:2*n);
y_ = y_(1:n) + y_(n+1:2*n);

%if( y_(1) == 0 && y_(end) == 0 )
  % simple case, only one wrapping needed
  %y_ = y_(1:2*n) + [y_(n+1:2*n) y_(1:n)];
  %x_ = x_(1:2*n);
  %x_ = x_(n+1:end);
  %y_ = y_(n+1:end);

 % y_ = y_(1:n) + y_(n+1:2*n);
%else
  % more than one wrapping needed
%  bin = [1:n 1:n];
%  y_ = accumarray( bin(:), y_(1:end-1), [], @mean )';
%end


