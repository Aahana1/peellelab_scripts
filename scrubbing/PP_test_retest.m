function TRT = PP_test_retest(options)
%
% test-retest postprocessor
%
% return test-restest metrics for 16 branch denoising analysis
% save a jpeg plot for sanity checking
%
% this is set up to do test-retest implemented across sessions using contrasts
%
% it assumes these 16 denoising strategies exist in the results folder:
%
%   aamod_firstlevel_threshold_00001 will contain test and retest for 6RP (aka "baseline")
%   aamod_firstlevel_threshold_00002 will contain test and retest for 24RP
%   aamod_firstlevel_threshold_00003 will contain test and retest for wavelet despiking
%   aamod_firstlevel_threshold_00004 will contain test and retest for rWLS
%
%   aamod_firstlevel_threshold_00005 will contain test and retest for 1% FD scrub
%   aamod_firstlevel_threshold_00006 will contain test and retest for 2% FD scrub
%   aamod_firstlevel_threshold_00007 will contain test and retest for 5% FD scrub
%   aamod_firstlevel_threshold_00008 will contain test and retest for 10% FD scrub
%   aamod_firstlevel_threshold_00009 will contain test and retest for 20% FD scrub
%   aamod_firstlevel_threshold_00010 will contain test and retest for 40% FD scrub
%
%   aamod_firstlevel_threshold_00011 will contain test and retest for 1% DVARS scrub
%   aamod_firstlevel_threshold_00012 will contain test and retest for 2% DVARS scrub
%   aamod_firstlevel_threshold_00013 will contain test and retest for 5% DVARS scrub
%   aamod_firstlevel_threshold_00014 will contain test and retest for 10% DVARS scrub
%   aamod_firstlevel_threshold_00015 will contain test and retest for 20% DVARS scrub
%   aamod_firstlevel_threshold_00016 will contain test and retest for 40% DVARS scrub
%
% INPUT
%
%   options -- struct with the following 8 fields:
%
%   1) options.analysis_description
%   2) options.results_dir
%   3) options.unthreshed_test
%   4) options.threshed_test
%   5) options.unthreshed_retest
%   6) options.threshed_retest
%   7) options.plot_label
%   8) options.fig_fname
%   9) options.ROI_fname (optional)
%
%   1) options.analysis_description - one-line text description -- this is
%   returned in the output so that the data is  self-documenting (which is 
%   handy if/when you come back to the results weeks or months later).
%
%   2) options.results_dir - top level aa results_dir
%
%   3-6) the unthresholded and thresholded t-maps to use. The maps live in 
%
%       /<results_dir>/aamod_firstlevel_threshold_0000XX/sub-**/stats/
%
%   where XX is 01-16 based on denoising branch. The nii to use are named:
%
%       spmT_000Y.nii - UNthresholded   <= UPDATE: this can be con_000Y.nii to test beta maps instead of unthesholded t
%       thrT_000Y.nii - thresholded
%
%   where Y depends on the contrast you want to examine and depends on the order the contrasts were
%   defined in the usescript. For example, here are the contrasts for the flanker data (ds000102):
% 
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [1 0], 'congruent_correct', 'T');
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [0 1], 'incongruent_correct', 'T');
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'sameforallsessions', [-1 1], 'IC_G_CC', 'T');
% 
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:Flanker_run-1', [1 0], 'CC-test', 'T');
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:Flanker_run-2', [1 0], 'CC-retest', 'T');
% 
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:Flanker_run-1', [0 1], 'IC-test', 'T');
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:Flanker_run-2', [0 1], 'IC-retest', 'T');
% 
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:Flanker_run-1', [-1 1], 'IC-G-CC-test', 'T');
%     aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*', '*', 'singlesession:Flanker_run-2', [-1 1], 'IC-G-CC-retest', 'T');
%
% obviously contrasts 4/5, 6/7, and 8/9 are set up for test/retest
%
% So, if we wanted to examine test and retest on "CC" we would define:
%
%     options.unthreshed_test = 'spmT_0004.nii';
%     options.threshed_test = 'thrT_0004.nii';
% 
%     options.unthreshed_retest = 'spmT_0005.nii';
%     options.threshed_retest = 'thrT_0005.nii';
% 
% that is, we first compare:
%
%     /<results_dir>/aamod_firstlevel_threshold_00001/sub-**/stats/spmT_0004.nii
%  to
%     /<results_dir>/aamod_firstlevel_threshold_00001/sub-**/stats/spmT_0005.nii
%
% and
%
%     /<results_dir>/aamod_firstlevel_threshold_00001/sub-**/stats/thrT_0004.nii
% to
%     /<results_dir>/aamod_firstlevel_threshold_00001/sub-**/stats/thrT_0005.nii
%
%  These are the data plotted the 1st column of the sanity plot ("RP6") 
%  note the gray dots = individual subjects; red dot == mean (the mean value
%  is also used for the dotted line as a baseline comparison)
%
% Next, we compare: 
%
%     /<results_dir>/aamod_firstlevel_threshold_00002/sub-**/stats/spmT_0004.nii 
%     /r<esults_dir>/aamod_firstlevel_threshold_00002/sub-**/stats/spmT_0005.nii
%
% and
%
%     /<results_dir>/aamod_firstlevel_threshold_00002/sub-**/stats/thrT_0004.nii 
%     /<results_dir>/aamod_firstlevel_threshold_00002/sub-**/stats/thrT_0005.nii
%
%  These are the data shown in the 2nd column in the difference plot.
%
%  and so on, up through all 16 scrubbing branches
%
%   The unthesholded files (spmT_XXXX.nii) are used to compute RMS and correlation
%   the thresholded files (thrT_XXXX.nii) are used to compute DICE (and # sig voxels,
%   which we no longer use in the poster)
%
%   Be sure to include the nii extension in the names!
%
%   7) options.plot_label - label for plot
%   8) options.fig_fname - filename for figure (empty = don't save figure)
%
%   9) options.ROI_fname - fname to optional ROI.nii
%      (this will be checked and resliced to match the data if necessary)
%
% EXAMPLE
% 
%     options.analysis_description = 'FFL TRT testing';
%     options.results_dir = '/Volumes/DATA01/SCRUB_SUBSET/RESULTS_ds000114_FFL';
%     options.unthreshed_test = 'spmT_0006.nii';
%     options.threshed_test = 'thrT_0006.nii';
%     options.unthreshed_retest = 'spmT_0007.nii';
%     options.threshed_retest = 'thrT_0007.nii';
%     options.plot_label = 'FFL';
%     options.fig_fname = 'FFL_TRT.jpg';
%
%     options.ROI_fname = 'AI_left.nii';
% or
%     options.ROI_fname = '/Users/peellelab/scrubbing_ROI/mask_nv_lips.nii';
%


