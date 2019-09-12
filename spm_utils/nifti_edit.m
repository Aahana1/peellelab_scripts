
function nifti_edit(fname)

% edit a glass brain 3D nifti_data

% example files:

% fname = '/Users/peellelab/data/SANDBOX/DATA/defaced_t1.nii';
% fname = '/Users/peellelab/data/SANDBOX/DATA/spmT_0001.nii';


header = spm_vol(fname);
nifti_data= spm_read_vols(header);


% generate a mask (either 0 or NaN) and reapply after every edit
% (so we don't create new voxels outside the brain)

nifti_mask = nifti_data;
nift_mask(isnan(nifti_mask)) = 0;
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

            if key=='c' % clear selection
              drawall(nifti_data);
              x1 = -1;
            end

            if key=='d' % clear selection
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
            
            if key=='s' % save
                [ p,n,e ] = fileparts(fname);
                out_fname = fullfile(p,['ne_' n e]);
                header.fname = out_fname;
                spm_write_vol(header, nifti_data); 
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
text(0,0.9,'d to delete selection','FontSize',14);
text(0,0.8,'c to clear selection','FontSize',14);
text(0,0.7,'v set selection to value','FontSize',14);
text(0,0.6,'s to save','FontSize',14);
text(0,0.5,'q to quit','FontSize',14);

[ r,c,s ] = size(nifti_data);
text(0,0.1,sprintf('Dimensions: %d x %d x %d', r,c,s),'FontSize',14);

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


% reapply mask

data = nifti_mask .* data;

end





end







