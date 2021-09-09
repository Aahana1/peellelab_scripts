
function [ errflag,errstring ] = counterbalance_metadata_fnames(METADATAdir, new_session_names, CB_fname)

% rename metadata files according to counterbalancing so we don't have to
% keep dragging around counterbalancing in add_model and other tools
% (after add_subjects_and_sessions we can ignore CB as long as we fix
% the metadata fnames)
%
% usage:
%
% [ errflag,errstring ] = counterbalance_metadata_fnames(METADATAdir, new_session_names, CB_fname)
%
% NB: run this *BEFORE* BIDSify_metadata_fnames (because we need the PLID 
% in the filename to lookup the counterbalancing)
%
% INPUT
%
% METADATAdir - fullpath to directory containing the peellelab .csv metadata files to rename
%
% new_session_names -- the new, (presumably) more meaningful, session names
% presented in null counterbalance order. This can be a cell or a fullpath
% to an session label auxfile. Cell example:
%
%   new_session_names = { 'LISTEN01', 'REPEAT01', 'LISTEN02', 'REPEAT02' }
%
% note the session names in the metadata files should be 'SESS01',
% 'SESS02', 'SESS03', etc as collected in chronological order. These
% are what we rename using 'new_session_names'
%
% OPTIONAL
%
% CB_fname - standard csv counterbalance file. Example format:
% 
%     PL00016,1,2,3,4
%     PL00026,2,1,4,3
%     PL00027,2,1,4,3
%     PL00029,2,1,4,3 etc.
%
% if no CB file is provided, we don't reshuffle the metadata files 
% (but they will get renamed using 'new_session'names')
%
% sanity check: if new_session_names are the orignal session names
% ('SESS01','SESS02',etc) and there is no counterbalancing, calling
% this function on your metadata should have no effect.
%
% HISTORY
%
% 12/2019 [MSJ] - minor cleanup
% 09/2019 [MSJ] - new
%

%--------------------------------------------------------------------------
% init
%--------------------------------------------------------------------------

% this function is destructive -- verify before running

reply = input('This will rename all .csv files in directory. Continue? Y/N [N]:','s');
if isempty(reply)
  reply = 'N';
end
    
if ~strcmp(reply,'Y')
    errstring = 'User aborted...';
    errflag = 1;
    return;
end

if (nargin < 3)
    CB_fname = [];
end

errstring = 'No error.';
errflag = 0;


%--------------------------------------------------------------------------
% session renaming init
%--------------------------------------------------------------------------

if (~iscell(new_session_names))

    % assume new_session_names is an fname
    
    if (~exist(new_session_names,'file'))
        errstring = sprintf('Passed session_names appears to be a file but %s was not found. Exiting...\n', new_session_names);
        errflag = 1;
        return;
    end
    
    % overwrite
    
    temp = new_session_names;
    clear(new_session_names);
    new_session_names = importdata(temp);
    
end


% session names should be uppercase

new_session_names = upper(new_session_names);

% build S_N_A_S on the fly (it depends on the number of sessions -- cf. NAM v AV)

SESSION_NAMES_IN_SCAN_ORDER = cell(numel(new_session_names),1);

for index = 1:numel(new_session_names)
    SESSION_NAMES_IN_SCAN_ORDER{index} = sprintf('SESS%02d',index);
end


%--------------------------------------------------------------------------
% counterbalancing init
%--------------------------------------------------------------------------

CBLUT = [];

if (~isempty(CB_fname))
    if (~exist(CB_fname,'file'))
        errstring = sprintf('Counterbalancing file %s not found. Exiting...\n', CB_fname);
        errflag = 1;
        return;
    end
    fprintf('Using counterbalancing file: %s\n', CB_fname);
    CBLUT = make_counterbalance_lookup_table(CB_fname);
end


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
    
    SID = char(temp(2,:));
    SESSNAME = char(temp(3,:));
    
    if (isempty(CBLUT))
        new_SESSNAME = new_session_names{find(contains(SESSION_NAMES_IN_SCAN_ORDER,SESSNAME))};
    else
        new_SESSNAME = new_session_names{CBLUT.([SID '_' SESSNAME])};
    end
    
    new_name = strrep(old_name, SESSNAME, new_SESSNAME);
    new_fname = fullfile(p,[new_name e]);

    fprintf('Renaming \t %s\nto \t\t %s\n\n', fname, new_fname); 

end

% now actually rename the files if we get to here w/o crashing

for index = 1:size(csv_masterlist,1)-1   % "split" adds a blank line ergo "-1"
    
    fname = char(csv_masterlist(index));
    [ p,old_name,e ] = fileparts(fname);
    
    temp = split(old_name,'_');
    
    SID = char(temp(2,:));
    SESSNAME = char(temp(3,:));
    
    if (isempty(CBLUT))
        new_SESSNAME = new_session_names{find(contains(SESSION_NAMES_IN_SCAN_ORDER,SESSNAME))};
    else
        new_SESSNAME = new_session_names{CBLUT.([SID '_' SESSNAME])};
    end
    
    new_name = strrep(old_name, SESSNAME, new_SESSNAME);
    new_fname = fullfile(p,[new_name e]);
    
    % sanity check: movefile won't copy a file onto itself
    % -- if true, doing nothing is the correct move
    
    if ~strcmp(fname,new_fname)
        
        [ SUCCESS,MESSAGE,~ ] = movefile(fname, new_fname);

        if (SUCCESS ~= 1)
            fprintf('Move of %s to %s failed. (%s). Continuing...\n', old_name, new_name, MESSAGE);
            errflag = 1;
            errstring = 'Some files not renamed';
        end
    
    end

end







% -------------------------------------------------------------------------
% make_counterbalance_lookup_table helper function
% -------------------------------------------------------------------------

function LUT = make_counterbalance_lookup_table(fname)

% table is assumed csv format:
%
% 	PL00016,1,2,3,4
% 	PL00029,2,1,4,3 	etc...
%
% we convert this into a lookup table:
%
%    LUT.(PL00016_SESS01) = 1;
%    LUT.(PL00016_SESS02) = 2;
%    LUT.(PL00016_SESS03) = 3;
%    LUT.(PL00016_SESS04) = 4;
%    LUT.(PL00029_SESS01) = 2;
%    LUT.(PL00029_SESS02) = 1;
%    LUT.(PL00029_SESS03) = 4;
%    LUT.(PL00029_SESS04) = 3;     etc
%
% we then use the value returned by the lookup table key as the index
% into the *new* session names. (We use SESSION_NAMES_IN_SCAN_ORDER
% as part of the key because we extract these from the metadata
% filename to determine how to properly rename the file.)

T = importdata(fname,',');

% build a string-indexed struct

for index1 = 1:numel(T.textdata)
    for index2 = 1:numel(SESSION_NAMES_IN_SCAN_ORDER)
        LUT.([T.textdata{index1} '_' SESSION_NAMES_IN_SCAN_ORDER{index2}]) = T.data(index1,index2);
    end
end


end

% we need to nest make_counterbalance_lookup_table to access
% SESSION_NAMES_IN_SCAN_ORDER as a local "global" variable
% - ergo move "end" to here

end