% OUTPUT (struct):
%
%   TRT.rms - test-retest rms results (nsubject x 16)
%   TRT.corr - test-retest correlation results (nsubject x 16)
%   TRT.dice - test-retest dice results (nsubject x 16)
%   TRT.descriptors - 1x16 cell array of denoising strategy descriptors
%   TRT.results_description - options.analysis_description
%
% Also, the function prints the individual file comparisons to the command
% window while it runs. You should verify that these make sense.
%
%
% NOTES
%
%   1) you might need to run this repeatedly and have a look at all the
%   test/retest contrasts and pick a good result to show -- sometimes the
%   test/retest results are poor, especially if there wasn't much data to
%   begin with
%
%   2) if you want to define ROI using seed center/radius,
%   use seeds2nii.m to convert seed to an .nii file
%
%

results_dir = options.results_dir;

unthreshed_test = options.unthreshed_test;
threshed_test = options.threshed_test;
unthreshed_retest = options.unthreshed_retest;
threshed_retest = options.threshed_retest;

PLOT_LABEL = options.plot_label;
fig_fname = options.fig_fname;

if (isfield(options,'ROI_fname') && ~isempty(options.ROI_fname))
    
    % ROI .nii likely needs resliced to match data. Let's assume
    % all the data is the same (although we sanity check during
    % extraction) and just reslice the .nii ONCE here and create
    % a correct temporary file to use (deleted on exit), rather 
    % than reslicing the ROI .nii on every extraction
    
    % pick the first tmaps to use as a template
    % (-print -quit makes find bail after one match)
    
    % (now using threshed_test in case beta map passed for unthreshed)
    
    command = sprintf('find %s/aamod_firstlevel_threshold_00001 -name %s -print -quit', results_dir, threshed_test);
    [ status,fname ] = system(command);

    if (status || ~numel(fname))
        error('ROI reslice failed');
    end

    resliceOpts = [];
    resliceOpts.mask = false;		% no masking
    resliceOpts.mean = false;		% don't write a mean image
    resliceOpts.interp = 1;			% default interp
    resliceOpts.which = 1;			% don't reslice the first image
    resliceOpts.wrap = [1 1 0];		% fMRI wrap around
    resliceOpts.prefix = 'r';		% creates ['r' options.ROI_fname ] (deleted on exit)
                                            
    spm_reslice({fname options.ROI_fname}, resliceOpts);

    [p,n,e] =  fileparts(options.ROI_fname);
    ROI_fname = fullfile(p,[ resliceOpts.prefix n e ]);
    
    
    % wavelet despiking flips R/L (sort of) -- it reverses the data then
    % flips the sign on the (1,1) .mat entry. Anyway, we need different
    % reslicing to use the mask on the wavelet despiking data...
    
    % wavelet despike = branch 00003
    
    command = sprintf('find %s/aamod_firstlevel_threshold_00003 -name %s -print -quit', results_dir, threshed_test);
    [ status,fname ] = system(command);

    if (status || ~numel(fname))
        error('ROI wavelet reslice failed');
    end

    resliceOpts = [];
    resliceOpts.mask = false;		% no masking
    resliceOpts.mean = false;		% don't write a mean image
    resliceOpts.interp = 1;			% default interp
    resliceOpts.which = 1;			% don't reslice the first image
    resliceOpts.wrap = [1 1 0];		% fMRI wrap around
    resliceOpts.prefix = 'wr';		% creates ['wr' options.ROI_fname ] (deleted on exit)
                                            
    spm_reslice({fname options.ROI_fname}, resliceOpts);

    [p,n,e] =  fileparts(options.ROI_fname);
    wROI_fname = fullfile(p,[ resliceOpts.prefix n e ]);
    
