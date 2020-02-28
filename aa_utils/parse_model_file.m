function [ model,errflag,errstring ] = parse_model_file(model_fname)

% INPUT
%
%       model_fname - fname (fullpath) to model definition file
%
% OUTPUT
%
%       model - properly formatted aax model struct
%
% MODEL DEFINITION FIELDS
%
%       description          - [optional] description of model (printed to log)  
%
% METADATA
%
%       metadata_directory   - NONBIDS: fullpath to single directory holding all the subject/session csv metadata
%                              BIDS: top level of BIDS data (make_model will drill down and find all the .tsv files)
%       excludedEvents       - events in the metadata NOT to model(empty == model all events; typically we exclude NULL events
%       timebase             - onsets and durations are divided by this to get seconds (use 1000 if expressed in milliseconds)
%       forceZeroDuration    - set duration = 0 in addevent (regardless of what metadata file says)
%       columnOrder          - column order of onsets, event name, event duration in metadata file
%                              NB: column order is generally different in Peelle lab csv and BIDS tsv files
%
% MODULE SELECTION
%
%       modelModules         - cell array of modeling modules to process. Default: aamod_firstlevel_model_*
%
% CONTRASTS
%
%       addUnaryContrasts    - true == add a +1 contrast for each(non-excluded) event defined in metadata
%       contrasts.defs       - optional custom explicit contrasts in +1xWawa format
%       contrasts.sessions   - session selector (one for each entry in .defs) 
%                              ('sameforallsessions' or 'sessions:SESS01+SESS02' etc)
%       contrastModules      - cell array of specific contrast modules to process
%                              (usually to turn off wildcarding). Default: aamod_firstlevel_contrasts_*
%
% PARAMETRIC MODULATOR(s)
%
%       parametric_modulator.names            - parametric modulator names (1D CELL ARRAY - one per modulator)
%       parametric_modulator.metadata_columns - metadata spreadsheet columns defining the modulator 
%                                               (enter as 1D cell array; returned as vector)
%       parametric_modulator.targets - events the corresponding modulator applies to (array of cell arrays)
%
% EXAMPLE
%
%       description          = 'NAMWORDS1 w/ motion correction';   
%       metadata_directory   = '/Users/peellelab/DATA/NAMWORDS/METADATA_04_16/fiveconditioncode';
%       excludedEvents       = { 'NULL' };
%       timebase             = 1000;
%       forceZeroDuration    = 'true';
%       columnOrder          = { 2,3,4 };
%       contrasts.defs       = { '+1xLISTENWORD|-1xLISTENNOISE' , '+1xREPEATCORRECT|-1xREPEATNOISE' } 
%       contrasts.sessions   = { 'sessions:SESS01+SESS03' , 'sessions:SESS02+SESS04' };
%       contrastModules      = { 'aamod_firstlevel_contrasts_00001','aamod_firstlevel_contrasts_00003' }
%       modelModules         = { 'aamod_firstlevel_model_00001','aamod_firstlevel_model_00003' }
%       parametric_modulator.names = { 'DENSITY', 'FREQUENCY' , 'RESPONSETIME' };
%       parametric_modulator.metadata_columns = { 8,11,13 };
%       parametric_modulator.targets = { { 'LISTENWORD', 'REPEATWORD' } , { 'LISTENWORD', 'REPEATWORD'}  , { 'REPEATWORD' } };
%
%   when specifying a contrast involving a modulator, the identifier is 'EVENTNAMExMODULATORNAME^1'
%   (e.g., '+1xLISTENNOISExCONCRETENESS^1')
%
% GENERAL FORMATING NOTES
%
%   1) any string quantities (including 'true' & 'false' and cell contents) must be in single quotes
%   2) any vectors should be entered as a cell array (i.e., curly-brackets)
%      (vanilla arrays are converted internally - this so the user need not 
%       know/care what is a cell and what is not -- *everything* is a cell array)
%   3) all cell array contents should be comma separated
%   4) there should be no repeated entries
%   5) entries w/ subfields must all have same number of entries (e.g. contrasts.defs & constrasts.sessions)
%   6) the usual good-naming practices apply: no spaces, no special characters
%   7) events, sessions, contrast, and modulator names must be uppercase
%      -- we enforce this using upper() where we can (TODO: contrast defs and sessions)
%   8) blank lines are allowed
%   9) any line starting with '% =' is treated as a comment and is ignored (see note below)
%   10) we don't error check constrast defs (because difficult to do generally)
%
% Note on comments: To keep Matlab readtable happy, every (non-blank)
% line should contain one (and only one) equals sign ("="). As such,
% comments should begin with "% =" not "%". OTOH, if you comment out an
% assignment (e.g., because you might use it in the future), just use
% "%" (NOT "% ="). Example:
%
%       % = try omitting incorrect events
%       % excludedEvents = { 'NULL' }
%       excludedEvents = { 'NULL', 'INCORRECT' }
%
% The first excludedEvents assigment is commented out, but because the
% assignment includes "=", the comment is indicated using "%" not "% =".
% You can break this rule and get away with it sometimes, but other times 
% readtable will crash.
%
% HISTORY
%
% 02/2020 [MSJ] - workaround for comment-related crashing
% 01/2020 [MSJ] - added modelModules and contrastModules
% 09/2019 [MSJ] - new

