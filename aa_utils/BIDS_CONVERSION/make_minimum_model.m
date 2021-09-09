function aap = make_minimum_model(aap, subject_IDs, session_names, model_fname)
%
% make a minimum model for BIDS conversion (no contrasts, no parametric
% modeling option)
%
% INPUT
%
%       aap             - the aap struct
%       subject_IDs     - subjects to include in model (e.g., returned from add_subjects_and_sessions)
%       session_names   - sessions to include in model (e.g., returned from add_subjects_and_sessions)
%       model_fname     - model file (fullpath). See parse_model_file.m for format
%
% OUTPUT
%
%	aap - updated aap with events added
%
% NOTES
%
%	Metadata file content is described in the parser.
%
%	PUNCTUATION (except underscore) IS STRIPPED FROM SESSION AND CONDITION
%	NAMES. (Be advised underscores in contrast names makes Matlab plot the
%	text as a subscript, which looks weird but is otherwise harmless).
%
%   Additionally, event names are converted to UPPERCASE
%
% see AVI make model for recent changes that might be helpful to add here
% (like providing a global event duration). Also, if the BIDS spec expands
% to include contrasts, etc, we should expand this also
%
% HISTORY
%
% 09/2021 [MSJ] - new from make_model (stripped contrasts and paramod)
% 01/2020 [MSJ] - added modelModules and contrastModules
% 09/2019 [MSJ] - new; simplifed from previous version
%

aas_log(aap, false, sprintf('INFO: running %s', mfilename));

%----------------------------------------------------------------------------------------------------------------------------
% sanity checks
%----------------------------------------------------------------------------------------------------------------------------

if (nargin ~= 4)
	aas_log(aap, true, sprintf('%s Usage: aap = make_model(aap, subject_IDs, session_names, model_structure)\n', mfilename));
end

if (isempty(subject_IDs) || ~iscell(subject_IDs))
  	aas_log(aap, true, sprintf('%s: subject_IDs must be a cell array of subject IDs. Exiting...\n', mfilename));
end

if (isempty(session_names) || ~iscell(session_names))
  	aas_log(aap, true, sprintf('%s: session_names must be a cell array of session names. Exiting...\n', mfilename));
end

% turn off pedantic Matlab warnings about variable names...

warning('OFF', 'MATLAB:table:ModifiedVarnames') % R2016a version
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames') % >R2016a version


%----------------------------------------------------------------------------------------------------------------------------
% load and unpack model struc
%----------------------------------------------------------------------------------------------------------------------------

if (~exist(model_fname,'file'))
  	aas_log(aap, true, sprintf('%s: Cannot find model file %s. Exiting...\n', mfilename, model_fname));
end

model = [];

[ model,errflag,errstring ] = parse_model_file(model_fname);

if (errflag > 0)
  	aas_log(aap, true, sprintf('parse_model_file returned error: %s. Exiting...\n', errstring));
end


if (~isfield(model,'description'))
    model.description = 'no description provided';
end

MODEL_DESCRIPTION = model.description;

if (~isfield(model,'metadata_directory'))
  	aas_log(aap, true, sprintf('%s: Metadata directory field missing in model struc. Exiting...\n', mfilename));
end

if (~exist(model.metadata_directory,'dir'))
  	aas_log(aap, true, sprintf('%s: Metadata directory %s does not exist. Exiting...\n', mfilename, model.metadata_directory));
end

METADATA_DIRECTORY = model.metadata_directory;

if (isfield(model,'excludedEvents'))
    EVENTS_TO_EXCLUDE = upper(model.excludedEvents);
else
    EVENTS_TO_EXCLUDE = [];
end

if (isfield(model,'columnOrder'))
    columnOrder = model.columnOrder;
else
    columnOrder = [ ];
end


model_has_parametric_modulators = false;