else
    ROI_fname = '';
    wROI_fname = '';
end


descriptors = {'RP6', 'RP24', 'wavelet','rWLS', 'FD1','FD2','FD5','FD10', 'FD20', 'FD40', 'DV1', 'DV2', 'DV5', 'DV10', 'DV20', 'DV40' };

% sanity check

if ~exist(results_dir,'dir')
    error('specified results directory does not exist');
end

	
% generate data

trt_rms  = [ ];
trt_corr = [ ];
trt_dice = [ ];

disp('processing baseline (6RP)');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00001', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

% save a copy of baseline results for plotting

rms_baseline = this_rms;
corr_baseline = this_corr;
dice_baseline = this_dice;

disp('processing 24 RP');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00002', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing wavelet');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00003', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, wROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing rWLS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00004', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 1% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00005', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 2% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00006', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 5% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00007', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 10% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00008', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 20% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00009', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 40% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00010', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 1% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00011', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 2% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00012', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 5% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00013', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 10% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00014', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 20% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00015', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 40% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00016', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest, ROI_fname); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];


% -------------------------------------------------------------------------------------------------------------------
% plot results for sanity check
% -------------------------------------------------------------------------------------------------------------------

h = figure('Position',[0 0 600 1000], 'Visible', 'off', 'MenuBar', 'none');
movegui(h, 'center');
set(h, 'Visible', 'on');
clf;

lightgray = [ 0.8 0.8 0.8 ];

% ----------- subplot #1: rms

subplot(3,1,1);
hold on;

thresh = mean(rms_baseline);
temp = trt_rms;

for index = 1:numel(descriptors)
	plot(index,temp(:,index),'ko','MarkerSize',8,'MarkerFaceColor',lightgray,'MarkerEdgeColor',lightgray);
	plot(index,mean(temp(:,index)),'ro','MarkerSize',14,'MarkerFaceColor','r');
end
a = axis;

% we plot the baseline as a dotted line across all scrub plots (for easy comparison)

plot([a(1) a(2)],[thresh thresh], '--', 'Color', [0.5 0.5 0.5],'LineWidth', 2);
axis([a(1) a(2) 0 1.2*a(4)]);
title(['RMS - ' strrep(unthreshed_test,'_','-')  ' vs ' strrep(unthreshed_retest,'_','-')]);
set(gca,'FontSize',14);

