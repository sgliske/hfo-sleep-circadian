function scatter_bar( X, labels, doTests, xlimits )
%%
%
%
%


hold off;
h = barh(fliplr(nanmedian(X)));
h.FaceColor = [1 1 1]*0.9;
h.BarWidth = 0.6;
hold on;

[n1,n2] = size(X);
Y = rand(n1,n2)*0.3 - 0.1 + (n2:-1:1);
scatter( X(:), Y(:), 10, 'b', 'filled','o');

if( nargin < 4 )
  xlimits = xlim();
end

yticks(1:n2);
yticklabels(flip(labels))

for j=2:n2
  line(xlimits, [1 1]*j-0.5, 'color', [1 1 1]*0.5);
end
xlim(xlimits)
ylim([0.5 n2+0.5]);

if( doTests )
  for i=1:n2
    p = signrank( X(:,i) );

    fprintf('%0.3f/%d %s\n', p, n2, labels{i} );

    nStars = 0;
    if( p<0.05/n2 )
      nStars = nStars + 1;
    end
    if( p<0.01/n2 )
      nStars = nStars + 1;
    end
    if( p<0.001/n2 )
      nStars = nStars + 1;
    end

    scatter( xlimits(2)-(1:nStars)*range(xlimits)/30, ones(1,nStars)*(n2+1-i),20,'r','*');

  end
end
