function T1 = get_electrode_channel_table( patientID, sesID )
%% function T1 = get_electrode_channel_table( patientID, sesID )
%
% Loads the channels and electrodes tsv files and makes one single
% table. Make sure the function "get_database_base_path" is in the
% search path or current folder before calling this function.
%
%

if( nargin < 2 )
  sesID = 'all';
end

%% determine the path to the other codes based on institution and OS

%% 

base_path = get_database_base_path();
base_path = fullfile( base_path, 'rawdata', ['sub-' patientID ] );

if( strcmp( sesID, 'all' ) )  
  query = fullfile( base_path, 'ses-ieeg*');
  dirlist = dir( query );
  nSes = length(dirlist);
  assert( nSes == 1, 'Number of sessions is not one.' ); % update code if this ever becomes not true
  
  sesID = dirlist(1).name(5:end);

  T1 = get_electrode_channel_table( patientID, sesID );
  return

end

%% electrodes

base_path = fullfile( base_path, ['ses-' sesID], 'ieeg' );
query = fullfile( base_path, '*electrodes.tsv' );
filelist = dir(query);
assert( length(filelist) == 1, 'Not exactly one *electrode.tsv file' );

T1 = read_tsv( fullfile( base_path, filelist(1).name ) );

%% channels

query = fullfile( base_path, '*channels.tsv' );
filelist = dir(query);
assert( ~isempty(filelist), 'No *channels.tsv files' );

for i=1:length(filelist)
  %%
  T2 = read_tsv( fullfile( base_path, filelist(i).name ) );

  if( ~iscell( T2.status_description ) )
    assert( all(isnan(T2.status_description)), 'odd status' );
    T2.status_description = cell( height(T2), 1 );
  end
  assert( iscell( T2.status_description ));

  idx = cellfun( @(name) find(strcmp( T1.name, name )), T2.name, 'UniformOutput', false );

  L = cellfun( @length, idx );
  if( any(L==0) )
      T2.name(L==0)
      assert( false, 'Missing rows in electrodes file (see %s)', filelist(i).name)
  end

  if( any(L>1) )
      T2.name(L>1)
      assert( false, 'Error in channel names for %s', filelist(i).name )
  end

  %%
  idx = cell2mat(idx);
  assert( length(idx) == sum(L==1), 'Error in channel names for %s', filelist(i).name )

  %%
  fn1 = fieldnames( T1 );
  fn2 = fieldnames( T2 );
  fn1 = setdiff( fn1, {'Properties','Row','Variables','name'});
  fn2 = setdiff( fn2, {'Properties','Row','Variables','name'});
  
  isIn = ismember( fn2, fn1 );
  for j = 1:length(fn2)
      %%
      if( isIn(j) )
        for k=1:length(idx)
          if( iscell( T1.(fn2{j})) )

            % cells of strings

            old_value = T1.(fn2{j}){idx(k)};
            new_value = T2.(fn2{j}){k};

            if( isempty(old_value) )
              T1.(fn2{j}){idx(k)} = new_value;
            else
              if( ~strcmp( old_value, new_value ))
                T1(idx(k),:)
                T2(k,:)
              end

              assert( strcmp( old_value, new_value ), 'Inconsistant values: %s %s %d %s %d %s (%s)\n', T2.name{k}, fn2{j}, idx(k), old_value, k, new_value, filelist(i).name );
            end

          else
            % vectors of numbers
            old_value = T1.(fn2{j})(idx(k));
            new_value = T2.(fn2{j})(k);

            if( isnan( old_value) )
              T1.(fn2{j})(idx(k)) = new_value;
            else
              assert( new_value == old_value, 'Inconsistant values: %s %d %f %d %f\n', fn2{j}, idx(k), old_value, k, new_value );
            end
          end
        end

      else
        % not yet set

        if( iscell( T2.(fn2{j} )))
          T1.(fn2{j}) = cell(height(T1),1);
        else
          T1.(fn2{j}) = nan(height(T1),1);
        end
        T1.(fn2{j})(idx) = T2.(fn2{j});
      end
  end

end
