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
%       spmT_000Y.nii - UNthresholded
%       thrT_000Y.nii - thresholded
%
%   where Y depends on the contrast you want to examine and depends on the order the contrasts were
%   defined in the usescript. For example, here are the contrasts for the flanker data (ds000002):
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
% that is, we compare:
%
%     /<results_dir>/aamod_firstlevel_threshold_00001/sub-**/stats/spmT_0004.nii 
%     /<results_dir>/aamod_firstlevel_threshold_00001/sub-**/stats/spmT_0005.nii
%
% and
%
%     /<results_dir>/aamod_firstlevel_threshold_00001/sub-**/stats/thrT_0004.nii 
%     /<results_dir>/aamod_firstlevel_threshold_00001/sub-**/stats/thrT_0005.nii
%
%  These are the data plotted the 1st column of the sanity plot ("RP6") 
%  -- gray dots = individual subjects; red dot == mean (the mean value is
%  also used for the dotted line as a baseline comparison)
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
%   Be sure to include the nii extension in the name!
%
%   note you might need to run this repeatedly and have a look at all
%   the test/retest contrasts and pick a good result to show -- sometimes the
%   test/retest results are poor, especially if there wasn't much data to
%   begin with
%
%   7) options.plot_label - label for plot
%   8) options.fig_fname - filename for figure (empty = don't save figure)
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

results_dir = options.results_dir;

unthreshed_test = options.unthreshed_test;
threshed_test = options.threshed_test;
unthreshed_retest = options.unthreshed_retest;
threshed_retest = options.threshed_retest;

PLOT_LABEL = options.plot_label;
fig_fname = options.fig_fname;

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

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00001', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

% save a copy of baseline results for plotting

rms_baseline = this_rms;
corr_baseline = this_corr;
dice_baseline = this_dice;

disp('processing 24 RP');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00002', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing wavelet');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00003', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing rWLS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00004', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 1% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00005', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 2% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00006', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 5% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00007', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 10% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00008', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 20% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00009', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 40% FD');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00010', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 1% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00011', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 2% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00012', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 5% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00013', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 10% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00014', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 20% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00015', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

trt_rms = [ trt_rms , this_rms ];
trt_corr = [ trt_corr , this_corr ];
trt_dice = [ trt_dice , this_dice ];

disp('processing 40% DVARS');

[ this_rms, this_corr, this_dice, ~ ] = TRT_diff(results_dir, 'aamod_firstlevel_threshold_00016', unthreshed_test, threshed_test, unthreshed_retest, threshed_retest); 

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
xlabel(PLOT_LABEL);

% save as jpeg

if (~isempty(fig_fname))
    print(h,'-djpeg', '-r150', fig_fname);
end


% ------------------------------------------------------------------------------------------------------------------------------------------
% load up return struct
% ------------------------------------------------------------------------------------------------------------------------------------------

TRT.descriptors = descriptors;
TRT.rms = trt_rms;
TRT.corr = trt_corr;
TRT.dice = trt_dice;

TRT.results_description = options.analysis_description;

end



% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================
% ==========================================================================================================================

% helper function that does the actual diff calculations


function [ diff_RMS, diff_CORR, diff_DICE, diff_TVD ] = TRT_diff(root_dir,...
                                                                    parent_dir,... 
                                                                        unthreshed_test_fname,... 
                                                                            threshed_test_fname,... 
                                                                                unthreshed_retest_fname,... 
                                                                                    threshed_retest_fname)

%----------------------------------------------------------------------------------------------------------------------------
% UNTHRESHOLDED METRICS (RMS and CORR)
%----------------------------------------------------------------------------------------------------------------------------

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

diff_RMS = zeros(numel(test_list),1);
diff_CORR = zeros(numel(test_list),1);

%----------------------------------------------------------------------------------------------------------------------------
% UNTHRESHOLDED METRICS (RMS and CORR)
%----------------------------------------------------------------------------------------------------------------------------

fprintf('*** UNTHRESHOLDED METRICS\n');

for index = 1:numel(test_list)
	fprintf('Comparing %s and %s\n', test_list{index}, retest_list{index});
	[ diff_RMS(index), diff_CORR(index), ~,~ ] = nii_diff(test_list{index}, retest_list{index});
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

fprintf('*** THRESHOLDED METRICS\n');

for index = 1:numel(test_list)
	fprintf('Comparing %s and %s\n', test_list{index}, retest_list{index});
	[ ~,~, diff_DICE(index),diff_TVD(index) ] = nii_diff(test_list{index}, retest_list{index});
end


end



%-------------------------------------------------------------------------------
function [ rms,r,dice,dCounts ] = nii_diff(fname1, fname2)
%-------------------------------------------------------------------------------

% add a few checks to handle the possibility fname1 and/or fname2 might
% not exist (e.g., aa didn't save a thresholded nii w/ no sig voxels)

% if both files don't exist, we're done

if (~exist(fname1,'file') && ~exist(fname2,'file'))
	rms = 0;		% true but misleading
	r = 0;			% technically NaN
	dice = 0;
	dCounts = 0;	% also misleading
	return;
end

% get the test .nii

if (exist(fname1,'file'))
	data_handle = spm_vol(fname1);			% get the test .nii
	data = spm_read_vols(data_handle(1));	% handle(1) here just in case its multivolume
	data(isnan(data)) = 0;					% remove any nan
end

% get the retest .nii

if (exist(fname2,'file'))
	benchmark_handle = spm_vol(fname2);
	benchmark = spm_read_vols(benchmark_handle(1));
	benchmark(isnan(benchmark)) = 0;
end

% if one of the files doesn't exist, set its data using the other

if (~exist(fname1,'file'))
	data = zeros(size(benchmark));
end

if (~exist(fname2,'file'))
	benchmark = zeros(size(data));
end

% ---------------- compute metrics

% 1) correlation

% do an implicit mask to mask common voxels outside of brain,
% otherwise correlation will be artificially inflated

% note this will be wonky for thresholded nii -- but we shouldn't
% be using corr on thresholded nii anyway...

datamask = data~=0;
benchmask = benchmark~=0;
mask = datamask & benchmask;
r = corrcoef(data(mask),benchmark(mask));	% mask must be type "logical"	

try 
	r=r(1,2);
catch
	r = 0;	% sanity check against empty data, Nan, etc...
end

% 2) DICE

% DICE is binarized, not thresholded (assume the thingies we dice
% are already thresholded). Note nnz will also count negative values
% -- is that okay?

dice_denominator = nnz(data) + nnz(benchmark);
if (dice_denominator == 0) dice_denominator = 1; end	% sanity check
dice = 2 * nnz(data & benchmark) / dice_denominator;

% 3) raw counts difference

dCounts = [ nnz(data)-nnz(benchmark) ];

% 4) RMS of difference 

signed_error = data - benchmark;

if (nnz(mask) > 0)	% sanity check
	% rms = sqrt(dot(signed_error(:),signed_error(:))/length(signed_error(:))); % this uses all voxels
	% rms = sqrt(dot(signed_error(mask),signed_error(mask))/length(mask(:)));	% don't use voxels outside of brain!
	rms = sqrt( dot(signed_error(mask),signed_error(mask)) /nnz(mask) );		% oops -- want nnz(mask) not length(mask(:))!
else
	rms = -1;
end


end








	