set(gca,'FontSize',14, 'XTick', [1:numel(descriptors)],'XTickLabel', []);


% ----------- subplot #2: corr

subplot(3,1,2);
hold on;

thresh = mean(corr_baseline);
temp = trt_corr;

for index = 1:numel(descriptors)
	plot(index,temp(:,index),'ko','MarkerSize',8,'MarkerFaceColor',lightgray,'MarkerEdgeColor',lightgray);
	plot(index,mean(temp(:,index)),'ro','MarkerSize',14,'MarkerFaceColor','r');
end
a = axis;

plot([a(1) a(2)],[thresh thresh], '--', 'Color', [0.5 0.5 0.5],'LineWidth', 2);
% axis([a(1) a(2) 0 1.0]);
title(['correlation - ' strrep(unthreshed_test,'_','-')  ' vs ' strrep(unthreshed_retest,'_','-')]);
set(gca,'FontSize',14, 'XTick', [1:numel(descriptors)],'XTickLabel', []);


% ---------- subplot #3: dice

subplot(3,1,3);
hold on;

thresh = mean(dice_baseline);
temp = trt_dice;

for index = 1:numel(descriptors)
	plot(index,temp(:,index),'ko','MarkerSize',8,'MarkerFaceColor',lightgray,'MarkerEdgeColor',lightgray);
	plot(index,mean(temp(:,index)),'ro','MarkerSize',14,'MarkerFaceColor','r');
end
a = axis;

plot([a(1) a(2)],[thresh thresh], '--', 'Color', [0.5 0.5 0.5],'LineWidth', 2);
% axis([a(1) a(2) 0 1.0 ]);
title(['DICE - ' strrep(threshed_test,'_','-')  ' vs ' strrep(threshed_retest,'_','-')]);


set(gca,...
    'XTick',1:numel(descriptors)+15,...
        'XTickLabel',descriptors,...
            'XTickLabelRotation',90);
	

set(gca,'FontSize',14);

% include the ROI in the plot label if it exists

if (isempty(ROI_fname))
    xlabel(PLOT_LABEL);
else
    [~,n,~] = fileparts(ROI_fname);
    n = strrep(n,'_','-');
    xlabel([ PLOT_LABEL ' ROI:' n ]);
end

% save as jpeg

if (~isempty(fig_fname))
    print(h,'-djpeg', '-r150', fig_fname);
end


% ------------------------------------------------------------------------------------------------------------------------------------------
% clean up
% ------------------------------------------------------------------------------------------------------------------------------------------

% load up return struct

TRT.descriptors = descriptors;
TRT.rms = trt_rms;
TRT.corr = trt_corr;
TRT.dice = trt_dice;

TRT.results_description = options.analysis_description;

% delete the resliced ROI_fnames if we created them

if (exist(ROI_fname,'file'))
    delete(ROI_fname);
end

if (exist(wROI_fname,'file'))
    delete(wROI_fname);
end


% done!

end



% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================

% helper function that does the actual difference calculations


function [ diff_RMS, diff_CORR, diff_DICE, diff_TVD ] = TRT_diff(root_dir,...
                                                                    parent_dir,... 
                                                                        unthreshed_test_fname,... 
                                                                            threshed_test_fname,... 
                                                                                unthreshed_retest_fname,... 
                                                                                    threshed_retest_fname,...
                                                                                        ROI_fname)

%----------------------------------------------------------------------------------------------------------------------------
% generate file list
%----------------------------------------------------------------------------------------------------------------------------

