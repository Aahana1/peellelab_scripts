function [ onsets, events, durations, auxdata ] = parse_metadata(fname, columnOrder)
%
% Parse a peellelab metadata file 
%
% Usage: 
%
% [ onsets, events, durations, auxdata ] = parse_metadata(fname, [columnOrder]);
%
% fname can be a full path (otherwise we expect the metadata to be
% in the current working directory)
%
% the file can either be standard BIDS event data or Peelle metadata which
% has the following file columns:
%
%       rowindex onset event duration auxdata
%
% - "rowindex" is discarded - this was a Chad workaround for a software glitch
% - "onset" is event onset milliseconds relative to start of scan
% - "event" is a string descriptor or code for the event
% - "duration" or a column of zeros if the events don't have a duration
% - "auxdata" or a column of zeros if no aux data (e.g., scoring) provided
%
% by default these are assumed to be the first five columns. However, you may
% use other ordering and select the five columns of interest in the passed
% variable "columnOrder"
%
% There should be no blank rows in the file. Events and auxdata should
% be all descriptors (string) or all codes (numeric). Do not mix data
% types within a column. The top row of the file is skipped and can be
% anything (e.g., column headers used to assist a human reader).
%
% Some apps generate enclosed string entries in double quotes. This is not
% acceptable. There should be no quotes in the file.

% CHALLENGE: we need to parse both peellelab- and BIDS-type metadata.
%
%   1) peellelab metdata is Excel csv with extra leading column
%
%       read using: T = readtable(fname);
%
%   2) BIDS is plain text tsv
%
%       read using:
%
%       T = readtable(fname,'FileType','text','Delimiter','\t')
%
% WE ASSUME A TSV EXTENSION INDICATES BIDS-STYLE DATA - set default
% columns accordingly (BIDS data doesn't have the weird leading column
% that's in the peellelab Excel files). However, if caller passes in an
% explicit columnOrder vec, we just use that.)
%
% CHANGE HISTORY
%
%   09/2019 [MSJ] - added BIDS tsv capability
%	08/2019 [MSJ] - added columnOrder, now uses 'readtable'
%   wawa [MSJ] - new
%

onsets = [];
events = [];
durations = [];
auxdata = [];

if (nargin < 1)
	disp('Usage: %s(filename, [columnOrder]', mfilename);
	return;
end

[ ~,~,e ] = fileparts(fname);

if strcmp(e,'.tsv')
    BIDS_style_metadata = true;
else
    BIDS_style_metadata = false;
end

if (isempty(columnOrder))
    
     % standard column order
     
     if (BIDS_style_metadata == true)
         
        % BIDS column 3 is "weight" -- we never use it
         
        column_latency  = 1;
        column_events   = 4;     
        column_duration = 2;
    
     else
         
        % Peellelab metadata format: skip col-1, then
        % latency, eventname, & duration are cols 2,3,4...
        % (we no longer read "auxdata" col -- see note below)
         
        column_latency  = 2;
        column_events   = 3;     
        column_duration = 4;

     end
    
else
    
        column_latency = columnOrder(1);
        column_events = columnOrder(2);
        column_duration = columnOrder(3);
  
end

fid = fopen(fname,'r');

if (fid < 0)
	fprintf('%s: Cannot open %s', mfilename, fname);
	return;
end

if (BIDS_style_metadata == true)
	T = readtable(fname,'FileType','text','Delimiter','\t');
else
  T = readtable(fname);
end

fclose(fid);

onsets = double(T{:,column_latency});
events = T{:,column_events};
durations = double(T{:,column_duration});

% initially, we returned a 4th column of "auxiliary" data
% -- this wasn't general enough to be useful; ergo now we
% return the entire table in "auxdata" and let the caller
% process it as need be

% auxdata = T{:,column_auxdata};
auxdata = T;

end
