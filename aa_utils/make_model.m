
function aap = make_model(aap, subject_IDs, session_names, model_fname)

%
% do addevents (and, optionally, addcontrasts) for AVI first-level model
%
% INPUT
%
%       aap                         - the aap struct
%       subject_IDs                 - subjects to include in model (e.g., returned from add_subjects_and_sessions)
%       session_names               - sessions to include in model (e.g., returned from add_subjects_and_sessions)
%       model_fname                 - model file (fullpath). See parse_model_file.m for format
%
% OUTPUT
%
%	aap - updated aap with events and (optionally) contrasts added
%
% NOTES
%
%   Metadata files are csv and should conform to the naming convention:
%
%		[wawa]_SID_SESSIONNAME_[wawa].csv
%
%   as long as the name includes the SID and session name it's fine
%   (in the old style, we enforced rigid naming -- here just include the
%   subject and session. You can always put different kinds of metadata
%   (e.g. condition vs. item) in different .metadata_directories
%
%	Metadata file content is described in the parser.
%
%	PUNCTUATION (except underscore) IS STRIPPED FROM SESSION AND CONDITION
%	NAMES. (Be advised underscores in contrast names makes Matlab plot the
%	text as a subscript, which looks weird but is otherwise harmless).
%
%   Additionally, event names are converted to UPPERCASE

%
% HISTORY
%
%   09/2019 [MSJ] - new; simplifed from previous version
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


has_parametric_modulator = false;

if (isfield(model,'parametric'))
    
    % process our simple passed struct into the weird struct array aas_addevent expects
        
    if (isfield(model.parametric,'names'))
        paranames = model.parametric.names;
        if ~iscell(paranames)
            aas_log(aap, true, sprintf('Parametric modulator names must be entered as a cell array. Exiting...\n'));
        end
    else
        aas_log(aap, true, sprintf('Parametric modulator missing name field. Exiting...\n'));
    end
    
    nmod = numel(paranames);
    
	if (isfield(model.parametric,'cols'))
        parauxcols = model.parametric.cols;
        if ~iscell(parauxcols)
            aas_log(aap, true, sprintf('Parametric modulator columms must be entered as a cell array. Exiting...\n'));
        end
    else
        aas_log(aap, true, sprintf('Parametric modulator missing column field. Exiting...\n'));
    end
  
    if (isfield(model.parametric,'hs'))
        parah = model.parametric.hs;
        if ~iscell(parah)
            aas_log(aap, true, sprintf('Parametric modulator polynomial expansion must be entered as a cell array. Exiting...\n'));
        end
    else
        parah = num2cell(ones(nmod,1));
    end
    
    placeholder = cell(1,nmod);
    
    parametric = struct('name', paranames, 'P', placeholder, 'h', parah);
    
   has_parametric_modulator = true;

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
	fprintf(fid,'=== aamod_firstlevel_model_000%d ===\n\n', index);
	temp = aap.tasksettings.aamod_firstlevel_model(index);
	print_aap(fid,temp);
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

        % need to keep a record of the per-session events for contrast def
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
      			
			temp = find(ismember(events,EVENTS_OF_INTEREST(eindex)));   % cellspeak for: temp = onsets(events==eindex);
				
            if (model.forceZeroDuration)
                durs = 0;
            else
                durs = durations(temp) / model.timebase;
            end
            
            % note we wildcard to define for all firstlevel_model appearing
            % in tasklist (think: branched analysis). This doesn't
            % hurt anything if there *isn't* multiple occurences.

             if (has_parametric_modulator)
                
                % copy data for this event into the modulator struct
                
                for mindex = 1:nmod
                    parametric(mindex).P = auxdata{temp,parauxcols{mindex}};
                end
                    
                aap = aas_addevent(aap, 'aamod_firstlevel_model_*', SID, SESSION_NAME, EVENTS_OF_INTEREST{eindex}, onsets(temp), durs, parametric);   
                command_string = sprintf('aap = aas_addevent(aap, ''aamod_firstlevel_model_*'', ''%s'', ''%s'', ''%s'', [%d onsets+durations+modulation]);', SID, SESSION_NAME, EVENTS_OF_INTEREST{eindex}, length(temp));

             else
                
                aap = aas_addevent(aap, 'aamod_firstlevel_model_*', SID, SESSION_NAME, EVENTS_OF_INTEREST{eindex}, onsets(temp), durs);
                command_string = sprintf('aap = aas_addevent(aap, ''aamod_firstlevel_model_*'', ''%s'', ''%s'', ''%s'', [%d onsets+durations]);', SID, SESSION_NAME, EVENTS_OF_INTEREST{eindex}, length(temp));
                
             end
             
            % log to logfile...
            %
            % (note we can't do eval(command_string) because command_string
            % isn't the literal command (we abridge the onsets and durs)
           
            fprintf('%s\n', command_string);
            fprintf(fid,'%s\n', command_string);
 
		end
					
	end
	
end


% ------------------------------------------------------------------------------------------------------------------------------
% 3) ADDCONTRAST
% ------------------------------------------------------------------------------------------------------------------------------

if ((model.addUnaryContrasts == false) && isempty(model.contrasts))
    fclose(fid);
    return;     
end

if ~isfield(aap.tasksettings,'aamod_firstlevel_contrasts')
    fclose(fid);
    aas_log(aap, true, sprintf('You must include aamod_firstlevel_contrasts in the tasklist to define contrasts. Exiting...'));
end

fprintf(fid,'\n--- CONTRASTS ----\n\n');

fprintf(fid,'aamod_firstlevel_contrasts options\n');
fprintf(fid,'(this might not reflect tasklist customization)\n\n');

for index = 1:numel(aap.tasksettings.aamod_firstlevel_model)
    fprintf(fid,'=== aamod_firstlevel_contrasts_000%d ===\n\n', index);
    temp = aap.tasksettings.aamod_firstlevel_contrasts(index);
    print_aap(fid,temp);
    fprintf(fid,'\n\n');
end

    
if (isfield(model,'contrasts') && ~isempty(model.contrasts))
    
	contrast_subject_selector = '*';
    contrast_type = 'T';

    for index = 1:length(model.contrasts.defs)
 
        % create a label based on the contrast def
        
% % %         contrast_label = model.contrasts.defs{index};
% % %          
% % %         % contrasts defs have syntax like '+1LISTENWORD|-1xLISTENNOISE'
% % %         % need to swap out special characters to avoid filenaming weirdness
% % %         
% % %         contrast_label = strrep(contrast_label,'+','P');
% % %         contrast_label = strrep(contrast_label,'-','M');
% % %         contrast_label = strrep(contrast_label,'|','_O_');
        
 % new - just have the user name the contrast...
 contrast_label = model.contrasts.names{index};
 
                
        contrast_vector = model.contrasts.defs{index};
        contrast_session_selector = model.contrasts.sessions{index};
 
        fprintf(fid,'\nUser-defined Contrast: %d\n', index);
        fprintf(fid,' subject selector: %s\n', contrast_subject_selector);
        fprintf(fid,' session selector: %s\n', contrast_session_selector);
        fprintf(fid,' contrast type: %s\n', contrast_type);
        fprintf(fid,' contrast label: %s\n', contrast_label);
        fprintf(fid,' contrast vector: %s\n', contrast_vector);
        fprintf(fid,'\n');
        
        fprintf('\nUser-defined Contrast: %d\n', index);
        fprintf(' subject selector: %s\n', contrast_subject_selector);
        fprintf(' session selector: %s\n', contrast_session_selector);
        fprintf(' contrast type: %s\n', contrast_type);
        fprintf(' contrast label: %s\n', contrast_label);
        fprintf(' contrast vector: %s\n', contrast_vector);
        fprintf('\n');


        % include aamod_firstlevel_contrasts_* wildcard to handle multiple 
        % occurences of module in tasklist (think: branched analysis)

 
        aap = aas_addcontrast(aap, ...
                                'aamod_firstlevel_contrasts_*', ...
                                    contrast_subject_selector, ...
                                        contrast_session_selector, ...
                                            contrast_vector, ...
                                                contrast_label, ...
                                                    contrast_type );


    end
    
end



if (model.addUnaryContrasts == true)

    % add one contrast for each condition, in same order as events

    master_event_list = unique(master_event_list);

    contrast_subject_selector = '*';
    contrast_type = 'T';

    for index = 1:numel(master_event_list)

        % contrast name is simply the event name

        contrast_label = master_event_list{index};
        contrast_vector = sprintf('+1x%s',contrast_label);

        % identify which sessions this event appears in

        contrast_session_selector = '';

        for bindex = 1:length(session_names)
            if (ismember(contrast_label, EVENTS_IN_THIS_SESSION{bindex}))
                SESSION_NAME = session_names{bindex};
                if (isempty(contrast_session_selector))
                    contrast_session_selector = [ 'sessions:' SESSION_NAME];
                else
                    contrast_session_selector = [ contrast_session_selector '+' SESSION_NAME ];
                end
            end
        end
        
        % CHECK -- if contrast appears in only one session, do we need to
        % change to singlesession:wawa not sessions:wawa?
        %
        % UPDATE: either works

        fprintf(fid,'\nUnary Contrast: %d\n', index);
        fprintf(fid,' subject selector: %s\n', contrast_subject_selector);
        fprintf(fid,' session selector: %s\n', contrast_session_selector);
        fprintf(fid,' contrast type: %s\n', contrast_type);
        fprintf(fid,' contrast label: %s\n', [ 'C_' contrast_label]);
        fprintf(fid,' contrast vector: %s\n', contrast_vector);
        fprintf(fid,'\n');

        fprintf('\nUnary Contrast: %d\n', index);
        fprintf(' subject selector: %s\n', contrast_subject_selector);
        fprintf(' session selector: %s\n', contrast_session_selector);
        fprintf(' contrast type: %s\n', contrast_type);
        fprintf(' contrast label: %s\n', [ 'C_' contrast_label]);
        fprintf(' contrast vector: %s\n', contrast_vector);
        fprintf('\n\n');

        % include aamod_firstlevel_contrasts_* wildcard to handle multiple 
        % occurences of module in tasklist (think: branched analysis)

        % adding a "C_' prefix to unary contrast label helps differentiate
        % it from event name in diagnostic plots, etc

        aap = aas_addcontrast(aap, ...
                                'aamod_firstlevel_contrasts_*', ...
                                    contrast_subject_selector, ...
                                        contrast_session_selector, ...
                                            contrast_vector, ...
                                                [ 'C_' contrast_label ], ...
                                                    contrast_type);

    end



end


fclose(fid);
return;


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
    






