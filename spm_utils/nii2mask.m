function nii2mask(fname,thresh)

% convert a (3D) nifti into a mask (e.g., voxel => voxel>thresh)
%
% thresh can be a number, or 'mean' or 'median'

header = spm_vol(fname);
data = spm_read_vols(header);

switch thresh
    
    case 'mean'
        f = sprintf('i1>%f', mean(data(:),'omitnan'));

    case 'median'
         f = sprintf('i1>%f', median(data(:),'omitnan'));
      
    otherwise
        f = sprintf('i1>%f', thresh);
        
end
    
[ p,n,e ] = fileparts(fname);
out_fname = fullfile(p,['m' n '.' e]);

Q = header;          
Q.fname =  out_fname;
flags = {[],[],[],[]};
      
Q = spm_imcalc(fname, Q, f, flags);   

end

