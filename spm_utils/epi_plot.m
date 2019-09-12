function epi_plot(nifti_data)

% plot a nift and cursor-selected voxel timecourses

% example files:
%
% fname = '/Users/peellelab/data/SNIFF/RS_TEST/aamod_QA_voxelcorr_00001/27_PREOT/SESS01/rf27preOT-0014.nii';
% fname = '/Users/peellelab/data/SNIFF/RS_TEST/aamod_QA_voxelcorr_00003/27_PREOT/SESS01/Res-0001.nii';

% you can pass in data or a filename

if (ischar(nifti_data) && exist(nifti_data,'file'))
    header = spm_vol(nifti_data);
    nifti_data = spm_read_vols(header);
end

[ r,c,s,nvols ] = size(nifti_data);

if (nvols < 2)
    error('data is not timeseries');
end

display_data = nifti_data(:,:,:,1);

xplane = round(r/2);
yplane = round(c/2);
zplane = round(s/2);

wlow = 0.01;
whigh = 0.1;

figh = figure('Name', 'Epi Plot', 'NumberTitle', 'off', 'Position', [0 0 1000 600], 'MenuBar', 'none', 'Visible', 'off');
movegui(figh,'center');
set(figh,'Visible', 'on');
set(gcf,'Units','normalized');

plot_display_volume(display_data,xplane,yplane,zplane);
plot_timeseries_at_xyz(nifti_data,xplane,yplane,zplane,wlow,whigh);

while 1 == 1
    
w = waitforbuttonpress;

  switch w 
      
      case 1  % keyboard 
          
            key = get(gcf,'currentcharacter');

            if key=='q'  % quit
              break
            end
         
            if key=='b'
                prompt = {'wLow', 'wHigh'};
                dlgtitle = 'bandpass';
                answer = inputdlg(prompt, dlgtitle, 1, { num2str(wlow) num2str(whigh) });
                wlow = str2num(answer{1});
                whigh = str2num(answer{2});
             end 
                      
        case 0  % mouse click 
          
            plane = get(gca,'tag');
            
            mousept = get(gca,'currentPoint');
            
            x1 = mousept(1,1);
            y1 = mousept(1,2);
         
            switch plane
                
                case 'p1'
                    zplane = round(x1);
                    yplane = round(y1);
                    
                case 'p2'
                    zplane = round(x1);
                    xplane = round(y1);
                   
                case 'p3'
                    yplane = round(x1);
                    xplane = round(y1);
                  
            end
            
  end
  
 plot_display_volume(display_data,xplane,yplane,zplane)
 plot_timeseries_at_xyz(nifti_data,xplane,yplane,zplane,wlow,whigh);

  
end

close(gcf);

end


%----------------------------------------------------------------------
function plot_display_volume(data,xplane,yplane,zplane)
%----------------------------------------------------------------------

clf
set(gcf,'Units','normalized')

subplot(2,3,1);
plot_data = data(xplane,:,:);
plot_data = squeeze(plot_data);

imagesc(plot_data);
hold on;
axis ij
axis equal
axis off
a = axis;
plot([zplane zplane],[a(3) a(4)],'r');
plot([a(1) a(2)],[yplane yplane],'g');
set(gca,'Tag','p1');
title('plane 1','FontSize',14);

subplot(2,3,2);
plot_data = data(:,yplane,:);
plot_data = squeeze(plot_data);
imagesc(plot_data);
hold on;
axis ij
axis equal
axis off
a = axis;
plot([zplane zplane],[a(3) a(4)],'r');
plot([a(1) a(2)],[xplane xplane],'y');
set(gca,'tag','p2');
title('plane 2','FontSize',14);

subplot(2,3,3);
plot_data = data(:,:,zplane);
plot_data = squeeze(plot_data);
imagesc(plot_data);
hold on;
axis ij
axis equal;
axis off
a = axis;
plot([yplane yplane],[a(3) a(4)],'g');
plot([a(1) a(2)],[xplane xplane],'y');
set(gca,'tag','p3');
title('plane 3','FontSize',14);

colormap gray

end


%----------------------------------------------------------------------
function plot_timeseries_at_xyz(data,vx,vy,vz,wlow,whigh)
%----------------------------------------------------------------------

[b,a] = butter(2,[wlow whigh]);

x = data(vx,vy,vz,:);
x = squeeze(x);

subplot(2,3,[4 5 6])
cla;
plot(x,'LineWidth',2);
hold on;

% plot(x2,'y','LineWidth',2);

xfilt = filtfilt(b,a,x);
plot(xfilt,'r','LineWidth',2);
axis tight;
grid on;

xvar = var(x);
xfiltvar = var(xfilt);

s = sprintf('mean: %.2f variance: %.2f  variance (filtered):  %.2f', mean(x), xvar, xfiltvar);
title(s,'FontSize',14);

s = sprintf('timeseries at (%d,%d,%d) (blue = raw, red = filtered) - b to change filter bandwidth; q to quit', vx,vy,vz');
xlabel(s,'FontSize',10);

end