% NEW FEATURE: we now allow comparing beta maps (i.e. con_XXXX.nii) instead
% of unthresholded t-maps. To make this as seamless as possible, we let the
% caller pass a single parent_dir (i.e,, aamod_firstlevel_threshold_XXXX)
% and string substitute "_contrasts_" for "_threshold_" in the find string
% if unthreshed_test_fname is "con_..." and not "spmT_...". We then unsubstitute 
% before processing the thresholded t-maps (which will always be in a 
% "aamod_firstlevel_threshold_..." parent dir.
%
% Yeah, it's a little kludegy, but it works...
%

if (startsWith(unthreshed_test_fname,'con_'))
    parent_dir = replace(parent_dir,'_threshold_','_contrasts_');
end


testdir_fullpath = [root_dir '/' parent_dir];

command = sprintf('find %s -name %s', testdir_fullpath, unthreshed_test_fname);
[ status,test_list ] = system(command);

if (status || ~numel(test_list))
	error('test_list generation failed');
end

test_list = split(deblank(test_list));

% sanity check

if (numel(test_list)>1000)
	reply = input('More than 1000 files found. Continue anyway? Y/N [N]:','s');
	if isempty(reply); reply = 'N'; end
	if (strcmp(reply,'N')); return; end
	if (strcmp(reply,'n')); return; end
end

command = sprintf('find %s -name %s', testdir_fullpath, unthreshed_retest_fname);
[ status,retest_list ] = system(command);

if (status || ~numel(retest_list))
	error('retest_list generation failed');
end

retest_list = split(deblank(retest_list));

% sanity check
% there can be missing thresholded files, but missing unthresholded files
% suggests something bad happened

if (numel(retest_list) ~= numel(test_list))	
	error(sprintf('number of files in test_list (%d) =/= number in retest_list (%d)', numel(test_list), numel(retest_list)));
end

%----------------------------------------------------------------------------------------------------------------------------
% UNTHRESHOLDED METRICS (RMS and CORR)
%----------------------------------------------------------------------------------------------------------------------------

diff_RMS = zeros(numel(test_list),1);
diff_CORR = zeros(numel(test_list),1);

fprintf('*** UNTHRESHOLDED METRICS\n');

for index = 1:numel(test_list)
	fprintf('Comparing %s and %s\n', test_list{index}, retest_list{index});
	[ diff_RMS(index), diff_CORR(index), ~,~ ] = nii_diff(test_list{index}, retest_list{index}, ROI_fname);
end


%----------------------------------------------------------------------------------------------------------------------------
% THRESHOLDED METRICS (DICE and TVD)
%----------------------------------------------------------------------------------------------------------------------------

% it's possible there are missing thresholded files (aa doesn't save .nii
% t- or f-maps if no voxels survive thresholding). A missing file needs
% to be treated as a nifti full of zeros. The problem is missing files will
% jinx the collation of test_list re retest_list. So instead of generating
% the thresholded files using find, we just string sub the thresholded fname
% into both unthresholded lists, pass these to nii_diff, and add an exist()
% check in nii_diff (with appropriate calculation modification therein)

diff_DICE = zeros(numel(test_list),1);
diff_TVD = zeros(numel(test_list),1);

test_list = replace(test_list, unthreshed_test_fname, threshed_test_fname);
retest_list = replace(retest_list, unthreshed_retest_fname, threshed_retest_fname);

