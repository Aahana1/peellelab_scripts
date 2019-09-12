
% demonstration of tasklist that will convert our CNDA
% dicom & aa-based modeling to BIDS using aa_export_toBIDS
%
% the data can then be imported for analysis using aas_processBIDS
%
% Freesurfer must be installed (its used for defacing the structurals)

% ------------------------------------------------------------------------------------------------------------------------------
% INITIALIZATION
% ------------------------------------------------------------------------------------------------------------------------------

clear all;
cd('~');        % workaround for an aa restart bug
aa_ver5;

aap = aarecipe('aap_parameters_WUSTL.xml', 'BIDS_convert.xml');

% ------------------------------------------------------------------------------------------------------------------------------
% directory specs -- customize for your analysis
% ------------------------------------------------------------------------------------------------------------------------------

aap.directory_conventions.rawdatadir = '/Users/peellelab/DATA/NAMWORDS/SUBJECTS';
aap.acq_details.root = '/Users/peellelab/DATA/NAMWORDS';
aap.directory_conventions.analysisid = 'RESULTS_BIDSCONVERSION';

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
% add subjects and sessions -- demonstrating one subject, 2 sessions
% ------------------------------------------------------------------------------------------------------------------------------
% Nomenclature for scan sequences: 'functional','diffusion','fieldmaps','specialseries'
% Check aas_addsubject for more info
% 'diffusion' also needs one aas_addsession; In Peellelab data, 3 sessions were collected for diffusion scans, which get combined into 1 with the BIDs export

% If you'd like to replace the Peellelab number with something non-discrete to upload to OpenNeuro
% aap = aas_addsubject(aap, 'sub_01', 'PL00026_02', 'functional',[ 18 20 ]); 

aap = aas_addsubject(aap, 'PL00026', 'PL00026_02', 'functional', [ 18 20 ]);

aap = aas_addsession(aap, 'SESS01');
aap = aas_addsession(aap, 'SESS02');

% ------------------------------------------------------------------------------------------------------------------------------
% add your modeling here -- note BIDS will save events but not contrasts
% ------------------------------------------------------------------------------------------------------------------------------

aap = aas_addevent(aap,'aamod_firstlevel_model', '*', '*','demonstration', [1:10:100],0);

% ------------------------------------------------------------------------------------------------------------------------------
% run -- this will terminate before completion due to aamod_halt (see comments in tasklist)
% ------------------------------------------------------------------------------------------------------------------------------

aa_doprocessing(aap);

% ------------------------------------------------------------------------------------------------------------------------------
% BIDS conversion - run the following code in the command window after aa_doprocessing terminates
% ------------------------------------------------------------------------------------------------------------------------------

aa_close(aap);
savedir = pwd;
cd(fullfile(aap.acq_details.root,aap.directory_conventions.analysisid));
clear aap; load('aap_parameters');

% alternatively, this uploads the defaced t1 and t2
aa_export_toBIDS('/Users/peellelab/DATA/NAMWORDS/OPENNEUROREADY',...
                    'anatt1','aamod_freesurfer_deface_00001|defaced_structural',...
                        'anatt2','aamod_freesurfer_deface_apply_t2_00001|defaced_t2')

cd(savedir);

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


