% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------

cd('~');
more off;
clear all
aa_ver5;

% NEW SCRUB MASTER TASKLIST

aap = aarecipe('aap_parameters_WUSTL.xml','new_scrub_noT2.xml');

% ------------------------------------------------------------------------------------------------------------------------------
% FSL hack
% ------------------------------------------------------------------------------------------------------------------------------

FSL_binaryDirectory = '/usr/local/fsl/bin'; 
currentPath = getenv('PATH');
if ~contains(currentPath,FSL_binaryDirectory)
    correctedPath = [ currentPath ':' FSL_binaryDirectory ];
    setenv('PATH', correctedPath);
end

% ------------------------------------------------------------------------------------------------------------------------------
% DIRECTORY AND DEFAULTS
% ------------------------------------------------------------------------------------------------------------------------------

aap.acq_details.root = '/Volumes/DATA01/SCRUB_SUBSET';
aap.directory_conventions.analysisid = 'RESULTS_ds002382'; % NAMWORDS YA_OA
aap.directory_conventions.rawdatadir = '/Volumes/DATA01/NAMWORDS/BIDSCONVERTED';

% PCT if available

% aap.options.wheretoprocess='matlab_pct';
% aap.directory_conventions.poolprofile = 'local';
% aap.options.aaparallel.numberofworkers = 15;

% ------------------------------------------------------------------------------------------------------------------------------
% STREAM CUSTOMIZATION
% ------------------------------------------------------------------------------------------------------------------------------

% need to point 1st level epi input for rWLS to pre-smoothing (see comments in tasklist)

aap = aas_renamestream(aap,'aamod_firstlevel_model_00004','epi','aamod_norm_write_epi_00001.epi');

% remember: SPARSE SAMPLING FOR NAMWORDS

 if isfield(aap.tasksettings,'aamod_firstlevel_model')
    for index = 1:numel(aap.tasksettings.aamod_firstlevel_model)
            aap.tasksettings.aamod_firstlevel_model(index).xBF.T0 = 1;
    end
 end

% ------------------------------------------------------------------------------------------------------------------------------
% BIDS input
% ------------------------------------------------------------------------------------------------------------------------------

% NEW BIDS SETTINGS

aap.acq_details.convertBIDSEventsToUppercase = true;
aap.acq_details.omitNullBIDSEvents = true;

aap = aas_processBIDS(aap);

% NEW CONTRAST OPTION: UNIQUEBYSESSION

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'uniquebysession', '+1xLISTENWORD', 'LW', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'uniquebysession', '+1xLISTENNOISE', 'LN', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'uniquebysession', '+1xLISTENWORD|-1xLISTENNOISE', 'LW_G_LN', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'uniquebysession', '+1xREPEATCORRECT|-1xREPEATNOISE|-1xLISTENWORD|+1xLISTENNOISE', 'rwGrn_G_lwGln', 'T');
						   
% ------------------------------------------------------------------------------------------------------------------------------
% RUN
% ------------------------------------------------------------------------------------------------------------------------------

aa_doprocessing(aap);
aa_close(aap);

