
function [ errflag,errstring ] = BIDSify_metadata_fnames(METADATAdir, PL2BIDSID_fname)

% replace Peellelab SID in metadata filesnames with generic BIDS sub-xx identifiers
%
% NB: run this AFTER counterbalance_metadata_fnames (because counterbalance file uses PLID
% (which will no longer work if you swap out the PLID for BIDS ID in the fnames!)
%
% usage:
%
% [ errflag,errstring ] = BIDSify_metadata_fnames(METADATAdir, PL2BIDSID_fname)
%
% INPUT
%
% metadata_dir - directory containing the .csv metadata files to rename
%
% PL2BIDSID_fname - fname containing Pellelab to BIDS ID table. Format:
%
%     PL00016,sub-01
%     PL00026,sub-02    etc...
%
% HISTORY
%
% 12/2019 [MSJ] minor cleanup
% 09/2019 [MSJ] - new
%


%--------------------------------------------------------------------------------------------------------
% init
%--------------------------------------------------------------------------------------------------------

reply = input('Warning: Run this AFTER running counterbalance_metadata_fnames. Continue? Y/N [N]:','s');
if isempty(reply)
  reply = 'N';
end
    
if ~strcmp(reply,'Y')
    errstring = 'User aborted...';
    errflag = 1;
    return;
end

errstring = 'No error.';
errflag = 0;

%--------------------------------------------------------------------------
% SID lookup table 
%--------------------------------------------------------------------------

p = dir(PL2BIDSID_fname);
if isempty(p)
    errstring =  sprintf('PL2BIDS lookup file %s not found. Aborting.', PL2BIDSID_fname);
    errflag = 3;
    return;
end

PL2BIDSLUT = make_BIDSID_lookup_table(PL2BIDSID_fname);


%--------------------------------------------------------------------------
% get a list of all csv files in METADATAdir
%--------------------------------------------------------------------------

command = sprintf('find %s  -name \\*.csv', METADATAdir);
[ status,csv_masterlist ] = system(command);

if (status || isempty(csv_masterlist))
	errstring = sprintf('csv filelist generation failed. Aborting.');
    errflag = 1;
    return;
end

csv_masterlist = split(csv_masterlist);

%--------------------------------------------------------------------------
% loop over csv files, rename
%--------------------------------------------------------------------------

% do as 2 passes just to be safe -- first pass will flush out any LUT
% issues (better this crashes on a first pass rather than leaving a mix
% of renamed and not-renamed files...)

for index = 1:size(csv_masterlist,1)-1   % "split" adds a blank line ergo "-1"
    
    fname = char(csv_masterlist(index));
    [ p,old_name,e ] = fileparts(fname);
    
    temp = split(old_name,'_');
    
    PLID = char(temp(2,:));
	BIDSID = PL2BIDSLUT.(PLID);  
    
    new_name = strrep(old_name, PLID, BIDSID);
    new_fname = fullfile(p,[new_name e]);

end

% now actually rename the files if we get to here w/o crashing

for index = 1:size(csv_masterlist,1)-1   % "split" adds a blank line ergo "-1"
    
    fname = char(csv_masterlist(index));
    [ p,old_name,e ] = fileparts(fname);
    
    temp = split(old_name,'_');
    
    PLID = char(temp(2,:));
	BIDSID = PL2BIDSLUT.(PLID);  
    
    new_name = strrep(old_name, PLID, BIDSID);
    new_fname = fullfile(p,[new_name e]);

    [ SUCCESS,MESSAGE,~ ] = movefile(fname, new_fname);

    % sanity check: movefile won't copy a file onto itself
    % -- if true, doing nothing is the correct move
    
    if ~strcmp(fname,new_fname)
        
        if (SUCCESS ~= 1)
            fprintf('Move of %s to %s failed. (%s). Continuing...\n', old_name, new_name, MESSAGE);
            errflag = 1;
            errstring = 'Some files not renamed';
        else
            fprintf('Renaming \t %s\nto \t\t %s\n\n', fname, new_fname);    
        end
    
    end

end


end



%--------------------------------------------------------------------------
function LUT = make_BIDSID_lookup_table(fname)
%--------------------------------------------------------------------------

% return a string-indexed struct for BIDS/PL ID conversion
%
%  fname contants is csv of Peellelab ID pairs:
%
% 	PL00001,sub-01
% 	PL00016,sub-02
%
%		etc...
%
% we assume caller checked that the file exists

temp = importdata(fname,',');

LUT = [];

for index = 1:numel(temp)
	s = temp{index};
	s = split(s,',');
	LUT.(s{1}) = s{2};
end

end



