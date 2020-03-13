
disp('motion scrub test/retest on openfmri dataset ds000114 (gorgo multitask -FFL)');
disp('working out final tasklist including wavelet despike, 24rp, rWLS');

% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------

cd('~');
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
aap.directory_conventions.analysisid = 'RESULTS_ds000114_FFL'; % finger-foot-lips

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
% we will combine into ONE model (then fake test/retest with contrasts)
% (if your dataset is organized as one session, DON'T do this!)
%
% aside: generates a warning: 
% 
%     WARNING: You have selected combining multiple BIDS sessions!
%     Make sure that you have also set aap.options.autoidentify*_* appropriately!
%     N.B.: <aa sessionname> = <BIDS taskname>_<BIDS sessionname>

aap.acq_details.input.combinemultiple = true;   % do BEFORE aas_processBIDS

% aap = aas_processBIDS(aap, [], {'finger_foot_lips'}, { 'sub-01' });   % how to test one task and one subject
aap = aas_processBIDS(aap, [], {'finger_foot_lips'});                   % all subjects (still must select task of interest)

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [1 -0.5 -0.5], 'finger', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [-0.5 1 -0.5], 'foot', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [-0.5 -0.5 1], 'lips', 'T');

% setup for TEST RETEST (i.e. aap.acq_details.input.combinemultiple = false)

% note aa names the sessions are finger_foot_lips_test and finger_foot_lips_retest)
%
% aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_test', [1 -0.5 -0.5], 'finger-test', 'T');
% aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_retest', [1 -0.5 -0.5], 'finger-retest', 'T');
% 
% aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_test', [-0.5 1 -0.5], 'foot-test', 'T');
% aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_retest', [-0.5 1 -0.5], 'foot-retest', 'T');
% 
% aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_test', [-0.5 -0.5 1], 'lips-test', 'T');
% aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_retest', [-0.5 -0.5 1], 'lips-retest', 'T');

							   
% ------------------------------------------------------------------------------------------------------------------------------
% RUN
% ------------------------------------------------------------------------------------------------------------------------------

aa_doprocessing(aap);
aa_close(aap);



