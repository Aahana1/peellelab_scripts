function img2nii(fname)

% convert a (3D) ANALYZE file (.img/.hrd pair) to nifti (single .nii)

[ p,n,~ ] = fileparts(fname);
out_fname = fullfile(p,[n '.nii']);
fname = fullfile(p,[n '.img']);

header = spm_vol(fname);
Y = spm_read_vols(header);

nifti_write(out_fname, Y, 'converted using img2nii', header);

end

