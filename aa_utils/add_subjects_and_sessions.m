
function [ aap, SID_ADDED, SESS_ADDED ] = add_subjects_and_sessions(aap, datastamp_fname, CB_fname, SID_alias_fname, session_labels_fname)
                                                                                        

% generate aas_addsubject and aas_addsession calls -- simplified version
%
% INPUT:
%
% to make this as error-proof as possible, function ALWAYS takes the
% following auxfiles (this will also be necessary for UAAF)
%
%   1) datastamp_fname -- fullpath to datastamp. Plaintext. Format:
%
%       PL00103 02 7 8 14 16 18 20 etc...
%
%   NOTE: this is the only space-separated auxfile (because bash doesn't play nice w/ csv)        
%
%   2) CB_fname - fullpath to plaintext csv counterbalance file. Example:
%
%       PL000103,1,2,3,4
%       PL000105,2,1,4,3
%       PL000110,2,1,4,3
%       PL000129,1,2,3,4    etc...
%
%   in this example, tasks for subjects 105 and 110 were presented in a different
%   order than in subjects 103 and 129. Their epi data numbers will be shuffled
%   when passed to aas_addsession so that a common session ordering is used for
%   all subjects (in NAMWords1, the two orders are listen,repeat,listen,repeat or 
%   repeat,listen,repeat,listen). The same shuffling must be applied in calls to
%   aas_addevent so that the metadata file order matches the order the epis were
%   added -- the same CB_fname should be passed to make_model
%
%   In here and other comments, the unshuffled order (e.g., 1,2,3,4) is
%   called "null" counterbalancing.
%
%   If there is no counterbalancing in your data, then just write in a null
%   counterbalance order for each subject, i.e.:
%
%       PL000103,1,2,3,4
%       PL000105,1,2,3,4
%       PL000110,1,2,3,4
%       PL000129,1,2,3,4    etc...
%
%   This may seem silly, but forcing the caller to provide this verifies
%   the user has thought about (and documented) the issue in thier data.
%
%   3) SID_alias_fname - fullpath to plaintext comma-separated SID aliases. Example:
%
%       PL000103,sub-01
%       PL000105,sub-02
%       PL000110,sub-03
%       PL000129,sub-04
%
%   (in general each line goes: datastamp-SID,alias-SID)
%
%   As this example suggests, the aliasing is typically used in preparation
%   for BIDS coversion. If you want to keep your original datastamp ID,
%   just do the obvious:
%
%       PL000103,PL000103
%       PL000105,PL000105
%       PL000110,PL000110
%       PL000129,PL000129
%
%   This may seem silly, but forcing the caller to provide this verifies
%   the user has thought about (and documented) the issue in thier data.
%
%   4) session_labels_fname -- fullpath to plaintext session labels. Ex:
%
%       SESS01
%       SESS02
%       SESS03
%       SESS04
%
%   or:
%
%       LISTEN01
%       REPEAT01
%       LISTEN02
%       REPEAT02
%
%   there should be one label for each epi appearing in the datastamp
%   (and there must be the same number of epis for each subject. If you
%   want to do subsets (of sessions or subjects) roll your own add_wawa
%
%   session labels must be UPPERCASE (they will be converted if necessary)
%
%	OUTPUT:
%
%       aap             - modified aap struct
%       SID_ADDED       - list of subjects added (= the (aliased) SID in the datastamp)
%       SESSID_ADDED    - list of session labels added (= contents of the session labels file)
%
%   SIDE EFFECTS
%
%   the generated aa commands are displayed in command window and saved to addsubject.txt in root
%
%   NOTES
%
%	i) If aap.options.autoidentifystructural == false, only T1 is added as a structural file
%       If you want to use both T1 and T2, you must use autoidentifystructural.
%
%   ii) metadata files must be renamed to XXX.ALIAS.SESSIONLABEL.[YYY].cvs
%
%       For example: NP1014_PL00123_SESS01.csv => NP1014_sub-01_LISTEN01.csv
%
%       (fingers crossed that dash in filename doesn't create problems...)
%
% ----------------------------------------------------------------------------------
%
% CHANGE HISTORY
%
%   09/2019 [MSJ] - new (scavenged from previous versions)
%

aas_log(aap, false, sprintf('INFO: running %s', mfilename));

%----------------------------------------------------------------------------------------------------------------
% sanity checks
%----------------------------------------------------------------------------------------------------------------

if (nargin ~= 5)
	aas_log(aap, true, 'Usage:[ aap, SID_ADDED, SESS_ADDED ] = add_subjects_and_sessions(aap, datastamp_fname, CB_fname, SID_alias_fname, session_labels_fname)\n');
end


%----------------------------------------------------------------------------------------------------------------
% start a paper trail 
%----------------------------------------------------------------------------------------------------------------

% this function probably gets called before aa has a chance to make the
% results directory -- check and create it now.

if ~exist(fullfile(aap.acq_details.root, aap.directory_conventions.analysisid),'dir')
	mkdir(aap.acq_details.root, aap.directory_conventions.analysisid);
end

fid = fopen(fullfile(aap.acq_details.root, aap.directory_conventions.analysisid, 'addsubject.txt'),'w');

if (fid < 0)
	aas_log(aap, true, sprintf('%s: Cannot create log file. Exiting...', mfilename));
end

fprintf(fid,'Auto addsubject/addsession (%s.m) %s\n\n', mfilename, datetime);
fprintf(fid,'Saving to logfile %s\n\n', fullfile(aap.acq_details.root, aap.directory_conventions.analysisid, 'addsubject.txt'));

aas_log(aap, false, sprintf('INFO: Saving to logfile %s', fullfile(aap.acq_details.root, aap.directory_conventions.analysisid, 'addsubject.txt')));

% We assume aap.directory_conventions.subject_directory_format = 3 -- make sure it's set:

fprintf(fid,'setting aap.directory_conventions.subject_directory_format to 3\n');

aap.directory_conventions.subject_directory_format = 3;

%----------------------------------------------------------------------------------------------------------------
% read and process session labels (we need this to parse datastamp)
%----------------------------------------------------------------------------------------------------------------

if (~exist(session_labels_fname,'file'))
	fprintf(fid,'Session label file %s not found. Exiting...\n', session_labels_fname); fclose(fid);
	aas_log(aap, true, sprintf('Session label file %s not found. Exiting...\n', session_labels_fname));
end

session_labels = importdata(session_labels_fname);

aas_log(aap, false, sprintf('INFO: Session labels from: %s', session_labels_fname));
fprintf(fid,'\nSession labels from: %s\n\n', session_labels_fname);

for index = 1:numel(session_labels)
    session_labels{index} = upper(session_labels{index});
    aas_log(aap, false, sprintf('INFO: %s', session_labels{index}));
    fprintf(fid,'%s\n\n', session_labels{index});
end

%----------------------------------------------------------------------------------------------------------------
% read and process datastamp
%----------------------------------------------------------------------------------------------------------------

if (~exist(datastamp_fname,'file'))
	fprintf(fid,'Datastamp file %s not found. Exiting...\n', datastamp_fname); fclose(fid);
	aas_log(aap, true, sprintf('Datastamp file %s not found. Exiting...\n', datastamp_fname));
end

aas_log(aap, false, sprintf('INFO: Using datastamp: %s', datastamp_fname));
fprintf(fid,'\nUsing datastamp: %s\n\n', datastamp_fname);

% executive decision: originally, we wanted EVERYTHING to be csv (because
% the (Excel) metadata had to be). However, csv doesn't play nice with
% shell scripts so the ONE exception is the datastamp is assumed to be
% SPACE separated (its just plaintext). This is the default delimiter used
% in importdata().

% temp = importdata(datastamp_fname,',');
temp = importdata(datastamp_fname);

SID_masterlist = temp.textdata;
visit_list = temp.data(:,1);			% careful! this strips leading 0
T1_list = temp.data(:,2);
% T2_list = temp.data(:,3);				% currently unused

% to guard against repeated or not T1/T2 entries, we use the last session-count sessions listed in the datastamp

session_count = numel(session_labels); 
session_list = temp.data(:,end-session_count+1:end);

%----------------------------------------------------------------------------------------------------------------
% read and process counterbalancing into a lookup table
%----------------------------------------------------------------------------------------------------------------

if (~exist(CB_fname,'file'))
	fprintf(fid,'Counterbalancing file %s not found. Exiting...\n', CB_fname); fclose(fid);
	aas_log(aap, true, sprintf('Counterbalancing file %s not found. Exiting...\n', CB_fname));
end

aas_log(aap, false, sprintf('INFO: Using counterbalancing file: %s', CB_fname));
fprintf(fid,'Using counterbalancing file: %s\n\n', CB_fname);
CBLUT = make_counterbalance_lookup_table(CB_fname);
 
% sanity check: make sure there's an CB entry for each SID in the datastamp

if (numel(SID_masterlist) ~=  numel(fieldnames(CBLUT)))
	fprintf(fid,'Warning: datastamp and counterbalancing list have different number of entries.\n');
	aas_log(aap, false, 'WARNING: datastamp and counterbalancing list have different number of entries.\n');
end


%----------------------------------------------------------------------------------------------------------------
% read and process aliasing into a lookup table
%----------------------------------------------------------------------------------------------------------------

if (~exist(SID_alias_fname,'file'))
	fprintf(fid,'SID aliasing file %s not found. Exiting...\n', SID_alias_fname); fclose(fid);
	aas_log(aap, true, sprintf('SID aliasing file %s not found. Exiting...\n', SID_alias_fname));
end

aas_log(aap, false, sprintf('INFO: Using SID aliasing file: %s', SID_alias_fname));
fprintf(fid,'Using SID aliasing file: %s\n\n', SID_alias_fname);
aliasLUT = make_SID_alias_lookup_table(SID_alias_fname);

% sanity check: make sure there's an alias for each SID in the datastamp

if (numel(SID_masterlist) ~=  numel(fieldnames(aliasLUT)))
	fprintf(fid,'Warning: datastamp and SID alias list have different number of entries.\n');
	aas_log(aap, false, 'WARNING: datastamp and SID alias list have different number of entries.\n');
end

for index = 1:numel(SID_masterlist) 
    try
        aliasLUT.(SID_masterlist{index});
    catch
        fprintf(fid,'SID %s not in the alias list. Exiting...\n', SID_masterlist{index}); fclose(fid);
        aas_log(aap, true, sprintf('SID %s not found in the alias list. Exiting...\n', SID_masterlist{index}));
    end
end


%----------------------------------------------------------------------------------------------------------------
% addsubject
%----------------------------------------------------------------------------------------------------------------

% typical addsubject( ) calls for reference (note use of style #3 subject dir)
%
%	aap = aas_addsubject(aap,'PL00135','PL00135_01','structural', 7); % actually, we never don't add epi. Fix?
%	aap = aas_addsubject(aap, 'PL00437', 'PL00437_01', 'functional', [ 14 16 18 20 ]);
%	aap = aas_addsubject(aap, 'PL00437', 'PL00437_01', 'structural', 7, 'functional', [ 14 16 18 20 ]);
%	aap = aas_addsubject(aap, 'sub-01', 'PL00437_01', 'structural', 7,'functional', [ 14 16 18 20 ]);  % note aliasing
%

SID_ADDED = cell(numel(SID_masterlist),1); % this is the SID list we return

for index = 1:numel(SID_masterlist) % SID_masterlist comes from the datastamp
	
    % note we need nested quotes here on the strings so the subsequent command string has them
    
	subject_string = sprintf('''%s''', SID_masterlist{index});
	dir_string = sprintf('''%s_%02d''', SID_masterlist{index}, visit_list(index));
	
	sesslist = session_list(index,:);                       % get session numbers for this SID from the datastamp
	sesslist = sesslist(CBLUT.(eval(subject_string)));      % apply CB (note we must eval subject_string bc quoted)
	sess_string = sprintf('%d ',sesslist);                  % turn integer list of CNDA numbers into a string for sprintf
    
	% replace SID with its alias(don't forget to enclose in quotes)
	% note CBLUT keys are the *original* SID (not the aliases) so
	% translate this *after* applying the CB. Also note: we don't
	% alias dir_string because that's a directory name created during
	% CNDA download (so we need the original SID)

	subject_string = sprintf('''%s''', aliasLUT.(eval(subject_string)));

	if aap.options.autoidentifystructural
 		command = sprintf('aap = aas_addsubject(aap, %s, %s, ''functional'', [ %s]);', subject_string, dir_string, sess_string);
	else
		T1 = T1_list(index);
		command = sprintf('aap = aas_addsubject(aap, %s, %s, ''structural'', %d, ''functional'', [ %s]);', subject_string, dir_string, T1, sess_string);
    end
    
	
	fprintf('%s\n',command);
	fprintf(fid,'%s\n', command);
    
	% we use eval to ensure the aa command is identical to what is written to file and screen
    
	eval(command);
    
	SID_ADDED{index} = eval(subject_string);    % eval here is just to unquote the string

end

%----------------------------------------------------------------------------------------------------------------
% addsession
%----------------------------------------------------------------------------------------------------------------

fprintf(fid,'\nSession Definitions\n\n');
	
%
% typical addsession( ) call for reference:
%
%		aap = aas_addsession(aap, 'SESS01');
%		aap = aas_addsession(aap, 'SESS02');
%

for index = 1:numel(session_labels)
	command = sprintf('aap = aas_addsession(aap,''%s'');', session_labels{index});
	fprintf('%s\n',command);
	fprintf(fid,'%s\n', command);
	eval(command);
end

%----------------------------------------------------------------------------------
% set return values
%----------------------------------------------------------------------------------

% we build SID_ADDED during the addsubject loop; the added
% sessions are just the labels; the added SID are the aliases
% (which we craftily extract from the LUT using struct2cell)

SESS_ADDED = session_labels;


%----------------------------------------------------------------------------------
% close the paper trail and return
%----------------------------------------------------------------------------------

fclose(fid);

% we're done!

end





% -------------------------------------------------------------------------
% make_counterbalance_lookup_table helper function
% -------------------------------------------------------------------------

function LUT = make_counterbalance_lookup_table(fname)

%
%   CB file assumed format (csv):
%
% 	PL00016,1,2,3,4
% 	PL00029,1,4,3,1
% 	PL00033,1,2,3,4
% 	PL00035,2,1,4,3		etc...


temp = importdata(fname,',');

% build a string-indexed struct

for index = 1:numel(temp.textdata)
	LUT.(temp.textdata{index}) = temp.data(index,:);
end

end



% -------------------------------------------------------------------------
% make_SID_alias_lookup_table helper function
% -------------------------------------------------------------------------

function LUT = make_SID_alias_lookup_table(fname)

% SID_cell_array will be either
%
%       name,alias
%
% which we use to build a string-indexed struct:
%
%       aliasLUT.(name) = alias
%

T = importdata(fname,',');

for index = 1:numel(T)
    temp = split(T{index},',');
    LUT.(temp{1}) = temp{2};
end

end





