function [ voxels,XYZ ] = extract_voxels(nii_fname, centers, radii)

%
% extract voxel values from 3D or 4D .nii given one or more seeds (XYZ center + radius)
%
% INPUTS
%
%   nii_fname  - fname of nii to process
%   centers    - 3xn XYZ defining seed centers (3 x nseeds) <= note column vec!
%   radii      - n radii, or a single value that will be used for to all seeds
%
% OUTPUT
%   voxels  - voxel values (nseed x 1 or nseed x nframes)
%   XYZ     - XYZ of voxel values (3 x number of voxels in seeds)
%
% NOTES
%
% 1) uses marsbar for voxel extraction (unless radii = 0)
%
% HISTORY
%
% 02/2020 [MSJ] - new
%

voxels = [];
XYZ = [];

% sanity checks

if (nargin < 3) 
    fprintf('Usage: extract_voxels(nii_fname, centers, radii)\n');
    return;
end


% in case caller left off extension...

[ p,n,~ ] = fileparts(nii_fname);
nii_fname = fullfile(p,[n '.nii']);

% if only one radius was passed we apply it to all centers

nseeds = size(centers,2);

if (length(radii) ~= nseeds)
    radii = radii * ones(nseeds,1);
end

% extract
   
header = spm_vol(nii_fname);

for index = 1:nseeds
    this_center = centers(:,index);
    this_radius = radii(index);
    [ this_v,this_XYZ ] = extract_voxel_values_around_seed(header, this_center, this_radius);
    XYZ = [ XYZ this_XYZ ];
    voxels = [ voxels ; this_v ];
end


end


%-------------------------------------------------------------------------------------------
function [ voxels,XYZ ] = extract_voxel_values_around_seed(nii_handle, seed_center, radius)
%-------------------------------------------------------------------------------------------

imgMat = nii_handle.mat;
imgDim = nii_handle.dim;

% marsbar ROI extraction
%
% maroi_sphere doesn't like radius = 0 (voxpts returns empty ROI) so
% for 1-voxel seed (i.e., radius=0) just do mat\[seedmm 1]'
% (note maroi_sphere sometimes fails if radius = 1)

if (radius > 0) 

    ROI = maroi_sphere(struct('centre', seed_center, 'radius', radius));
    roiIJK = voxpts(ROI, struct('mat', imgMat, 'dim', imgDim));
    if (isempty(roiIJK))
        fprintf('%s: Seed %s resulted in empty ROI. Skipping...', mfilename);
        voxels = 0;        
    else      
        roiIJK = [ roiIJK; ones(1, size(roiIJK,2)) ];
        voxels = spm_get_data(nii_handle, roiIJK);      
    end

else

    roiIJK =  round(imgMat\[seed_center ; 1]);
    voxels = spm_get_data(nii_handle, roiIJK);

end

XYZ = imgMat * roiIJK;
XYZ = XYZ(1:3,:);

voxels = reshape(voxels,[],size(XYZ,2))';


end


