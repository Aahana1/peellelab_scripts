%
% change the Series Number in a collection of dicom files
%
%
% ----------------------------------------------------------------------------
% change this section to fit your needs

directory_name = '/Users/peellelab/DATA/HEMI/SUBJECTS/HEMI/SCANS/182/DICOM';

OLDSERIESNUMBER = 18;
NEWSERIESNUMBER = 19;

% ----------------------------------------------------------------------------

cd(directory_name);

new_dir_name = fullfile(directory_name, num2str(NEWSERIESNUMBER));

if (exist(new_dir_name) == 0)
	mkdir(directory_name, num2str(NEWSERIESNUMBER));
end

flist = dir('*.dcm');

for index = 1:numel(flist)
	
	fname = flist(index).name;
	
	ddata = dicomread(fname);

	metadata = dicominfo(fname);
	
	% change the series number in the header
	
	metadata.SeriesNumber = NEWSERIESNUMBER;
	
	% change the filename
	
	fname = strrep(fname,['.' num2str(OLDSERIESNUMBER) '.'],['.' num2str(NEWSERIESNUMBER) '.']);
	
	% write the new file
	
	outfilepath = fullfile(directory_name, num2str(NEWSERIESNUMBER), fname);
	
	disp(outfilepath);
	
% 	dicomwrite(ddata, outfilepath, metadata);	% this creates an unusable file
	dicomwrite(ddata, outfilepath, metadata, 'CreateMode', 'copy', 'WritePrivate', true); % do this instead

end
