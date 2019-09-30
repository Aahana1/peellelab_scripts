
global st


% clist = [ ...
%   -25   -98   -12 ; ...
%    27   -97   -13 ; ...
%    24    32   -18 ; ...
%   -56   -45   -24 ; ...
%     8    41   -24 ];

clist = [ -43 -71 23 ; 45 -65 22 ];
	

background_image = '/Users/peellelab/DATA/SPM_canonical_copy/avg152T1.nii';

% ----------------------------------------------
% loop though coords, display w/ crosshairs
% ----------------------------------------------

spm_image('Display',background_image);

disp('forcing NN interpolation...');
spm_orthviews('Interp',0);

h = findobj(st.fig,'Tag','spm_image:mm'); 
 
if ~isempty(h)
	
for index = 1:size(clist,1)
		coords = clist(index,:);
		set(h,'String',sprintf('%.1f %.1f %.1f',coords));
		spm_image('setposmm');
        pause;
end
	
spm_figure('Close','Graphics');
	
end






 
 
 
 