if (isfield(model,'parametric_modulator'))
    
    % process our simple passed struct into the weird struct array aas_addevent expects
        
    if (isfield(model.parametric_modulator,'names'))
        paranames = model.parametric_modulator.names;
        if ~iscell(paranames)
            aas_log(aap, true, sprintf('Parametric modulator names must be entered as a cell array. Exiting...\n'));
        end
    else
        aas_log(aap, true, sprintf('Parametric modulator missing name field. Exiting...\n'));
    end
    
    nmodulators = numel(paranames);
    
	if (isfield(model.parametric_modulator,'metadata_columns'))
        paracols = model.parametric_modulator.metadata_columns;
        if (length(paracols) ~= numel(paranames))
            aas_log(aap, true, sprintf('You must specify a metadata columm for each modulator. Exiting...\n'));
        end
	else
        aas_log(aap, true, sprintf('Parametric modulator missing column field. Exiting...\n'));
    end
  
    if (isfield(model.parametric_modulator,'hs'))
        parah = model.parametric_modulator.hs;
        if ~iscell(parah)
            aas_log(aap, true, sprintf('Parametric modulator polynomial expansion must be entered as a cell array. Exiting...\n'));
        end
    else
        parah = num2cell(ones(nmodulators,1));
    end
    
    if (isfield(model.parametric_modulator,'targets'))
        paratargets = model.parametric_modulator.targets;
        if ~iscell(paratargets)
            aas_log(aap, true, sprintf('Parametric modulator event targets must be entered as a cell array. Exiting...\n'));
        end
    else
        aas_log(aap, true, sprintf('Parametric modulator missing event target field. Exiting...\n'));
    end    
        
	model_has_parametric_modulators = true;

end


%----------------------------------------------------------------------------------------------------------------------------
% process
%----------------------------------------------------------------------------------------------------------------------------

% this function might get called before aa has a chance to make the
% results directory -- check and create it now.

if ~exist(fullfile(aap.acq_details.root, aap.directory_conventions.analysisid),'dir')
	mkdir(aap.acq_details.root, aap.directory_conventions.analysisid);
end

fname = fullfile(aap.acq_details.root, aap.directory_conventions.analysisid, 'model_description.txt');

fid = fopen(fname,'w');

if (fid < 0)
	aas_log(aap, true, 'Cannot create model description log file. Exiting...');
end

aas_log(aap, false, sprintf('INFO: Saving model description to: %s', fname));

fprintf(fid,'Model Description: ');
fprintf(fid,'%s\n\n',MODEL_DESCRIPTION);
fprintf(fid,'Subjects in this model:\n\n');
fprintf(fid,'%s\n', string(subject_IDs));
fprintf(fid,'\nSessions in this model:\n\n');
fprintf(fid,'%s\n', session_names{:});
fprintf(fid,'\n');

fprintf(fid,'\nMetadata directory:\n\n');
fprintf(fid,'%s\n', string(METADATA_DIRECTORY));
fprintf(fid,'\n');

if (isempty(EVENTS_TO_EXCLUDE))
    fprintf(fid,'No excluded events specified -- will add all (non-null) events\n\n');
else
    fprintf(fid,'Excluded events  in this model:\n\n');
    fprintf(fid,'%s ', string(EVENTS_TO_EXCLUDE));
    fprintf(fid,'\n\n');
end

fprintf(fid,'aamod_firstlevel_model options\n');
fprintf(fid,'(this might not reflect tasklist customization)\n\n');

for index = 1:numel(aap.tasksettings.aamod_firstlevel_model)
	fprintf(fid,'=== aamod_firstlevel_model_0000%d ===\n\n', index);
	this_setting = aap.tasksettings.aamod_firstlevel_model(index);
	print_aap(fid,this_setting);
	fprintf(fid,'\n\n');
end


% ------------------------------------------------------------------------------------------------------------
% generate a list of metadata files
% ------------------------------------------------------------------------------------------------------------