errflag = 0;
errstring = 'no error';

if (~exist(model_fname,'file'))
	errstring = sprintf('Model definition file %s not found. Exiting...\n', model_fname);
    errflag = 1;
    return;
end


% init sensible default model struct fields

model.description = 'No description';
model.columnOrder = [ 2,3,4 ];
model.addUnaryContrasts = true;
model.forceZeroDuration = true;
model.timebase = 1000;


% read and parse model definition file

% T = readtable(model_fname,'Delimiter','=');
T = readtable(model_fname,'Delimiter','=','ReadVariableNames',false);

T_fields = deblank(T.Var1);
T_field_values = deblank(T.Var2);

% readable wraps field values in single quotes
% need an eval to get at values

for index = 1:numel(T_fields)
    
    switch T_fields{index}

        case 'description'
    
            model.description = eval(T_field_values{index});
             
        case 'metadata_directory'
            
            model.metadata_directory = eval(T_field_values{index});
            
        case 'forceZeroDuration'
            
            model.forceZeroDuration = strcmp(eval(T_field_values{index}),'true');
             
        case 'timebase'
            
            model.timebase = eval(T_field_values{index});
            
        case 'columnOrder'
            
            model.columnOrder = cell2mat(eval(T_field_values{index}));
          
        case 'excludedEvents'
            
            model.excludedEvents = upper(eval(T_field_values{index}));
            
        case 'contrastModules'
            
            model.contrastModules = eval(T_field_values{index});
            
        case 'modelModules'
            
            model.modelModules = eval(T_field_values{index});
           
        case 'addUnaryContrasts'
            
            model.addUnaryContrasts = strcmp(eval(T_field_values{index}),'true');
           
        case 'contrasts.defs'
            
            model.contrasts.defs = eval(T_field_values{index});
            
        case 'contrasts.sessions'
            
            model.contrasts.sessions = eval(T_field_values{index});
            
        case 'contrasts.names'
            
            model.contrasts.names = eval(T_field_values{index});
           
        case 'parametric_modulator.names'
            
            model.parametric_modulator.names = upper(eval(T_field_values{index}));
           
        case 'parametric_modulator.metadata_columns'  
           
            model.parametric_modulator.metadata_columns = cell2mat(eval(T_field_values{index}));
            
        case 'parametric_modulator.targets'  
           
            model.parametric_modulator.targets = (eval(T_field_values{index}));

        otherwise
            % any comments will land here (do nothing, but first verify it's a commment)
            temp = T_fields{index};
            if (~strcmp(temp(1),'%'))
                errstring = sprintf('Unrecognized model field <%s> encountered. Exiting...\n', T_fields{index});
                errflag = 1;
                return;
            end
            
    end
    
end

% ------------------------------------------------------------------------------------------------------------
% sanity checks
% ------------------------------------------------------------------------------------------------------------

if (~isfield(model,'metadata_directory'))
	errstring = sprintf('Invalid model: metadata directory not defined.\n');
    errflag = 1;
    return;
end

if (~exist(model.metadata_directory,'dir'))
	errstring = sprintf('Metadata directory %s not found.\n', model.metadata_directory);
    errflag = 1;
    return;
end

if (isfield(model,'contrasts'))
    if (~isfield(model.contrasts,'defs'))
        errstring = sprintf('Invalid model: missing contrast definitions.\n');
        errflag = 1;
        return;
    end
    if (~isfield(model.contrasts,'sessions'))
        errstring = sprintf('Invalid model: missing contrast session definitions.\n');
        errflag = 1;
        return;
    end
end

if (isfield(model,'parametric_modulator'))
    if (~isfield(model.parametric_modulator,'names'))
        errstring = sprintf('Invalid model: missing parametric modulator names.\n');
        errflag = 1;
        return;
    end
    if (~isfield(model.parametric_modulator,'metadata_columns'))
        errstring = sprintf('Invalid model: missing : missing parametric modulator metadata columns.\n');
        errflag = 1;
        return;
    end
end





