function data = load_glap_h5( filename, groups )
%%
%
%

narginchk(1,2);
if( nargin < 2 )
  groups = [];
end

%% load info

info = h5info(filename);

%% group list

if( ischar(groups) )
    groups = {groups};
end

if( isempty(groups) )
  groups = {info.Groups.Name};
end

for i=1:length(groups)
  if( groups{i}(1) ~= '/' )
    groups{i} = [ '/' groups{i} ];
  end
end

%% load

data = struct();
for i=1:length(groups)
  %%
  info = h5info( filename, groups{i} );
  temp = struct();

  for j=1:length( info.Datasets )
    name = info.Datasets(j).Name;
    temp.(name) = h5read( filename, [ groups{i} '/' name ]);
  end
  data.(groups{i}(2:end) ) = temp;
end


