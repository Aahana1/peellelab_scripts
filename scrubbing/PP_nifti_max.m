function nifti_results = PP_nifti_max(options)
%
% nift_max postprocessor
%
% generate nifti_max barplots (wholebrain and one ROI) using secondlevel maps
%
% in brief, the function will crawl the results directory and extract whole-brain 
% and optionally ROI max-t for each aamod_secondlevel_threshold_* in the root 
% directory (each of which corresponds to a scrubbing strategy. The maps
% are are located in:
%
%   /<options.root>/aamod_secondlevel_threshold_XXXX/group_stats/<options.contrast>/<options.tmap>
%
% The values are returned in vector nifti_max and a sanity-check bargraph
% is generated and saved to jpg.
%
% INPUT
%
% options - struct with the following fields:
%
% .root      - top level aa analysis folder
% .contrast  - contrast to example (one of the folders under "group_stats")
% .tmap      - tmap to use:
%
%       spmT_0002.nii is MEAN ACTIVATION
%       spmT_0003.nii is MEAN DEACTIVATION
%       spmF_0001.nii is MEAN (activation | deactivation) -- note F
%
% .SEED.center/.SEED.radius - ROI defined as center+radius
% .ROI_fname - ROI defined as a .nii mask
% .ROI_description - used to label plot (also returned in nifti_max)
% .plot_title  - title to add to QA plot (leave empty to skip plotting)
% .analysis_description - string identifier for results
%
% you may define the ROI using SEED or an ROI file but not both. If
% both are defined, results for the SEED are returned
%
% OUTPUT
%
% nifti_max - struct of tmax results having the following fields:
%
% .wholebrain.UNC - vector of whole-brain tmax for each scrub strategy
% .wholebrain.FWE - vector of whole-brain tmax for each scrub strategy
% .ROI.UNC - vector of tmax for each scrub strategy restricted to ROI
% .ROI.FWE - vector of tmax for each scrub strategy restricted to ROI
% .scrub_descriptors - cell array of scrub strategy descriptors
% .ROI_description - = options.ROI_description
% .results_description - = option.analysis_description
%
% Additionally, a plot of the results is saved to <options.description>.jpg
%
% EXAMPLE USE:
%
%     options.root = '/Users/peellelab/data/scrub/RESULTS_ds000114_FFL';
%     options.contrast = 'foot';
%     options.tmap = 'spmT_0002';
%     options.SEED.center = [12 -78 -10];
%     options.SEED.radius = 5;
%     options.ROI_fname = '/Users/peellelab/MATLAB_SCRIPTS/V5.nii';
%     options.ROI_description = 'V5';
%     options.plot_title = 'FFL foot'; 


% 1) top level results folder

% results_dir = '/Users/peellelab/data/scrub/RESULTS_ds000114_FFL';
results_dir = options.root;


% these match the scrubbing branches in the tasklist:
% actual results are x2 (odd entries are UNC, evens are FWE)

scrub_descriptors = {'RP6', 'RP24', 'wavelet','rWLS', 'FD1','FD2','FD5','FD10', 'FD20', 'FD40', 'DV1', 'DV2', 'DV5', 'DV10', 'DV20', 'DV40' };
    
% 2) contrast to examine - these will be the tags used in aas_addcontrast
%
% gorgo - motor example
%
% contrast_to_examine = 'finger';
% contrast_to_examine = 'foot';
% contrast_to_examine = 'lips';     % best for somatomotorlateral ROI

contrast_to_examine = options.contrast;

%
% 3) tmap - presumably activation is most meaningful, but you can pick whichever you
% want. There are also thresholded versions of these files (thr*.nii)

% tmap_to_examine = 'spmT_0002'; 
tmap_to_examine= options.tmap;

% 4a) ROI definition as ROI file

ROI_fname = [];

if (~isempty(options.ROI_fname))
    ROI_fname = options.ROI_fname;
end

% 4b) ROI definintion as SEED

SEED = [];

% SEED.name = 'SomatomotorLateral';
% SEED.center = [ 65.64 -7.88 24.83 ];
% SEED.radius = 5;

if (~isempty(options.SEED))
    SEED.center = options.SEED.center;
    SEED.radius = options.SEED.radius;
end


% 5) ROI_description (used to label the plot)

% ROI_description = 'SomatomotorLateral ROI [ 65.64 -7.88 24.83 ]';
ROI_description = options.ROI_description;

% 6) save filename for the jpg (or leave fig_fname empty to skip plotting)

% title_string = 'FFL foot';
title_string = options.plot_title;

