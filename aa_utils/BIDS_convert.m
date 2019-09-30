

% script/tasklist that will convert our CNDA
% dicom & aa-based modeling to BIDS using aa_export_toBIDS
%
% the data can then be imported for analysis using aas_processBIDS
%
% Freesurfer must be installed (its used for defacing the structurals)
%
% this version updated to use new modeling tools


% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------

clear all;
cd('~');        % workaround for an aa restart bug
aa_ver5;

aap = aarecipe('aap_parameters_WUSTL.xml', 'BIDS_convert.xml');

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
% directory specs -- customize for your analysis
% ------------------------------------------------------------------------------------------------------------------------------

aap.acq_details.root = '/Users/peellelab/DATA/NAMWORDS';
aap.directory_conventions.analysisid = 'RESULTS_BIDSCONVERSION';

aap.directory_conventions.rawdatadir = '/Users/peellelab/DATA/NAMWORDS/SUBJECTS';

% this is where aa will look for required BIDS files -- see notes on BIDS conversion below
% note this is relative (i.e. under) aap.acq_details.root

aap.directory_conventions.BIDSfiles = 'BIDSFILES';

% ------------------------------------------------------------------------------------------------------------------------------
% autoidentify -- T1 is required, T2 is optional
% ------------------------------------------------------------------------------------------------------------------------------

% NAMWords protocol for t1 (dicom.ProtocolName) is T1w_MPR
% NAMWords protocol for t2 (dicom.ProtocolName) is T2w_SPC

aap.options.autoidentifystructural = 1;
aap.directory_conventions.protocol_structural = 'T1w_MPR';
aap.options.autoidentifystructural_choosefirst = 1;
aap.options.autoidentifystructural_chooselast = 0;

% change autoidentifyt2 to 0 if no T2 (and comment T2 block in tasklist)

aap.options.autoidentifyt2 = 1;
aap.directory_conventions.protocol_t2 = 'T2w_SPC';
aap.options.autoidentifyt2_choosefirst = 1;
aap.options.autoidentifyt2_chooselast = 0;

% ------------------------------------------------------------------------------------------------------------------------------
% PCT
% ------------------------------------------------------------------------------------------------------------------------------

% aap.options.wheretoprocess='matlab_pct';
% aap.directory_conventions.poolprofile = 'local';
% aap.options.aaparallel.numberofworkers = 11;

% ------------------------------------------------------------------------------------------------------------------------------
% HRF TIMING
% -- the default SPM value (halfway through volume) is often not good for our data
% ------------------------------------------------------------------------------------------------------------------------------

if isfield(aap.tasksettings,'aamod_firstlevel_model')
	aap.tasksettings.aamod_firstlevel_model.xBF.T0 = 1; 
end

% ------------------------------------------------------------------------------------------------------------------------------
% add subjects and sessions
% ------------------------------------------------------------------------------------------------------------------------------

datastamp_fname = '/Users/peellelab/DATA/NAMWORDS/auxdata/NAM_datastamp.txt'; 
CB_fname = '/Users/peellelab/DATA/NAMWORDS/auxdata/NAM_counterbalance.txt'; 
SID_alias_fname = '/Users/peellelab/DATA/NAMWORDS/auxdata/NAM_BIDSalias.txt'; 
session_labels_fname = '/Users/peellelab/DATA/NAMWORDS/auxdata/NAM_session_labels.txt';

[ aap, SUBJECTS, SESSIONS ] = add_subjects_and_sessions(aap, datastamp_fname, CB_fname, SID_alias_fname, session_labels_fname);


% ------------------------------------------------------------------------------------------------------------------------------
% modeling 
% ------------------------------------------------------------------------------------------------------------------------------

% DON'T DEFINE CONTRASTS IN MODEL_FNAME

model_fname = '/Users/peellelab/DATA/NAMWORDS/auxdata/NAM_model.txt'; 
aap = make_model(aap, SUBJECTS, SESSIONS, model_fname);

% ------------------------------------------------------------------------------------------------------------------------------
% run -- this will terminate before completion due to aamod_halt (see comments in tasklist)
% ------------------------------------------------------------------------------------------------------------------------------

aa_doprocessing(aap);
aa_close(aap);

% ------------------------------------------------------------------------------------------------------------------------------
% BIDS conversion - run the following code in the command window after aa_doprocessing terminates
% ------------------------------------------------------------------------------------------------------------------------------

% % % savedir = pwd;
% % % cd(fullfile(aap.acq_details.root,aap.directory_conventions.analysisid));
% % % clear aap; load('aap_parameters');
% % % % aa_export_toBIDS('/Users/peellelab/DATA/NAMWORDS/BIDSCONVERTED');
% % % aa_export_toBIDS('/Users/peellelab/DATA/NAMWORDS/BIDSCONVERTED',...
% % %                     'anatt1','aamod_freesurfer_deface_00001|defaced_structural',...
% % %                         'anatt2','aamod_freesurfer_deface_apply_t2_00001|defaced_t2')
% % % cd(savedir);

% ------------------------------------------------------------------------------------------------------------------------------
%
% Some helpful notes in re aa_export_toBIDS usage:
%
%   syntax: aa_export_toBIDS('path/to/toplevel/directory/to/create')
%
% c) BIDS requires three files to appear in the top level directory:
%
%		README - a plaintext (ASCII or UTF-8) description of the data
%		CHANGES- a plaintext (ASCII or UTF-8) list of version changes
%		dataset_description.json - a JSON description of the data (see the
%			current specification for required and optional fields)
%
%	You must provide these files to be BIDS-compliant. This function will
%	attempt to copy them from aap.directory_conventions.BIDSfiles, if the
%	field is defined and the directory exists (otherwise you'll have to add 
%	them by hand). Note there are a number of optional files that can be also
%	be included at the top level -- for convenience, all files that live in 
%	aap.directory_convention.BIDSfiles will be copied for you. *
%
%   * if you set aap.directory_conventions.BIDSfiles, the directory must
%     ONLY contain BIDS files (because aa_export_toBIDS blindly copies the
%     entire directory contents to the destination folder). So it can't be
%     the analysis results directory (which would have been the logical
%     choice).
%
% There is weirdness in the aa BIDS converter in that it needs to load the
% aap struct from aap_parameters.mat (this includes additional fields created
% during aa_doprocessing). Ergo the cd and clear-and-load in the code above.
%
% ------------------------------------------------------------------------------------------------------------------------------


