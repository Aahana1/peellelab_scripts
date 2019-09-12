function dicomCheck(aap)
%
% crawl the results folder for dicom headers and
% print critical information like TR. For epis, just print
% the header for the first frame (the rest are assumed
% to be the same)
%
% Note this will repeat headers for as many times as they
% are found in the results tree.
%

if (~isstruct(aap) || isempty(aap))
	disp('Usage: dicomCheck(aap)');
	return;
end

cd([aap.acq_details.root '/' aap.directory_conventions.analysisid]);

fprintf('Checking structural dicom headers...\n');
command = sprintf('find -s `pwd` -name structural_dicom_header.mat');
[status,header_list] = system(command);
if (status);disp('Error searching for structural headers. Exiting...');end
print_structural_header_info(header_list);

fprintf('Checking epi dicom headers...\n');
command = sprintf('find -s `pwd` -name dicom_headers.mat');
[status,header_list] = system(command);
if (status);disp('Error searching for epi headers. Exiting...');end
print_epi_header_info(header_list);

end


function print_structural_header_info(raw_header_list)

if (isempty(raw_header_list))
	disp('no structural headers found');
	return;
end


header_list = split(raw_header_list);
header_list(end) = [];

for index = 1:size(header_list,1)
	clear dcmhdr;
	load(char(header_list(index)));
	fprintf('Filename: %s\n', dcmhdr{1}.Filename);
	fprintf('volumeTR: %f\n', dcmhdr{1}.volumeTR);
end

end




function print_epi_header_info(raw_header_list)

if (isempty(raw_header_list))
	disp('no epi headers found');
	return;
end

header_list = split(raw_header_list);
header_list(end) = [];

for index = 1:size(header_list,1)
	clear DICOMHEADERS;
	load(char(header_list(index)));
	fprintf('Filename: %s\n', DICOMHEADERS{1}.Filename);
	fprintf('volumeTR: %f\n', DICOMHEADERS{1}.volumeTR);
	fprintf('volumeTE: %f\n', DICOMHEADERS{1}.volumeTE);
end

end




