function [ errflag,errstring ] = BIDS_TSV_slam(BIDSdir, METADATAdir)

% overwrite the default 4-column tsv event file created by
% aa_export_toBIDS with auxiliary column metadata
%
% simplified version that assumes aliasing and counterbalancing
% have been handeled by renaming the metadata files using
% counterbalance_metadata_fnames and BIDisfy_metadata_fnames
%
% INPUT:
%
% BIDSdir       - toplevel of BIDS directory (fullpath)
% MEDATDATAdir  - direcectory containing the Peellelab metadata csv files (fullpath)
%                 FILENAMES MUST BE CB CORRECTED AND BIDS ALIASED!
%
% OUTPUT
%
% errflag/errstring (0 == no error)
%
% SIDE EFFECT
%
% overwrites all *_events.tsv files in BIDS directory
%
% HISTORY
%
% 09/2019 [MSJ] - new; simplified from previous version
%


errflag = 0;
errstring = '';

%--------------------------------------------------------------------------
% sanity checks
%--------------------------------------------------------------------------

p = dir(BIDSdir);
if isempty(p)
    errstring =  sprintf('BIDS dirrectory %s not found. Aborting.', BIDSdir);
    errflag = 1;
    return;
end

p = dir(METADATAdir);
if isempty(p)
    errstring =  sprintf('Metadata dirrectory %s not found. Aborting.', METADATAdir);
    errflag = 2;
    return;
end


%--------------------------------------------------------------------------
% make a list of all the tsv event files to be slammed
%--------------------------------------------------------------------------

command = sprintf('find %s  -name \\*_events.tsv', BIDSdir);
[ status,tsv_masterlist ] = system(command);

if (status || isempty(tsv_masterlist))
    errstring =  sprintf('tsv filelist generation failed. Aborting.');
    errflag = 4;
    return;
end

tsv_masterlist = split(tsv_masterlist);

%--------------------------------------------------------------------------
% make a list of all the csv metadata files to slam
%--------------------------------------------------------------------------

command = sprintf('find %s  -name \\*.csv', METADATAdir);
[ status,csv_masterlist ] = system(command);

if (status || isempty(csv_masterlist))
    errstring =  sprintf('csv filelist generation failed. Aborting.');
    errflag = 5;
    return;
end

csv_masterlist = split(csv_masterlist);

%--------------------------------------------------------------------------
% loop over BIDS subjects and /func sessions, overwrite tsv event files
%--------------------------------------------------------------------------

for index = 1:size(tsv_masterlist,1)-1 % "split" adds a blank line ergo "-1"
    
    this_tsv_fname = char(tsv_masterlist(index));
    [ p,n,e ] = fileparts(this_tsv_fname);
    
    temp = split(n,'_');
    
    SID = char(temp(1,:));      % keep 'sub-'
    SESSID = char(temp(2,:));    
    SESSID = SESSID(6:end);     % trim 'task-'
        
    this_csv_fname = lookup_csv_fname(csv_masterlist,SID,SESSID);
    
    if (isempty(this_csv_fname))
        errstring =  sprintf('csv file lookup for %s %s failed. Aborting.', SID, SESSID);
        errflag = 6;
        return;
    end

    % readtable is much better at handling unknown # columns than textscan
    
    % however, turn off its pedantic warning about variable names...
    
    warning('OFF', 'MATLAB:table:ModifiedVarnames') % R2016a version
    warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames') % >R2016a version
        
    CSVcontents = readtable(this_csv_fname);
    
    if (isempty(CSVcontents))
        errstring =  sprintf('Error reading %s. Aborting.', this_csv_fname);
        errflag = 7;
        return;
    end
    
	fprintf('Overwriting %s with data from %s.\n', this_tsv_fname, this_csv_fname);

    % build a new table for output

	tout = CSVcontents(:,2);                                % onset
 	tout = [ tout CSVcontents(:,4) ];                       % duration
	tout = [ tout CSVcontents(:,1) ]; tout{:,3} = 1.0;      % weight
    tout = [ tout CSVcontents(:,3) ];                       % trial_type

  	tout.Properties.VariableNames{1} = 'onset';
	tout.Properties.VariableNames{2} = 'duration';
	tout.Properties.VariableNames{3} = 'weight';
	tout.Properties.VariableNames{4} = 'trial_type';
  
    tout = [ tout CSVcontents(:,5:end) ];   % everything else columns...
    
	% BIDS spec states onset (ET) and duration should be expressed in
    % seconds - Pellelab metadata appears to always be expressed
    % in milliseconds so we need to convert these
    %
    % there's no way of knowing if auxiliary cols have data that requires
    % converting -- need to keep an eye on this.
    
 	fprintf('Converting onsets and durations to seconds.\n');
   
    tout{:,1} = tout{:,1} / 1000;
    tout{:,2} = tout{:,2} / 1000;

    if (1)  % testing - save original tsv file - use a unique suffix for easy delete
	  fprintf('Original events file saved as: %s\n', fullfile(p,[ n '_b4slam' e ]));
      system(sprintf('cp %s %s', this_tsv_fname,  fullfile(p,[ n '_b4slam' e ])));
    end  
    
    writetable(tout, this_tsv_fname, 'FileType', 'text', 'Delimiter', '\t');

end % loop over tsv files  

end % function
  
       

% -------------------------------------------------------------------------
% lookup_csv_fname helper function
% -------------------------------------------------------------------------

function fname = lookup_csv_fname(list_of_csv_fnames, SID, SESSID)

fname = [];
 
for index = 1:size(list_of_csv_fnames,1)
    
    this_fname = list_of_csv_fnames(index);
    
    if (contains(this_fname, SID))
        if (contains(this_fname,SESSID))
            fname = char(this_fname);
            return;
        end
    end
    
end

end
    

    
    
    



