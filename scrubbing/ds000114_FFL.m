
disp('motion scrub test/retest on openfmri dataset ds000114 (gorgo multitask -FFL)');
disp('working out final tasklist including wavelet despike, 24rp, rWLS');

% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------

% cd('~');
more off;
clear all
aa_ver5;

aap = aarecipe('aap_parameters_WUSTL.xml','new_scrub.xml');

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

aap.acq_details.root = '/Users/peellelab/DATA/SCRUB';
% aap.directory_conventions.analysisid = 'RESULTS_ds000114_FFL'; % finger-foot-lips
aap.directory_conventions.analysisid = 'RESULTS_ds000114_FFL_TRT'; % finger-foot-lips

% just point rawdatadir at the top level BIDS dir, processBIDS does the rest

aap.directory_conventions.rawdatadir = '/Users/peellelab/DATA/ds000114';

% there are multiple structuals in ds000114 -- need to specify chooseblerg

aap.options.NIFTI4D = 1;
aap.options.autoidentifystructural_choosefirst = 1;
aap.options.autoidentifystructural_chooselast = 0;

% we "throw out" first 4 volumes using scrubbing, ergo set numdummies = 0

aap.acq_details.numdummies = 0;
aap.acq_details.input.correctEVfordummies = 0;

% PCT if availble

% aap.options.wheretoprocess='matlab_pct';
% aap.directory_conventions.poolprofile = 'local';
% aap.options.aaparallel.numberofworkers = 15;

% ------------------------------------------------------------------------------------------------------------------------------
% STREAM CUSTOMIZATION
% ------------------------------------------------------------------------------------------------------------------------------

% need to point 1st level epi input for rWLS to pre-smoothing (see comments in tasklist)

aap = aas_renamestream(aap,'aamod_firstlevel_model_00004','epi','aamod_norm_write_epi_00001.epi');


% ------------------------------------------------------------------------------------------------------------------------------
% BIDS input
% ------------------------------------------------------------------------------------------------------------------------------

% ds000114 has separate test and retest sessions
% we will combine these into ONE model then implement test/retest using contrasts
% (if your dataset is organized as one session, DON'T do this!)
%
% the key is setting the "combinemultiple" option to true (the default is false):

aap.acq_details.input.combinemultiple = true;   

% note, set this *BEFORE* aas_processBIDS
%
% if combinemultiple = true, aa creates two sessions for each subject:
%
%	finger_foot_lips_retest
%	finger_foot_lips_test
%
% you can verify this in the model -- the design matrix will have 2 sessions
%
% for comparision, if combinemultiple = false, aa creates a test
% and a retest DIRECTORY at the SUBJECT level, each with one session
% called finger_foot_lips. That's not what we want.

% ----- Selecting the tasks in processBIDS and addcontrast ---------
%
% DON'T include the _test or _retest suffix when specifying the
% task in processBIDS (ds000114 has multiple tasks; here we analyze
% finger_foot_lips):

% aap = aas_processBIDS(aap, [], {'finger_foot_lips_test','finger_foot_lips_retest'}); % <= WRONG
aap = aas_processBIDS(aap, [], {'finger_foot_lips'}); % <= DO IT THIS WAY

% aside: here's how to test one subject, which is handy
% aap = aas_processBIDS(aap, [], {'finger_foot_lips'}, { 'sub-01' });   

% however, DO use the _test and _retest suffix when specifying *contrasts*

% here are contrasts for max-t extraction (we want to use all the data in the max-T):
% (we simplfy this by using sameforallsessions so the session names are irrelevant)

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [1 -0.5 -0.5], 'finger', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [-0.5 1 -0.5], 'foot', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [-0.5 -0.5 1], 'lips', 'T');

% here are the contrasts for test-retest:

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_test', [1 -0.5 -0.5], 'finger-test', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_retest', [1 -0.5 -0.5], 'finger-retest', 'T');

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_test', [-0.5 1 -0.5], 'foot-test', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_retest', [-0.5 1 -0.5], 'foot-retest', 'T');

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_test', [-0.5 -0.5 1], 'lips-test', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_retest', [-0.5 -0.5 1], 'lips-retest', 'T');

							   
% ------------------------------------------------------------------------------------------------------------------------------
% RUN
% ------------------------------------------------------------------------------------------------------------------------------

aa_doprocessing(aap);
aa_close(aap);