% we need to handle both Peelelab- and BIDS-style metadata. The working
% assumption is that the former will be .csv and the latter will be .tsv
% (ergo, point model.metadata_directory at a dedicated directory for
% Peellelab metatdata or simply at the top level BIDS directory for BIDS
% data). We crawl model.metadata_directory using find...

command = sprintf('find %s  -name \\*.csv', model.metadata_directory);
[ status,metadata_fname_master_list ] = system(command);

if (status)
	fprintf(fid, 'Metadata file list generation failed. Exiting...\n'); fclose(fid);
	aas_log(aap, true, sprintf('Metadata file list generation failed. Exiting...\n'));
end

if (isempty(metadata_fname_master_list))
    
    % if we didn't find any .csv files (Peellab metadata), look for .tsv (BIDS metadata)
   
	command = sprintf('find %s  -name \\*_events.tsv', model.metadata_directory);
    [ status,metadata_fname_master_list ] = system(command);

    if (status || isempty(metadata_fname_master_list))
        fprintf(fid, 'Metadata file list generation failed. Exiting...\n'); fclose(fid);
        aas_log(aap, true, sprintf('Metadata file list generation failed. Exiting...\n'));
    end
    
end

% this creates a trailing blank entry but so what

metadata_fname_master_list = split(metadata_fname_master_list);

% careful: convert entries in the master list using char( ) before using, e.g.:
%
%    this_fname = char(metadata_fname_master_list(index));
%    [ p,n,e ] = fileparts(this_fname);
%



% ------------------------------------------------------------------------------------------------------------------------------
% ADDEVENT
% ------------------------------------------------------------------------------------------------------------------------------

fprintf(fid,'\n--- EVENTS ----\n\n');

% new: we no longer do sameforallsessions in addcontrast because that isn't
% general enough for some studies (e.g. readaloud only appears in AVI SESS06)
%
% so we need to add for specific combinations of sessions -- for that we need
% to generate a record of which sessions have which events

EVENTS_IN_THIS_SESSION = cell(numel(session_names),1);
master_event_list = {};

