
% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------

cd('~');
clear all
aa_ver5;

aap = aarecipe('aap_parameters_WUSTL.xml','SPM_tutorial_BIDS.xml');

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
% DEFAULTS AND SANITY CHECKS
% ------------------------------------------------------------------------------------------------------------------------------

aap.acq_details.root = '/Users/peellelab/DATA/MoAEpilot';
% aap.directory_conventions.analysisid = 'RESULTS_check';
aap.directory_conventions.analysisid = 'RESULTS';

% just point rawdatadir at the top level BIDS dir, processBIDS does the
% rest (also be sure xml does -- *_fromnifti, not dicom import...)

aap.directory_conventions.rawdatadir = '/Users/peellelab/DATA/MoAEpilot';

% need to specify chooseblerg otherwise aa crashes

aap.options.autoidentifystructural_choosefirst = 1;
aap.options.autoidentifystructural_chooselast = 0;

aap.options.NIFTI4D = 1;
aap.acq_details.numdummies = 0;	
aap.acq_details.input.correctEVfordummies = 0;

% ------------------------------------------------------------------------------------------------------------------------------
% BIDS input
% ------------------------------------------------------------------------------------------------------------------------------

aap = aas_processBIDS(aap);

% ------------------------------------------------------------------------------------------------------------------------------
% GLM
% ------------------------------------------------------------------------------------------------------------------------------

% UNITS can be 'secs' or 'scans' (SPM auditory tutorial has it set for 'scans')
 
% aap.tasksettings.aamod_firstlevel_model.xBF.UNITS = 'scans'; 
aap.tasksettings.aamod_firstlevel_model.xBF.UNITS = 'secs'; 
 
% processBIDS will create the events for the model, but you must define the contrasts

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts', '*', 'sameforallsessions', 1, 'omnibus','T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts', '*', 'sameforallsessions', 1, 'omnibus2','T');
						   
% ------------------------------------------------------------------------------------------------------------------------------
% RUN AND REPORT
% ------------------------------------------------------------------------------------------------------------------------------

aa_doprocessing(aap);
% aa_report(fullfile(aas_getstudypath(aap),aap.directory_conventions.analysisid));
aa_close(aap);



