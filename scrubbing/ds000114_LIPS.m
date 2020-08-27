
disp('motion scrub test/retest on openfmri dataset ds000114 / LIPS');

% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------

more off;
clear all
aa_ver5;

% this omits default scrub of frames 1:4 (use numdummies instead)
aap = aarecipe('aap_parameters_WUSTL.xml','new_scrub_no14.xml');

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
aap.directory_conventions.analysisid = 'RESULTS_ds000114_LIPS';

% just point rawdatadir at the top level BIDS dir, processBIDS does the
% rest (also be sure xml does -- *_fromnifti, not dicom import...)

aap.directory_conventions.rawdatadir = '/Volumes/DATA01/SCRUB_SUBSET/ds000114';

% there are multiple structuals in ds000114 -- need to specify chooseblerg

aap.options.NIFTI4D = 1;
aap.options.autoidentifystructural_choosefirst = 1;
aap.options.autoidentifystructural_chooselast = 0;

% correct T1 effect using numdummies

aap.acq_details.numdummies = 4;
aap.acq_details.input.correctEVfordummies = 1;

% PCT customization

aap.options.wheretoprocess='matlab_pct';
aap.directory_conventions.poolprofile = 'local';
aap.options.aaparallel.numberofworkers = 15;

% ------------------------------------------------------------------------------------------------------------------------------
% STREAM CUSTOMIZATION
% ------------------------------------------------------------------------------------------------------------------------------

% need to redirect 1st level epi input for rWLS to pre-smoothing (see comments in tasklist)

aap = aas_renamestream(aap,'aamod_firstlevel_model_00004','epi','aamod_norm_write_epi_00001.epi');

% ------------------------------------------------------------------------------------------------------------------------------
% BIDS input and model
% ------------------------------------------------------------------------------------------------------------------------------

aap.acq_details.input.combinemultiple = true;   

aap = aas_processBIDS(aap, [], {'finger_foot_lips'}); % <= DO IT THIS WAY

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [-0.5 -0.5 1], 'lips', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_test', [-0.5 -0.5 1], 'lips-test', 'T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:finger_foot_lips_retest', [-0.5 -0.5 1], 'lips-retest', 'T');
					   
% ------------------------------------------------------------------------------------------------------------------------------
% RUN
% ------------------------------------------------------------------------------------------------------------------------------

aa_doprocessing(aap);
aa_close(aap);

% ------------------------------------------------------------------------------------------------------------------------------
% POSTPROCESSING
% ------------------------------------------------------------------------------------------------------------------------------

% notes
%
% n = 10
%
% Data irregularities:
%
% sub-01 had weird cb stripe in some firstlevel maps. It does not seem to
% affect the secondlevel results
%
% note lips was selected for analysis even though finger and foot had
% stronger activation because data was a mix of left and right activation
% (lip activation is bilateral)
%
% title and link to publication:
%
% Gorgolewski KJ, Storkey AJ, Bastin ME, Whittle I, Pernet C: 
% Single subject fMRI test-retest reliability metrics and confounding factors. 
% NeuroImage 69 (2013) 231?243e
%
% https://pubmed.ncbi.nlm.nih.gov/23153967/
%
% ROI = bilateral 5 mm spheres, MNI coords from:
%
% 	Motor cortex maps articulatory features of speech sounds 
%   Pulvermuller et al. PNAS 103(20):7865-7870 (2006) 
%

% ----------------------------------------------------------------------------------
% MAXIMUM T (second level) - generates separate plots for UNC and FWE
% ----------------------------------------------------------------------------------

if (0)
    
clear TMAX_options;

TMAX_options.analysis_description = 'ds000114 LIPS max_t';
TMAX_options.results_dir = '/Volumes/DATA01/scrub_subset/RESULTS_ds000114_LIPS';
TMAX_options.contrast = 'lips';
TMAX_options.tmap = 'spmT_0002';
TMAX_options.ROI_fname = '/Users/peellelab/SCRUB_PROJECT_FILES/DS000114/LIPS/mask_lips_pulvermuller.nii';
TMAX_options.ROI_description = 'lips';
TMAX_options.plot_title = 'contrast = lips'; 
TMAX_options.plot_fname = 'ds000114_lips_TMAX.jpg';

TMAX_results_LIPS = PP_nifti_max(TMAX_options);

% ----------------------------------------------------------------------------------
% TEST-RETEST (first level) - unthresholded and UNC thresholded
% note now using beta maps not tmaps for unthresholded comparison
% ----------------------------------------------------------------------------------

clear TRT_options;

TRT_options.analysis_description = 'ds000114 LIPS TRT';
TRT_options.results_dir = '/Volumes/DATA01/SCRUB_SUBSET/RESULTS_ds000114_LIPS';
TRT_options.unthreshed_test = 'con_0002.nii';
TRT_options.threshed_test = 'thrT_0002.nii';
TRT_options.unthreshed_retest = 'con_0003.nii';
TRT_options.threshed_retest = 'thrT_0003.nii';
TRT_options.plot_label = 'LIPS';
TRT_options.fig_fname = 'ds000114_lips_TRT.jpg';

TRT_results_LIPS = PP_test_retest(TRT_options);

TRT_options.fig_fname = 'ds000114_lips_MI_TRT.jpg';
TRT_options.ROI_fname = '/Users/peellelab/SCRUB_PROJECT_FILES/DS000114/LIPS/mask_lips_pulvermuller.nii';
TRT_wROI_results_LIPS = PP_test_retest(TRT_options);


end