for sindex = 1:numel(subject_IDs) 

	SID = subject_IDs{sindex};

	for bindex = 1:length(session_names) % "bindex" for "block" (sindex in use for "subject")
				       
		SESSION_NAME = session_names{bindex};
		
        % you must put a file "parse_metadata.m" somewhere in your path
        
        % parse_metadata now returns the entire table in auxdata
        % that's the easist way to get at multicolumn auxdata
        % (rather than keeping track of some multicolumn subset)      
        
        % this assumes the correct metadata file is identifiable solely by grepping SID and SESS_ID in the fname

        metadata_fname = lookup_metadata_fname(metadata_fname_master_list, SID, SESSION_NAME);
        
        % sanity check better than crash
        
        if (isempty(metadata_fname))
            aas_log(aap, true, sprintf('Metadata file lookup for %s / %s failed. Aborting...\n', SID, SESSION_NAME));
        end
        
        if (~exist(metadata_fname,'file'))
            aas_log(aap, true, sprintf('Cannot find metadata file %s. Aborting...\n', metadata_fname));
        end         
        
        [ onsets,events,durations,auxdata ] = parse_metadata(metadata_fname, columnOrder);

		% if there was trouble parsing the metadata, the onsets vector will be empty
		
        if (isempty(onsets))
			fprintf(fid,'Parse of %s returned empty onset vector. Aborting...\n', metadata_fname);
			fclose(fid);
			aas_log(aap, true, sprintf('%s: Parse of %s returned empty onset vector. Aborting...', mfilename, metadata_fname));
        end
        
        % note we enforce regression naming in UPPERCASE
        % (this allows 'string' contrast definition -- see addcontrasts)
        
		events = strip_punctuation(events); % ***** no punctuation allowed in event names!!!
        events = upper(events);             % ****** NB: CONVERT TO UPPERCASE to allow string contrast def
        onsets = onsets / model.timebase;   % convert to sec (or whatever) as appropriate

        % EVENTS_OF_INTEREST is the unique events in this sesssion (we identify
        % multiple occurences of each in 'events' to identify the onsets and durs
        % -- see the find(ismember... line below)

        EVENTS_OF_INTEREST = unique(events);

        % remove any events that are explicitly excluded (can be anything, but prolly at least includes NULL)
        % (be sure to convert model.excludedEvents to uppercase)
        
        EVENTS_OF_INTEREST(ismember(EVENTS_OF_INTEREST,upper(model.excludedEvents)))= [];

        % need to keep a record of the per-session events for later contrast def
        %
        % notes:
        %
        % bindex goes 1,2,length(session_subset) whereas b = session_subset(bindex)
        % so could be 2,4,5 whatever -- addcontrast uses the session names, I think
        % it will go:
        %       
        %		SESSION_NAME = session_names{session_names(bindex)};
        %
        % where bindex goes 1 to length(session_subset)
        %       

        EVENTS_IN_THIS_SESSION{bindex} = EVENTS_OF_INTEREST;
        
        master_event_list = { master_event_list{:} EVENTS_OF_INTEREST{:} };

		for eindex = 1:numel(EVENTS_OF_INTEREST)
            
            event_name = EVENTS_OF_INTEREST{eindex};
      			
			rowselector = find(ismember(events,event_name));   % cellspeak for: rowselector = onsets(events==event_name);
				
            if (model.forceZeroDuration)
                durs = 0;
            else
                durs = durations(rowselector) / model.timebase;
            end    
                      
            if (isfield(model,'modelModules'))
            
                for mindex = 1:numel(model.modelModules) 
 
                    aap = aas_addevent(aap, model.modelModules{mindex}, SID, SESSION_NAME, event_name, onsets(rowselector), durs);
                    command_string = sprintf('aap = aas_addevent(aap, ''%s'', ''%s'', ''%s'', ''%s'', [%d onsets+durations]);', model.modelModules{mindex}, SID, SESSION_NAME, event_name, length(rowselector));                  

                    % log to logfile...
                    %
                    % (note we can't do eval(command_string) because command_string
                    % isn't the literal command (we abridge the onsets and durs)

                    fprintf('%s\n', command_string);
                    fprintf(fid,'%s\n', command_string);

                end

            else
            
                % default is to wildcard the call to addevent to so the addevent applies to for all firstlevel_model appearing
                % in tasklist (think: branched analysis). This doesn't hurt anything if there *isn't* multiple occurences.

                aap = aas_addevent(aap, 'aamod_firstlevel_model_*', SID, SESSION_NAME, event_name, onsets(rowselector), durs);
                command_string = sprintf('aap = aas_addevent(aap, ''aamod_firstlevel_model_*'', ''%s'', ''%s'', ''%s'', [%d onsets+durations]);', SID, SESSION_NAME, event_name, length(rowselector));
              
             
                % log to logfile...
                %
                % (note we can't do eval(command_string) because command_string
                % isn't the literal command (we abridge the onsets and durs)

                fprintf('%s\n', command_string);
                fprintf(fid,'%s\n', command_string);
            
            end
 
		end
					
	end
	
end

% done

fclose(fid);

end




% ------------------------------------------------------------------------------------------------------------------------------
% strip_punctuation helper function
% ------------------------------------------------------------------------------------------------------------------------------

function s = strip_punctuation(s)
	
s = regexprep(s,'[^a-zA-Z_0-9+-]','');
	
end



% ------------------------------------------------------------------------------------------------------------------------------
% lookup_metadata_fname helper function
% ------------------------------------------------------------------------------------------------------------------------------

function fname = lookup_metadata_fname(fname_list, SID, SESSID)

fname = [];
 
for index = 1:size(fname_list,1)
    
    this_fname = fname_list(index);
    
    if (contains(this_fname, SID))
        if (contains(this_fname,SESSID))
            fname = char(this_fname);
            return;
        end
    end
    
end

end
    






