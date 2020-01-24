% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------
 
cd('~')
clear;
aa_ver5;
 
parameters_xml = 'aap_parameters_WUSTL.xml'; % our default parameter file
tasklist_xml = 'SPM_PPI_tutorial.xml';	% see tasklist listing below
 
aap = aarecipe(parameters_xml,tasklist_xml);
 
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

aap.acq_details.root = '/Users/peellelab/DATA/SPM_PPI';
aap.directory_conventions.analysisid = 'RESULTS';
 
aap.options.autoidentifystructural = 0;  % we'll specify data explicitly using addsubject
aap.options.NIFTI4D = 1;  % want to convert ANALYZE file into a single 4D nii (would be reading in DICOM in most cases)
 
% tutorial specific settings (see also .xml header)
 
aap.acq_details.numdummies = 0;         % SPM12 manual p. 221 - we removed manually

% ------------------------------------------------------------------------------------------------------------------------------
% ADD SUBJECTS and STREAMS
% ------------------------------------------------------------------------------------------------------------------------------
 
subjectID = 'S01';
subjectID_dir = 'S01'; % not used here because we specify sFile and fList, but we must define
 
sFile = '/Users/peellelab/DATA/SPM_PPI/attention/structural/nsM00587_0002.img';
fList = cellstr(spm_select('FPList', '/Users/peellelab/DATA/SPM_PPI/attention/functional', '.*img$'));
 
aap = aas_addsubject(aap, subjectID, subjectID_dir, 'structural', {sFile}, 'functional', {fList});
aap = aas_addsession(aap,'SESS01');
 
% ------------------------------------------------------------------------------------------------------------------------------
% GLM
% ------------------------------------------------------------------------------------------------------------------------------


% % % % % % % if isfield(aap.tasksettings,'aamod_firstlevel_model')
% % % % % % %     
% % % % % % %     % use this syntax if one module appears in tasklist
% % % % % % %     
% % % % % % % % 	aap.tasksettings.aamod_firstlevel_model.xBF.T0 = 1; % this works for sure
% % % % % % % 
% % % % % % %     % use this syntax if multiple module in tasklist
% % % % % % % 
% % % % % % % 	aap.tasksettings.aamod_firstlevel_model(1).xBF.T0 = 1;
% % % % % % % 	aap.tasksettings.aamod_firstlevel_model(2).xBF.T0 = 1;
% % % % % % %  
% % % % % % % % % % % % these are wrong 
% % % % % % % % % % % 	aap.tasksettings.aamod_firstlevel_model_00001.xBF.T0 = 1;
% % % % % % % % % % % 	aap.tasksettings.aamod_firstlevel_model_00002.xBF.T0 = 1;
% % % % % % % 
% % % % % % % end

% UNITS can be 'seconds' or 'scans' (SPM PPI tutorial has it set for 'scans')
 
% % % % % % % % % aap.tasksettings.aamod_firstlevel_model_00001.xBF.UNITS = 'scans';  WRONG!!!!
aap.tasksettings.aamod_firstlevel_model(1).xBF.UNITS = 'scans'; 

% these are from a 'load factor'

stat = [ 80   170   260   350 ];
att = [  10    50   100   140   210   250   300   340 ];
natt = [  30    70   120   160   190   230   280   320 ];

 
aap = aas_addevent(aap,'aamod_firstlevel_model_00001', '*', '*', 'stat', stat, 10);
aap = aas_addevent(aap,'aamod_firstlevel_model_00001', '*', '*', 'natt', natt, 10);
aap = aas_addevent(aap,'aamod_firstlevel_model_00001', '*', '*', 'att', att, 10);

% need to add regressors (p. 330)

%   aap = aas_addcovariate(aap, modulename, subject, session, covarName, covariate, HRF, interest)
%
%   modulename    = name of module (e.g.,'aamod_firstlevel_model') for which this covariate applies
%   subject       = subject for whom this model applies
%   session       = session for which this applies
%   covarName     = name of the covariate
%   covarVector   = covariate vector, which should be as long as the session
%   HRF           = do we want to convolve this covariate with the HRF? (0 - no; 1 - yes)
%   interest      = is this covariate of interest, or a nuisance covariate?

% what does "interest" mean??

% block_regressors.mat is from SPM tutorial data (put in pwd)

load('block_regressors.mat'); % creates block1, block2, block3

% aap = aas_addcovariate(aap, modulename, subject, session, covarName, covarVector, HRF, interest);
aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00001', '*', '*', 'block1', block1, 0, 1);
aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00001', '*', '*', 'block2', block2, 0, 1);
aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00001', '*', '*', 'block3', block3, 0, 1);

% contrasts (p. 332)

% effectOfInterest is in tutorial -- I think aamod_vois_extract Ic option does this for us?

% aap = aas_addcontrast(aap,'aamod_firstlevel_contrasts','*','sameforallsessions', [eye(3) zeros(3,4)], 'effectOfInterest','F');
aap = aas_addcontrast(aap,'aamod_firstlevel_contrasts_00001','*','sameforallsessions', [0 -1 1 0 0 0], 'attention','T');
aap = aas_addcontrast(aap,'aamod_firstlevel_contrasts_00001','*','sameforallsessions', [-2 1 1 0 0 0], 'motion','T');

% WE MUST SET UP "CONTRASTS" PARAMETER IN aamod_ppi_prepare

% PPI MODEL

% % % % % % % % % % % % % % % % aap.tasksettings.aamod_firstlevel_model_00002.xBF.UNITS = 'scans'; 
aap.tasksettings.aamod_firstlevel_model(2).xBF.UNITS = 'scans'; 
% 
% aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00002', '*', '*', 'block1', block1, 0, 1);
% aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00002', '*', '*', 'block2', block2, 0, 1);
% aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00002', '*', '*', 'block3', block3, 0, 1);
aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00002', '*', '*', 'block1', block1, 0, 0);
aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00002', '*', '*', 'block2', block2, 0, 0);
aap = aas_addcovariate(aap, 'aamod_firstlevel_model_00002', '*', '*', 'block3', block3, 0, 0);

% % % % % aap = aas_addevent(aap,'aamod_firstlevel_model_00002', '*', '*', 'block1', 1, 90);
% % % % % aap = aas_addevent(aap,'aamod_firstlevel_model_00002', '*', '*', 'block2', 91, 90);
% % % % % aap = aas_addevent(aap,'aamod_firstlevel_model_00002', '*', '*', 'block3', 181, 90);
% % % % % 
% % % % % aap = aas_addcontrast(aap,'aamod_firstlevel_contrasts_00002','*','sameforallsessions', [0 0 0 1], 'PPI','T');

aap = aas_addcontrast(aap,'aamod_firstlevel_contrasts_00002','*','sameforallsessions', [1], 'PPI','T');

% need to rename the 2nd model input (otherwise the scheduler tries to use
% the output from aamod_firstlevel_model_00001 -- the residuals -- and if
% they weren't created (they aren't by default) then aa crashes

aap = aas_renamestream(aap,'aamod_firstlevel_model_00002','epi','aamod_epi_from_ANALYZE_00001.epi');

% ------------------------------------------------------------------------------------------------------------------------------
% RUN AND REPORT
% ------------------------------------------------------------------------------------------------------------------------------
 
aa_doprocessing(aap);
% aa_report(fullfile(aas_getstudypath(aap),aap.directory_conventions.analysisid));
aa_close(aap);





