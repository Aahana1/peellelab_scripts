

% script/tasklist that will convert our CNDA
% dicom & aa-based modeling to BIDS using aa_export_toBIDS
%
% the data can then be imported for analysis using aas_processBIDS
%
% Freesurfer must be installed (its used for defacing the structurals)

% some of the code is wrapped in an "if (0)" block because it should only
% be run once (and maybe you're re-running this script after a change or
% a crash) or shouldn't be run on some kinds of data (e.g., resting state). 
% See additional comments immediately preceeding the block

% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------

clear all;

% run this from inside BIDS_CONVERSION so we don't have to addpath
% (this script can remain as an example)

cd('/Users/peellelab/MATLAB_SCRIPTS/BIDS_CONVERSION')
aa_ver5;

aap = aarecipe('aap_parameters_WUSTL.xml', 'BIDS_convert.xml');   % old version parameter file (if running WASHU branch)
% aap = aarecipe('BIDS_convert.xml');                                 % uses new default aa param file (all other branches)

% ------------------------------------------------------------------------------------------------------------------------------
% directory specs -- customize for your analysis
% ------------------------------------------------------------------------------------------------------------------------------

aap.acq_details.root = '/Volumes/DATA02/NAMWORDS2';
aap.directory_conventions.analysisid = 'RESULTS_BIDSCONVERSION';
% aap.directory_conventions.analysisid = 'RESULTS_BIDS_onesubtest'; % one subject test (already has defacing etc complete)

aap.directory_conventions.rawdatadir = '/Volumes/DATA02/NAMWORDS2/SUBJECTS';

% this is where aa will look for required BIDS files -- see notes on BIDS conversion below
% note this is relative (i.e. under) aap.acq_details.root

% currently this is just placeholders that need to be filled in properly
% also, BIDS says we should add "sidecar" files for all the aux variables

aap.directory_conventions.BIDSfiles = 'BIDSFILES_fixme';

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
% % aap.options.wheretoprocess='parpool';
% aap.directory_conventions.poolprofile = 'local';
% aap.options.aaparallel.numberofworkers = 15;

% ------------------------------------------------------------------------------------------------------------------------------
% BIDS conversion - define metadata dir and paths to helper files
% ------------------------------------------------------------------------------------------------------------------------------

% using our new reprocessed metadata (CHAD conversion is missing recent
% subjects) -- note these files will be renamed by BIDSify_metadata_fnames

METADATAdir = '/Volumes/DATA02/NAMWORDS2/METADATA/NW2_reprocessed_metadata';
% METADATAdir = '/Volumes/DATA02/NAMWORDS2/METADATA/NW2_onesubtest';  % TESTING

datastamp_fname = '/Volumes/DATA02/NAMWORDS2/auxdata_BIDS_convert/NW2_datastamp_sorted.txt';
% datastamp_fname = '/Volumes/DATA02/NAMWORDS2/auxdata_BIDS_convert/NW2_datastamp_onesubtest.txt';    % TESTING
 
SID_alias_fname = '/Volumes/DATA02/NAMWORDS2/auxdata_BIDS_convert/NW2_alias.txt';
% SID_alias_fname = '/Volumes/DATA02/NAMWORDS2/auxdata_BIDS_convert/NW2_alias_onesubtest.txt';    % TESTING

session_labels_fname = '/Volumes/DATA02/NAMWORDS2/auxdata_BIDS_convert/NW2_session_labels.txt';

% ------------------------------------------------------------------------------------------------------------------------------
% 1) BIDS metadata tweaking
% ------------------------------------------------------------------------------------------------------------------------------

% run these utils only once (they will prompt before continuing)
% you also don't need to run this if converting resting state data

if (0)
    
    % 1) c_m_f is unnecessary for NW2 data (bc no CB and don't need to change session naming)
    % [ errflag,errstring ] = counterbalance_metadata_fnames(METADATAdir, new_session_names, CB_fname)

    % 2) however, we do need to rename the metadata to reflect the new subject ID (i.e., PL000XXX => sub-01, etc)
    [ errflag,errstring ] = BIDSify_metadata_fnames(METADATAdir, SID_alias_fname);

end

% ------------------------------------------------------------------------------------------------------------------------------
% 2) add subjects and sessions
% ------------------------------------------------------------------------------------------------------------------------------

[ aap, SUBJECTS, SESSIONS ] = add_subjects_and_sessions(aap, datastamp_fname, SID_alias_fname, session_labels_fname);

% ------------------------------------------------------------------------------------------------------------------------------
% 3) model (this is what goes into the tsv files)
% ------------------------------------------------------------------------------------------------------------------------------

% this model file defines the minimum model for BIDS conversion
% NB: DON'T define contrasts in the modelfile (a_f_c isn't in the tasklist!)

% you also don't need to run this if you converting resting state data 

if (1)

    model_fname = '/Volumes/DATA02/NAMWORDS2/auxdata_BIDS_convert/NW2_minmodel.txt';
    % model_fname = '/Volumes/DATA02/NAMWORDS2/auxdata_BIDS_convert/NW2_minmodel_onesubtest.txt';

    aap = make_minimum_model(aap, SUBJECTS, SESSIONS, model_fname);

end

% ------------------------------------------------------------------------------------------------------------------------------
% run -- this will terminate before completion due to aamod_halt (see comments in tasklist)
% ------------------------------------------------------------------------------------------------------------------------------

aa_doprocessing(aap);
aa_close(aap);

% ------------------------------------------------------------------------------------------------------------------------------
% BIDS conversion - run the following code in the command window after aa_doprocessing terminates
% ------------------------------------------------------------------------------------------------------------------------------

if (0)
    
    BIDSdir = '/Volumes/DATA02/NAMWORDS2/BIDSCONVERED';

    savedir = pwd;
    cd(fullfile(aap.acq_details.root,aap.directory_conventions.analysisid));
    clear aap; load('aap_parameters');

    aa_export_toBIDS(BIDSdir,...
                        'anatt1','aamod_freesurfer_deface_00001|defaced_structural',...
                            'anatt2','aamod_freesurfer_deface_apply_t2_00001|defaced_t2')
    cd(savedir);

end

%
% Some notes in re aa_export_toBIDS usage:
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



% ------------------------------------------------------------------------------------------------------------------------------
% lastly, update the tsv to include aux columns
% ------------------------------------------------------------------------------------------------------------------------------

% (note BIDS suggests including "sidecar" files to describe any aux variables)
% note this will add all events in the metadata (including excludedEvents in
% the model struct passed to make_min_model)

% you don't need to do this if converting resting state data

if (0)
    
    [errflag,errstring] =  BIDS_TSV_slam(BIDSdir,METADATAdir);

end

% note BIDS_TSV_slam saves (renames) the original tsv to *_b4slam.tsv
% you should delete these files after you confirm all is well



