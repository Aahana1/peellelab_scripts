
function nifti_edit(fname)

% edit a glass brain 3D nifti_data

% example files:

% fname = '/Users/peellelab/data/SANDBOX/DATA/defaced_t1.nii';
% fname = '/Users/peellelab/data/SANDBOX/DATA/spmT_0001.nii';
% fname = '/Users/peellelab/data/SANDBOX/DATA/con_0008.nii';
% fname = '/Users/peellelab/con_0001.nii';

header = spm_vol(fname);
[ nifti_data,XYZ ] = spm_read_vols(header);

% NaNs don't play nice with our code:

nifti_data(isnan(nifti_data)) = 0;

% generate a mask to reapply after every edit
% so we don't accidentially create new voxels outside the brain

nifti_mask = nifti_data;
nifti_mask = ~~nifti_mask;

figure('Name',fname,'NumberTitle','off','Position',[0 0 800 800],'MenuBar', 'none');
set(gcf,'Units','normalized')

drawall(nifti_data);

x1 = -1; % indicates "no selection"


while 1 == 1
    
w = waitforbuttonpress;

  switch w 
      
      case 1     % keyboard 
          
            key = get(gcf,'currentcharacter');

            if key=='q'  % quit
              break
            end

            if key=='u' % unselect
              drawall(nifti_data);
              x1 = -1;
            end
                        
            if key=='l' % delete left side
              nifti_data(XYZ(1,:)<=0) = 0;           % assumes MNI normed!
              drawall(nifti_data);
              x1 = -1;
            end

            if key=='r' % delete right side
              nifti_data(XYZ(1,:)>=0) = 0;           % assumes MNI normed!
              drawall(nifti_data);
              x1 = -1;
            end         
                        
            if key=='d' % delete voxels in selection
              nifti_data = set_voxels(nifti_data,x1,y1,x2,y2,plane,0);
              drawall(nifti_data);
              x1 = -1;
            end
          
            if key=='v' % value
                prompt = {'Enter new voxel value'};
                dlgtitle = 'Voxel Value';
                answer = inputdlg(prompt, dlgtitle,1,{'0'});
                nifti_data = set_voxels(nifti_data,x1,y1,x2,y2,plane,str2double(answer{1}));
                drawall(nifti_data);
                x1 = -1;
            end
            
            if key=='1' % enter a single voxel value
                prompt = {'Enter new value as: x(mm),y(mm),z(mm),v'};
                dlgtitle = 'Voxel Value';
                answer = inputdlg(prompt, dlgtitle,1,{'0'});
                answer = split(answer,',');
                xyz = header.mat \ [str2double(answer{1}) str2double(answer{2}) str2double(answer{3}) 1]';
                xyz = round(xyz);
                nifti_data(xyz(1),xyz(2),xyz(3)) = str2num(answer{4});           
                drawall(nifti_data);
                x1 = -1;
            end

            if key=='e' % expand (convolve with 3x3x3 block)
                nifti_data = convn(nifti_data,ones(3,3,3),'same');
                drawall(nifti_data);
                x1 = -1;
            end
            
            if key=='b' % binarize
                nifti_data = ~~nifti_data;
                drawall(nifti_data);
                x1 = -1;
            end

                
             
            % applying the starting mask is an simple way
            % to make sure no voxels get added outside the brain.
            % We used to do this automatically, but it doesn't
            % work if we're adding to a sparse nifti (e.g., ROI)
            % bc the mask deletes everything outside the initial
            % content). So make it an explicit option.
                          
            if key=='m' % apply starting mask
                nifti_data = nifti_mask .* nifti_data;
                drawall(nifti_data);
                x1 = -1;
            end
                   
            if key=='s' % save
                [ p,n,e ] = fileparts(fname);
                out_fname = fullfile(p,['ne_' n e]);
                header.fname = out_fname;
                nifti_save(out_fname, nifti_data,'created by nifti_edit', header);
                uiwait(msgbox(sprintf('File written to %s',out_fname),'', 'modal'));
            end
          
        case 0    % mouse click 
          
            plane = get(gca,'tag');
            mousept = get(gca,'currentPoint');
            x1 = mousept(1,1);
            y1 = mousept(1,2);
            % we use rbbox for feedback, but need to use
            % currentPoint bc rbbox returns coords wrt entire fig
            rect_pos = rbbox;
            annotation('rectangle',rect_pos,'Color','red','LineWidth',2) 
            mousept = get(gca,'currentPoint');
            x2 = mousept(1,1);
            y2 = mousept(1,2);


  end
  
end

close(gcf);





%----------------------------------------------------------------------
function drawall(nifti_data)
%----------------------------------------------------------------------

clf
set(gcf,'Units','normalized')

subplot(2,2,1);
plot_data = squeeze(sum(nifti_data,2));
% pcolor(plot_data);
imagesc(plot_data);
axis ij
% axis square
axis equal
axis off
set(gca,'Tag','axial');
title('axial');

subplot(2,2,2);
plot_data = squeeze(sum(nifti_data,3));
% pcolor(plot_data);
imagesc(plot_data);
axis ij
% axis square
axis equal
axis off
set(gca,'tag','sagittal');
title('sagittal');

subplot(2,2,3);
plot_data = squeeze(sum(nifti_data,1));
% pcolor(plot_data);
imagesc(plot_data);
axis ij
% axis square
axis equal;
axis off
set(gca,'tag','coronal');
title('coronal');

subplot(2,2,4)
axis off
text(0,1,'drag mouse to select','FontSize',14);
text(0,0.9,'d - delete selection','FontSize',14);
text(0,0.8,'u - unselect','FontSize',14);
text(0,0.7,'v - set selection to value','FontSize',14);
text(0,0.6,'l[r] - clear left[right] hemisphere','FontSize',14);
text(0,0.5,'1 - specify one voxel','FontSize',14);
text(0,0.4,'e - expand','FontSize',14);
text(0,0.3,'m - (re)mask','FontSize',14);
text(0,0.2,'b - binarize','FontSize',14);
text(0,0.1,'s - save; q - quit','FontSize',14);

[ r,c,s ] = size(nifti_data);
text(0,0,sprintf('Dimensions: %d x %d x %d', r,c,s),'FontSize',14);

colormap gray

end



%----------------------------------------------------------------------
function data = set_voxels(data,x1,y1,x2,y2,plane,newvalue)
%----------------------------------------------------------------------

x1 = round(x1);
y1 = round(y1);
x2 = round(x2);
y2 = round(y2);

% disp([ x1 y1 ]);
% disp([ x2 y2 ]);
% plane

if (x1>x2)
    temp = x1;
    x1 = x2;
    x2 = temp;
end

if (y1>y2)
    temp = y1;
    y1 = y2;
    y2 = temp;
end

switch plane
    
    case 'axial'
        data(y1:y2,:,x1:x2) = newvalue;
       
    case 'sagittal'
        data(y1:y2,x1:x2,:) = newvalue;
        
    case 'coronal'
        data(:,y1:y2,x1:x2) = newvalue;

end


% reapply mask - opdate: change this to m option
% % % data = nifti_mask .* data;

end



%----------------------------------------------------------------------
function nifti_save(fname,Y,desc,V)
%----------------------------------------------------------------------

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



end







