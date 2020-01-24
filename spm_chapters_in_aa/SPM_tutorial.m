% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------
 
clear;
aa_ver5;
 
parameters_xml = 'aap_parameters_WUSTL.xml'; % our default parameter file
tasklist_xml = 'SPM_tutorial.xml';	% see tasklist listing below
 
aap = aarecipe(parameters_xml,tasklist_xml);
% aap = aas_configforSPM12(aap); % only if older aa version
 
% ------------------------------------------------------------------------------------------------------------------------------
% this fixes a Matlab FSL path glitch
% ------------------------------------------------------------------------------------------------------------------------------
 
FSL_binaryDirectory = '/usr/local/fsl/bin'; 
currentPath = getenv('PATH');
if ~contains(string(currentPath),FSL_binaryDirectory)
    correctedPath = [ currentPath ':' FSL_binaryDirectory ];
    setenv('PATH', correctedPath);
end
 
% ------------------------------------------------------------------------------------------------------------------------------
% ANALYSIS SPECIFIC SETTINGS
% ------------------------------------------------------------------------------------------------------------------------------

aap.acq_details.root = '/Users/peellelab/DATA/MoAEpilot';
aap.directory_conventions.analysisid = 'RESULTS'; % creates this directory to save results
 
aap.options.autoidentifystructural = 0;  % we'll specify data explicitly using addsubject
aap.options.NIFTI4D = 1;  % want to convert ANALYZE file into a single 4D nii (would be reading in DICOM in most cases)
 
% tutorial specific settings (see also .xml header)
 
aap.acq_details.numdummies = 0;         % SPM12 manual p. 221 - we removed manually
aap.tasksettings.aamod_smooth.FWHM = 6; % SPM12 manual p. 227

% ------------------------------------------------------------------------------------------------------------------------------
% ADD SUBJECTS and STREAMS
% ------------------------------------------------------------------------------------------------------------------------------
 
subjectID = 'M00223';
subjectID_dir = 'M00223'; % not used here because we specify sFile and fList, but we must define
 
sFile = '/Users/peellelab/DATA/MoAEpilot/M00223/sM00223/sM00223_002.img';
fList = cellstr(spm_select('FPList', '/Users/peellelab/DATA/MoAEpilot/M00223/fM00223', '.*img$'));
 
aap = aas_addsubject(aap, subjectID, subjectID_dir, 'structural', {sFile}, 'functional', {fList});
aap = aas_addsession(aap,'session1');
 
% ------------------------------------------------------------------------------------------------------------------------------
% GLM
% ------------------------------------------------------------------------------------------------------------------------------

% UNITS can be 'seconds' or 'scans' (SPM auditory tutorial has it set for 'scans')
 
aap.tasksettings.aamod_firstlevel_model.xBF.UNITS = 'scans'; 
 
aap = aas_addevent(aap,'aamod_firstlevel_model','*','*','Sound', 6:12:84, 6); %refer to the tutorial 
aap = aas_addcontrast(aap,'aamod_firstlevel_contrasts','*','sameforallsessions', 1,'test-contrast','T');
 
% ------------------------------------------------------------------------------------------------------------------------------
% RUN AND REPORT
% ------------------------------------------------------------------------------------------------------------------------------
 
aa_doprocessing(aap);
aa_report(fullfile(aas_getstudypath(aap),aap.directory_conventions.analysisid));
aa_close(aap);