fig_fname = [];

if (~isempty(options.plot_title))
    fig_fname = 'nift_max.jpg';
end


% ------------------------------- END OF INPUT ---------------------------------------

% sanity check

if ~exist(results_dir,'dir')
    error('specified results directory does not exist');
end

% get list of files to process

command = sprintf('find %s -path *aamod_secondlevel_threshold*/group_stats/%s* -name %s.nii', results_dir, contrast_to_examine, tmap_to_examine);

[ status,nifti_list ] = system(command);

if (status || ~numel(nifti_list))
	error('nifti_list generation failed');
end

nifti_list = split(deblank(nifti_list));

% sanity check

if (numel(nifti_list)>1000)
	disp('More than 1000 files found...');
    pause;
end

number_of_scrub_levels = numel(scrub_descriptors);

% each has two rows: row-1 = FWE, row-2 = UNC 

wholebrain_max = zeros(2,number_of_scrub_levels);
SEED_max = zeros(2,number_of_scrub_levels);
ROI_max = zeros(2,number_of_scrub_levels);


scrub_index = 0;

for index = 1:2:numel(nifti_list)
    
	scrub_index = scrub_index + 1;

    % FWE
    
    fname = nifti_list{index};
    disp(['processing: ' fname]);
    [ this_wholebrain_max, this_SEED_max, this_TPM_max ] = nifti_max(fname, SEED, ROI_fname);
    wholebrain_max(1,scrub_index) = this_wholebrain_max;
    if ~isempty(this_SEED_max)
        SEED_max(1,scrub_index) = this_SEED_max; 
    end
    if ~isempty(this_TPM_max)
        ROI_max(1,scrub_index) = this_TPM_max; 
    end
    
    % UNC
    
    fname = nifti_list{index+1};
    disp(['processing: ' fname]);
    [ this_wholebrain_max, this_SEED_max, this_TPM_max ] = nifti_max(fname, SEED, ROI_fname);
    wholebrain_max(2,scrub_index) = this_wholebrain_max;
    if ~isempty(this_SEED_max)
        SEED_max(2,scrub_index) = this_SEED_max; 
    end
    if ~isempty(this_TPM_max)
        ROI_max(2,scrub_index) = this_TPM_max; 
    end   
    
end


% plot bargraphs

wholebrain_means = wholebrain_max;

% assume there is only one seed

if isempty(SEED)
    ROI_means = ROI_max;
else
    ROI_means = SEED_max;
end

barmeans = [ wholebrain_means(1,:) ; ROI_means(1,:) ; wholebrain_means(2,:) ; ROI_means(2,:) ];

h = figure('Position',[0 0 700 1000], 'Visible', 'off', 'MenuBar', 'none');
movegui(h, 'center');
set(h, 'Visible', 'on');
clf

b = bar(barmeans,1.0,'EdgeColor','black','LineWidth',0.9,'FaceColor','flat');
set(gca,'XTickLabel',{'Whole Brain', ROI_description },'FontSize',16);

l = legend(scrub_descriptors);
title(l,'Scrub Level');
a = axis;
axis([0.8*a(1),1.1*a(2),0,1.1*a(4)]);

% title(['Group Max T (' strrep(contrast_to_examine,'_','-') ') ' title_string ]);
title(title_string);

% save as jpeg

if (~isempty(fig_fname))
    print(h,'-djpeg', '-r150', fig_fname);
%     print(h,'-depsc',fig_fname);
end

%  fill in nifi_max return struct


nifti_results.wholebrain.FWE = wholebrain_means(1,:);
nifti_results.wholebrain.UNC = wholebrain_means(2,:);
nifti_results.ROI.FWE = ROI_means(1,:); 
nifti_results.ROI.UNC = ROI_means(2,:);

nifti_results.ROI_description = ROI_description;
nifti_results.scrub_descriptors = scrub_descriptors;
nifti_results.results_description = options.analysis_description;


end



% ====================================================================================
% ====================================================================================
% ====================================================================================
% ====================================================================================
% ====================================================================================
% ====================================================================================


