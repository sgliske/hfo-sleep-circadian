function plot_asym_cyclicity( pIdx, sIdx )
%% function plot_asym_cyclicity( pIdx, sIdx )
%
%
%
%

%% load data
f = load('data/asym_cyclicity.mat');
data = f.data{pIdx,sIdx};

%% prep
fig = gcf;
fig.Position(3:4) = [900 300];

%% 

n = length(data.asym);
x = linspace(0,24,n);
clf

subplot(1,2,1)
I = data.selected;
if( mean(I) < 0.75 )
  I = false(size(I));
end

data.yIn(~I) = nan;
data.yOut(~I) = nan;
h = plot(x,data.yIn,x,data.yOut);
legend({'Within SOZ', 'Without SOZ'}, 'FontSize', 14);

for i=1:2
  h(i).LineWidth = 2;
end
color = colors();
h(2).Color = color.green;
h(1).Color = color.blue;
%h(2).LineStyle = '--';

g = gca;
g.FontSize = 14;
g.Box = 'off';
yL = ylim();
yL = yL*1.5;
g.YLim = yL;
g.XLim = [0 24];
g.XTick = 0:3:24;
xlabel('Time of Day');
ylabel('HFO Rate [#/min]');
addLetter('A',[-0.1 -0.03])

%%
subplot(1,2,2);
data.asym(~I) = nan;
h(1) = plot(x,data.asym);
%ylim([0 0.8])
xlim([0 24])

phi = x/24*2*pi;
yFit = data.alpha * [ones(size(phi)); cos(phi); sin(phi)];
yFit(~I) = nan;

hold on
h(2) = plot( x([1 end]), data.alpha(1)*[1 1])
h(3) = plot( x, yFit );
hold off


legend({'Empirical','Mean asymmetry','24-cyclicity model'},'FontSize',14)

for i=1:length(h)
  h(i).LineWidth = 2;
end
h(2).LineWidth = 1.5;
color = colors();
h(2).Color = color.orange;
h(3).Color = h(2).Color;
h(1).Color = color.black;
h(2).LineStyle = ':';
h(3).LineStyle = '--';

g = gca;
g.FontSize = 14;
g.Box = 'off';
yL = ylim();
yL(2) = yL(2) + 0.1;
ylim(yL);
g.XLim = [0 24];
xlabel('Time of Day');
ylabel('Asymmetry');
g.XTick = 0:3:24;

addLetter('B',[-0.1 -0.03])

%%

print(sprintf('plots/example_circ_asym_%d_%d.svg', pIdx, sIdx),'-dsvg');