% this undoes the beta map kludge above if a contrast fname was passed
% instead of a t-map fname (if it wasn't, the following is harmless)

test_list = replace(test_list, '_contrasts_', '_threshold_');
retest_list = replace(retest_list, '_contrasts_', '_threshold_');


fprintf('*** THRESHOLDED METRICS\n');

for index = 1:numel(test_list)
	fprintf('Comparing %s and %s\n', test_list{index}, retest_list{index});
	[ ~,~, diff_DICE(index),diff_TVD(index) ] = nii_diff(test_list{index}, retest_list{index}, ROI_fname);
end


end



%-------------------------------------------------------------------------------
function [ drms,r,dice,dCounts ] = nii_diff(fname1, fname2, ROI_fname)
%-------------------------------------------------------------------------------

% compute four difference metrics between fname1.nii and fname2.nii:
%
%   1) drms (rms of difference)
%   2) r (correlation)
%   3) dice
%   4) difference count
%
% 1 & 2 only make sense for unthresholded data
% 3 & 4 only make sense for thresholded data
%
% fnameROI.nii is optional ROI -- it must have same dimensions/orientation
% the as data (which must have same threshold/orientation as each other)
%
% notes
%
% 1) for unthresholded images, it's assumed 0 == outside of brain
%    we neeed to restrict drms and r calculations to use in-brain
%    voxels only (zeros won't affect dice and dcount) otherwise
%    drms will be artifically low and r will be artifically high
%    If no ROI is passed, we generate an implicit mask on-the-fly.
%    (if an ROI is passed, we use all non-zero voxels in the ROI)
%

% sanity check: fname1 and/or fname2 might not exist
%
% this can happen if aa didn't save a thresholded nii because 
% there were no sig voxels. If one of the files doesn't exist, we
% can treat it like zeros. If both files don't exist, we're done:

if (~exist(fname1,'file') && ~exist(fname2,'file'))

    warning(['*** nii_diff: ' fname1 ' and ' fname2 ' not found. Metrics undefined. This is not necessarily an error.' ]);
        
	drms = NaN;
	r = NaN;
	dice = NaN;
	dCounts = NaN;
	return;
    
end

% we call the test and retest maps "data" and "benchmark", respectively...

% get the test .nii

if (exist(fname1,'file'))
	data_handle = spm_vol(fname1);			% get the test .nii
	data = spm_read_vols(data_handle(1));	% handle(1) in case its multivolume
	data(isnan(data)) = 0;					% convert any nan to zero
end

% get the retest .nii

if (exist(fname2,'file'))
	benchmark_handle = spm_vol(fname2);
	benchmark = spm_read_vols(benchmark_handle(1));
	benchmark(isnan(benchmark)) = 0;
end

% sanity check: make sure files are compatible

if (exist(fname1,'file') && exist(fname2,'file'))
    if (~isequal(data_handle.dim,benchmark_handle.dim) || norm(data_handle.mat-benchmark_handle.mat)>0.01)
        error([ '*** ' fname1 ' and ' fname2 ' are not same dimension/orientation. Exiting...' ]);
    end
end

% if one of the files doesn't exist, set its data using the other

if (~exist(fname1,'file'))
	data = zeros(size(benchmark));
end

if (~exist(fname2,'file'))
	benchmark = zeros(size(data));
end

% if we pass in an ROI file, use that for the mask
% otherwise generate an implicit mask to restrict
% calculuation to in-brain voxels only

% note mask must be type "logical"

if (isempty(ROI_fname))

    datamask = data~=0;
    benchmask = benchmark~=0;
    mask = datamask & benchmask;

else
    
    mask_handle = spm_vol(ROI_fname);
    
% there's currently weirdness being generated by wavelet despiking
% uncomment this once we get that sorted
        
    if (~isequal(data_handle.dim,mask_handle.dim) || norm(data_handle.mat-mask_handle.mat)>0.01)
        error([ '*** ROI file ' ROI_fname ' has different dimension/orientation than data. Exiting...' ]);
    end
    
    mask = spm_read_vols(mask_handle);
	mask(isnan(mask)) = 0;
    mask = mask~=0;

end


% ---------------------------------------------------------------------------------- 
% compute metrics
% ---------------------------------------------------------------------------------- 

% 1) RMS of difference
%
% note there's a function rms in SPT that should give the same result

signed_error = data - benchmark;

if (nnz(mask) > 0)	% sanity check
	drms = sqrt( dot(signed_error(mask),signed_error(mask) ) / nnz(mask) );
else
	drms = -1;
end

% 2) correlation

r = corrcoef(data(mask),benchmark(mask));		

try 
	r=r(1,2);
catch
    warning(['Correlation failed on ' fname1 ' v ' fname2 '. This is not necessarily an error.' ]);
	r = 0;	% sanity check against empty data, Nan, etc...
end

% 3) DICE

% dice == 2 * intersection(image1,image2) / nnz(image-1) + nnz(image-2)
%
% only apply mask for DICE if it came from an ROI

if (~isempty(ROI_fname))

    dice_denominator = nnz(data(mask)) + nnz(benchmark(mask));
    if (dice_denominator == 0) dice_denominator = 1; end	% sanity check
    dice = 2 * nnz(data(mask) & benchmark(mask)) / dice_denominator;

else

    dice_denominator = nnz(data) + nnz(benchmark);
    if (dice_denominator == 0) dice_denominator = 1; end	% sanity check
    dice = 2 * nnz(data & benchmark) / dice_denominator;

end


% 4) difference counts (signed) -- FYI: nnz counts NaN and Inf
%
%  only apply mask for dCounts if it came from an ROI

if (~isempty(ROI_fname))
    dCounts = nnz(data(mask))-nnz(benchmark(mask));
else   
    dCounts = nnz(data)-nnz(benchmark);
end



end