function [ wholebrain_max, SEED_max, ROI_max ] = nifti_max(nii_fname, SEED, ROI_fname)
%
%
% return wholebrain and, optionally, ROI maximum values for nii_fname.nii
%
% input:
%
% nii_fname - (fullpath) nii filename
%
% optional:
%
% SEED - struct defining an ROI as a center and a radius
% 
%    <SEED>
%       <name></name>
%       <center></center>
%       <radius></radius>
%    </SEED>
%
% ROI_fname - ROI fname of ROI to examine
%
% output:
%
% wholebrain_max    - maximum voxel value in fname
% SEED_max          - max voxel across all seeds (weighted by seed.weight)
% ROI_max           - max voxel in ROI
%
% examples
%
% nii_fname = '/blah/blah/stats/spmT_0001.nii';
% 
% ROI_fname = '/Users/peellelab/V5.nii';
% 
% SEED.name = 'SomatomotorLateral';
% SEED.center = [ 65.64 -7.88 24.83 ];
% SEED.radius = 5;
% 
% SEED.name = 'CinguloOpercular';
% SEED.center = [ 51.26 8.26 -2.06];
% SEED.radius = 5;
%
%
% NOTES
%
% 1) use of SEED requires marsbar (unless seed.radius = 0)
%
%
% HISTORY
%
% 3/2020 [MSJ] - changed TPM from directory to file  and SEED to single center to simplify use
%

if nargin < 3
    ROI_fname = [];
end

if nargin < 2
    SEED = [];
end

SEED_max = [];
ROI_max = [];


% whole brain (always computed)

wholebrain_max = nifti_wholebrain_max(nii_fname);

% process ROI if defined

if (~isempty(ROI_fname))
    
    if (~exist(ROI_fname,'file')) 
        fprintf('%s: ROI file %s doesn''t exist. Skipping...', mfilename, ROI_fname);
    else
       ROI_max = nifti_max_from_TPM(nii_fname, ROI_fname);      
    end

end

% process SEED if defined

if (~isempty(SEED))
	SEED_max = nifti_max_from_seeds(nii_fname, SEED);
end

end



%---------------------------------------------------------------------------------
function vmax = nifti_wholebrain_max(fname)
%---------------------------------------------------------------------------------

handle = spm_vol(fname);
data = spm_read_vols(handle);
data(isnan(data)) = 0;

vmax = max(max(max(data)));

clear data;

end


%---------------------------------------------------------------------------------
function vmax = nifti_max_from_TPM(fname, ROI_fname)
%---------------------------------------------------------------------------------

vmax = [];

if (isempty(ROI_fname))
	return;
end

% reslice data to match ROI file

resliceOpts = [];
resliceOpts.mask = false;		% no masking
resliceOpts.mean = false;		% don't write a mean image
resliceOpts.interp = 1;			% default interp
resliceOpts.which = 1;			% don't reslice the first image
resliceOpts.wrap = [1 1 0];		% fMRI wrap around
resliceOpts.prefix = 'r';		% filename really doesn't matter - we delete it

spm_reslice({ROI_fname fname}, resliceOpts);

[p,n,e] = fileparts(fname);
tempfile = fullfile(p,['r' n e]);
handle = spm_vol(tempfile);
data = spm_read_vols(handle);
data(isnan(data)) = 0;

handle = spm_vol(ROI_fname);
roi = spm_read_vols(handle);
vmax = max(max(max((~~roi).*data)));

delete(tempfile);

end



%---------------------------------------------------------------------------------
function vmax = nifti_max_from_seeds(fname, SEED)
%---------------------------------------------------------------------------------

handle = spm_vol(fname);
imgMat = handle.mat;
imgDim = handle.dim;
  
vmax = [];

seed_center = SEED.center;
radius = SEED.radius;

if (radius> 0) 
    
    % marsbar ROI extraction
    %
    % maroi_sphere doesn't like radius = 0 (voxpts returns empty ROI) so
    % for 1-voxel seed (i.e., radius=0) just do mat\[seedmm 1]'
    % (note maroi_sphere sometimes fails if radius = 1)

    ROI = maroi_sphere(struct('centre', seed_center, 'radius', radius));
    roiIJK = voxpts(ROI, struct('mat', imgMat, 'dim', imgDim));
    if (isempty(roiIJK))
        fprintf('%s: Seed %s resulted in empty ROI', mfilename, SEED.name);
        voxels = 0;
    else
        
        roiIJK = [ roiIJK; ones(1, size(roiIJK,2)) ];
        voxels = spm_get_data(handle, roiIJK);
    end

else

	% maroi_sphere doesn't like radius = 0 (voxpts returns empty ROI) so
    % for 1-voxel seed (i.e., radius=0) just do mat\[seedmm 1]'
    % (note maroi_sphere sometimes even fails if radius = 1)

    roiIJK =  round(imgMat\[seed_center 1]');
    voxels = spm_get_data(handle, roiIJK);

end

vmax = max(max(max(voxels)));


end





	