function [ errflag,errstring ] = overlay_nifti(nii_fname, template_fname, render_fname, text_label)
%
% create render & three orthogonal overlays for the specified
% nifti using the SPM and aa image functions and save to jpg in
% the same directory the nifti lives
%
%   nii_fname           - nifti to overlay (fullpath if not in working dir)
%   template_fname      - structural template (fullpath if not in working dir)
%   render_fname        - render template (fullpath if not in working dir)
%   text_label          - text used to label figure (empty = no label)
%
% for example:
%
%       nii_fname = 'thrT_0001.nii';
%       template_fname = '/Applications/MATLAB_R2016b.app/toolbox/spm12/toolbox/OldNorm/T1.nii';
%       render_fname = '/Applications/MATLAB_R2016b.app/toolbox/spm12/rend/render_single_subj.mat';
%
% If the first char isn't '/', the function will look in under the spm install dir, i.e.:
%
%       template_fname = 'toolbox/OldNorm/T1.nii';
%       render_fname = 'rend/render_single_subj.mat';
%

errflag = 0;
errstring = '';

rendfile = render_fname;

% sanity checks

p = dir(nii_fname);
if (isempty(p))
    errstring = 'nifti file not found';
    errflag = 1;
    return;
end

p = dir(rendfile);
if isempty(p) && (rendfile(1) ~= '/') 
    rendfile = fullfile(fileparts(which('spm')),rendfile); 
end
     
p = dir(rendfile);
if isempty(p)
    errstring = 'render file not found';
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
        
% ------------------------------------------------------------------------
% 1) Render - we can use shortcut in spm_render by just passing
% in the nifti and render image filename
% ------------------------------------------------------------------------

% need to set up global prevrend for some reason...

global prevrend
prevrend = struct('rendfile', rendfile, 'brt',0.5, 'col',eye(3));
out = spm_render(nii_fname,0.5,rendfile);
spm_figure('Close','Graphics');

% squeeze render output into montage and write to file

for i = 1:numel(out), img(1:size(out{i},1),1:size(out{i},2),:,i) = out{i}; end
mon = tr_3Dto2D(squeeze(img(:,:,1,[1 3 5 2 4 6])));
mon(:,:,2) = tr_3Dto2D(squeeze(img(:,:,2,[1 3 5 2 4 6])));
mon(:,:,3) = tr_3Dto2D(squeeze(img(:,:,3,[1 3 5 2 4 6])));
mon = mon(1:size(mon,2)*2/3,:,:);			

if (~isempty(text_label))
    mon = insertInImage(mon, @()text(40,25,text_label),...
    {'fontweight','bold','color','y','fontsize',16,...
    'linewidth',1,'margin',5,'backgroundcolor','k'});	
end

imwrite(mon,strrep(nii_fname,'.nii','_render.jpg'));
  
% ------------------------------------------------------------------------
% 2) three ortho section overlays 
% (this code mostly stolen from aamod_firstlevel_threshold...)
% ------------------------------------------------------------------------

transparency = 0.4;
nth_slice = 3; 

template_header = spm_vol(template_fname);
[ Ytemplate,~ ] = spm_read_vols(template_header);

% work out threshold for template

threshprop=0.10;
ys=sort(Ytemplate(~isnan(Ytemplate)));
bright3=ys(round(length(ys)*0.3));
bright97=ys(round(length(ys)*0.97));
thresh=bright3*(1-threshprop)+bright97*threshprop;
Ytemplate=Ytemplate.*(Ytemplate>thresh);

% need nifti to match template

nifti_header = spm_vol(nii_fname);

if (~isequal(nifti_header.dim, template_header.dim) ||	norm(nifti_header.mat-template_header.mat)>0.01)

    resliceOpts = [];
    resliceOpts.mask = false;
    resliceOpts.mean = false;
    resliceOpts.interp = 1;
    resliceOpts.which = 1;		% DON'T reslice the first image
    resliceOpts.wrap = [0 0 0];	% this is everywhere in aa even though it should be [1 1 0] for MRI
    resliceOpts.prefix = 'r';

    spm_reslice({template_header.fname, nifti_header.fname}, resliceOpts);
    
    [ p,n,e ] = fileparts(nii_fname);
    nifti_header = spm_vol(fullfile(p,[resliceOpts.prefix n e]));

end

[ rYepi,~ ] = spm_read_vols(nifti_header);
        
fnsl = '';

for a = 0:2 % in 3 axes

    arYepi = shiftdim(rYepi,a);
    aYtemplate = shiftdim(Ytemplate,a);
    
    % Adjust slice selection according to the activation
    
    for iSl = 1:nth_slice 
        iYepi = arYepi(:,:,iSl:nth_slice:end);
        if any(iYepi(:)~=0), break; end
    end
    
    iYepi = img_rot90(iYepi);
    iYtemplate = img_rot90(aYtemplate(:,:,iSl:nth_slice:end));

    [ img,~,~ ] = map_overlay(iYtemplate,iYepi,1-transparency);                                
    mon = tr_3Dto2D(img_tr(img(:,:,:,1),a==2));
    mon(:,:,2) = tr_3Dto2D(img_tr(img(:,:,:,2),a==2));
    mon(:,:,3) = tr_3Dto2D(img_tr(img(:,:,:,3),a==2));
    fnsl(a+1,:) = strrep(nii_fname,'.nii',sprintf('_%d.jpg', a));

    if (~isempty(text_label))
        mon = insertInImage(mon, @()text(40,25,text_label),...
        {'fontweight','bold','color','y','fontsize',14,...
        'linewidth',1,'margin',5,'backgroundcolor','k'});	
    end

    imwrite(mon,deblank(fnsl(a+1,:)));

end

% delete resliced image if one was created

[ p,n,e ] = fileparts(nii_fname);
try delete(fullfile(p,[resliceOpts.prefix n e])); catch; end

    
end 
 
 

function fo = img_rot90(fi)
for i = 1:size(fi,3)
    fo(:,:,i) = rot90(fi(:,:,i),1);
end
end


function fo = img_tr(fi,toDo)
if nargin < 2, toDo = true; end
if toDo
    nslice = size(fi,3);
    for i = 1:nslice
        fo(:,:,i) = fliplr(rot90(fi(:,:,i),1));
    end
else
    fo = fi;
end
end
