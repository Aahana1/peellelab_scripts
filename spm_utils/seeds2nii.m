function [ errflag,errstring ] = seeds2nii(centers, radii, template_fname, nii_fname, voxel_value)

%
% create .nii from an ROI specified as a collection of seeds (XYZ center + radius)
%
% INPUTS
%
%   centers         - 3xn XYZ defining seed centers. (NB: 3xn -- i.e. COLUMN WISE)
%   radii           - nx1 seed radii, or a single value that will be applied to all
%   template_fname  - template image to use (fullpath if not in working dir)
%                     Ex:   '/Applications/spm12/toolbox/OldNorm/T1.nii';
%                           '/Users/peellelab/OLF_SEEDS/atlas.nii'
%   nii_fname       - fname of nii to create (saved in pwd if not fullpath)
%                     (NB: if the file exists it will be overwritten)
%
%   OPTIONAL
%
%   voxel_value - voxel value for ROI (default = 1)
%
% ATLAS MODE
%
% if voxel_value = "index", then the voxel value for each ROI is set equal
% to the ordinal position of the seed in "centers" (i.e., all voxels in the 
% first ROI have a value of 1, all in the second have a value of 2, and so
% on. This is useful for generating an indexed ROI atlas.
%
% NOTES
%
% 1) ROI centers are assumed to be in template space
%
% 2) uses marsbar for voxel extraction
%       addpath(genpath('/Users/peellelab/MATLAB_THIRDPARTY/marsbar'))
%
% 3) A voxel value > 1 is recommended when overlaying ROI on tmaps
%    - see comments in overlay_nifti.m
%
% CHANGE HISTORY
%
% 05/2020 [MSJ] - added "atlas mode" option
% 2019 [MSJ] - new
%

errflag = 0;
errstring = '';

% sanity checks

if (nargin < 4) 
    errstring = 'Usage:seeds2nii(centers, radii, template_fname, nii_fname[, voxel_value])';
    errflag = 1;
    return;
end

p = dir(template_fname);
if (template_fname(1) ~= '/') 
    template_fname = fullfile(fileparts(which('spm')),template_fname); 
end

p = dir(template_fname);
if (isempty(p))
    errstring = 'template file not found';
    errflag = 1;
    return;
end


nseeds = size(centers,2);
    
if (nargin < 5) 
    voxel_values = ones(nseeds,1);
else
    if (ischar(voxel_value))
        voxel_values = 1:nseeds;    % "atlas mode"
    else
        voxel_values = voxel_value * ones(nseeds,1);
    end
end

% if only one radius was passed we apply it to all centers

if (length(radii) ~= nseeds)
    radii = radii * ones(nseeds,1);
end

% convert seed defs into XYZ values
   
header = spm_vol(template_fname);

seed_XYZ = cell(nseeds,1);

for index = 1:nseeds
    this_center = centers(:,index);
    this_radius = radii(index);
    temp = [];
    [ ~,temp ] = extract_voxel_values_around_seed(header, this_center, this_radius); 
    seed_XYZ{index} = temp;
end

% write to nii

% in case caller left off extension...

[ p,n,~ ] = fileparts(nii_fname);
nii_fname = fullfile(p,[n '.nii']);

fprintf('Creating %s...\n', nii_fname);

Y = spm_read_vols(header);
Y(:) = 0;

for index = 1:nseeds
    temp = seed_XYZ{index};
    IJK = header.mat\[ temp; ones(1,size(temp,2)) ];
    Y(sub2ind(size(Y),IJK(1,:),IJK(2,:),IJK(3,:))) = voxel_values(index);
end

nifti_write_localcopy(nii_fname, Y, 'ROI2nii', header);
  
end



%---------------------------------------------------------------------------------
function nifti_write_localcopy(fname,Y,desc,V)
%---------------------------------------------------------------------------------

    dim = size(Y);
    N      = nifti;
    N.dat  = file_array(fname,dim,V.dt);
    N.mat  = V.private.mat;
    N.mat0 = V.private.mat;
    N.descrip     = desc;
    create(N);

    dim = [dim 1];
    for i = 1:prod(dim(4:end))
        N.dat(:,:,:,i) = Y(:,:,:,i);   
        spm_get_space([N.dat.fname ',' num2str(i)], V.mat);
    end
    N.dat = reshape(N.dat,dim);
    
end




%-------------------------------------------------------------------------------------------
function [ voxels,XYZ ] = extract_voxel_values_around_seed(nii_handle, seed_center, radius)
%-------------------------------------------------------------------------------------------

imgMat = nii_handle.mat;
imgDim = nii_handle.dim;

% seed_center = seed.center;
% radius = seed.radius;

% marsbar ROI extraction
%
% "seed" is one voxel; "voxels" is all voxels within radius
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

    roiIJK =  round(imgMat\[seed_center 1]');
    voxels = spm_get_data(nii_handle, roiIJK);

end

% roiIJK is (row,col,stack) -- XYZ is more useful for caller

voxels = voxels(:);
% voxels(isnan(voxels)) = 0;    % no! let caller decide
XYZ = imgMat * roiIJK;
XYZ = XYZ(1:3,:);

end


