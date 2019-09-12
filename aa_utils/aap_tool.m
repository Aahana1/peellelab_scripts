function aap_tool(aap)
%
% format the aap struct as an html doc for easy (well, easier) review
%

savedir = pwd;

if (isempty(aap))
	disp('Usage: aap_tool(aap)');
	return;
end

cd([aap.acq_details.root '/' aap.directory_conventions.analysisid]);


fid = fopen('aap.htm','w');
if (fid < 0); cleanup_and_exit(2); end

html_make_head(fid);
html_add_table_of_contents(fid, aap);
html_add_aap_contents(fid,aap);
html_close(fid);

cleanup_and_exit(0);
cd(savedir);


%-----------------------------------------------------------------------------------------------------------------------------------
% cleanup_and_exit - THIS MUST BE NESTED FOR VARIABLE ACCESS
%-----------------------------------------------------------------------------------------------------------------------------------

function cleanup_and_exit(ierr)

	if exist('fid');fclose(fid);end
	cd(savedir);
	if (ierr)
		if exist('aap','var')
			aas_log(aap, true, sprintf('\n%s: aap format generation failed (ierr = %d.\n', mfilename, ierr));
		else
			error('aap format generation failed (ierr = %d).\n', ierr);
		end
	end
	
end


end % NESTED


%-----------------------------------------------------------------------------------------------------------------------------------
% html_make_head
%-----------------------------------------------------------------------------------------------------------------------------------

function html_make_head(fid)

	% create the html head, which now includes css for index
	
	% <meta name="viewport" content="width=device-width, initial-scale=1">

	fprintf(fid,'%s\n','<!DOCTYPE html>');
	fprintf(fid,'%s\n','<html>');
	fprintf(fid,'%s\n','<head>');
	fprintf(fid,'%s\n','<style>');
	fprintf(fid,'%s\n','body {');
	fprintf(fid,'%s\n','    margin: 0;');
	fprintf(fid,'%s\n','}');
	fprintf(fid,'%s\n','');
	fprintf(fid,'%s\n','ul {');
	fprintf(fid,'%s\n','    list-style-type: none;');
	fprintf(fid,'%s\n','    margin: 0;');
	fprintf(fid,'%s\n','    padding: 0;');
	fprintf(fid,'%s\n','    width: 20%;');
	fprintf(fid,'%s\n','    background-color: #f1f1f1;');
	fprintf(fid,'%s\n','    position: fixed;');
	fprintf(fid,'%s\n','    height: 100%;');
	fprintf(fid,'%s\n','    overflow: auto;');
	fprintf(fid,'%s\n','}');
	fprintf(fid,'%s\n','');
	fprintf(fid,'%s\n','li a {');
	fprintf(fid,'%s\n','    display: block;');
	fprintf(fid,'%s\n','    color: #000;');
	fprintf(fid,'%s\n','    padding: 8px 16px;');
	fprintf(fid,'%s\n','    text-decoration: none;');
	fprintf(fid,'%s\n','    font-size:12px;');
	fprintf(fid,'%s\n','    font-weight:bold;');
	fprintf(fid,'%s\n','}');
	fprintf(fid,'%s\n','');
	fprintf(fid,'%s\n','li a.active {');
	fprintf(fid,'%s\n','    background-color: #4CAF50;');
	fprintf(fid,'%s\n','    color: white;');
	fprintf(fid,'%s\n','}');
	fprintf(fid,'%s\n','');
	fprintf(fid,'%s\n','li a:hover:not(.active) {');
	fprintf(fid,'%s\n','    background-color: #555;');
	fprintf(fid,'%s\n','    color: white;');
	fprintf(fid,'%s\n','}');
	fprintf(fid,'%s\n','</style>');
	fprintf(fid,'%s\n','</head>');
	fprintf(fid,'%s\n','<body>');

	fprintf(fid,'%s\n','<title>analysis settings</title>');

end

%-----------------------------------------------------------------------------------------------------------------------------------
% html_add_table_of_contents
%-----------------------------------------------------------------------------------------------------------------------------------

function html_add_table_of_contents(fid, aap)

	% add a clickable table of contents tab based on modules
	
	% the entries go like:
	%
	% 	<li><a href="#tag01">aamod_firstlevel_threshold_00001</a></li>
	% 	<li><a href="#tag02">aamod_norm_noss_00001</a></li>
	% 	<li><a href="#tag03">aamod_firstlevel_model_00001</a></li>
	% 	<li><a href="#tag03">aamod_firstlevel_model_00002</a></li>
	% 	<li><a href="#tag03">aamod_firstlevel_model_00003</a></li>

	% call this after make_html_head 

	% this is based on aap if module_list is a struct
	% or parse out the modules if module_list is a cell array

	fprintf(fid,'<ul>\n');
	fprintf(fid,'<br/> &nbsp; CONTENTS<br/><br/>\n');
	
	fprintf(fid,'<hr/>\n');
	
	% directory_conventions
	
	fprintf(fid,'<li><a href="#dir_cons">aap.directory_conventions</a></li>\n');

	% options
	
	fprintf(fid,'<li><a href="#options">aap.options</a></li>\n');
	
	% acquisition details
	
	fprintf(fid,'<li><a href="#acq_det">aap.acq_details</a></li>\n');
	
	% spm options
	
	fprintf(fid,'<li><a href="#spm_opts">aap.spm</a></li>\n');
	
	tasknames = sprintf('%s ', aap.tasklist.main.module.name);
	tasknames = split(tasknames);
	tasknames(end) = [];

	for index = 1:numel(tasknames)
		module_name = aap.tasklist.main.module(index).name;
		instance = find(index==find(strcmp(tasknames,module_name)));
		fprintf(fid,'<li><a href="#tag%02d">%s_%05d</a></li>\n', index, module_name, instance);
	end
				
  	fprintf(fid,'</ul>\n');

end



%-----------------------------------------------------------------------------------------------------------------------------------
% html_add_aap_contents 
%-----------------------------------------------------------------------------------------------------------------------------------

function html_add_aap_contents(fid, aap)

	% div IDs must match TOC tags!
	
	% aap.directory_conventions
	
	html_open_named_div(fid, 'dir_cons');
	fprintf(fid,'<br/><b>aap.directory_conventions</b><br/><br/>\n');
	html_pp_struct(fid, aap.directory_conventions);
	html_close_div(fid);

	% aap.options
	
	html_open_named_div(fid, 'options');
	fprintf(fid,'<br/><b>aap.options</b><br/><br/>\n');
	html_pp_struct(fid, aap.options);
	html_close_div(fid);

	% aap.options
	
	html_open_named_div(fid, 'acq_det');
	fprintf(fid,'<br/><b>aap.acq_details</b><br/><br/>\n');
	html_pp_struct(fid, aap.acq_details);
	html_close_div(fid);

	% aap.spm
	
	html_open_named_div(fid, 'spm_opts');
	fprintf(fid,'<br/><b>SPM options</b><br/><br/>\n');
	html_pp_struct(fid, aap.spm);
	html_close_div(fid);
	
	% get a list of all modules in tasklist, including repeats
	
	tasknames = sprintf('%s ', aap.tasklist.main.module.name);
	tasknames = split(tasknames);
	tasknames(end) = [];
	
	for index = 1:numel(aap.tasklist.main.module)
		
		module_name = aap.tasklist.main.module(index).name;
		instance = find(index==find(strcmp(tasknames,module_name)));
	
		divID = sprintf('tag%02d',index);
		html_open_named_div(fid, divID);
		fprintf(fid,'<br/><b>%s_%05d</b><br/><br/>\n', module_name, instance);
		html_pp_struct(fid,aap.tasksettings.(module_name)(instance));
			
		% note custom params are in tasklist, not tasksettings...
		
		if (isfield(aap.tasklist.main.module(index).extraparameters.aap,'tasklist'))
			fprintf(fid,'<br/><font color="red">\n');
			fprintf(fid,'Customized xml Parameters<br/><br/>\n');
			html_pp_struct(fid, aap.tasklist.main.module(index).extraparameters.aap.tasklist.currenttask.settings);
			fprintf(fid,'</font>\n');
		end

		html_close_div(fid);
		
	end


end


%-----------------------------------------------------------------------------------------------------------------------------------
% html_open_named_div
%-----------------------------------------------------------------------------------------------------------------------------------

function html_open_named_div(fid, ID)

	% the margin-left percent here needs to play nice with the toc css
	% also note: double %% is % literal

% 	fprintf(fid, '<div id="%s" style="font-family:courier;margin-left:20%%;padding:1px 16px;height:1000px;">\n', ID);
	fprintf(fid, '<div id="%s" style="font-family:courier;margin-left:20%%;padding:1px 16px;">\n', ID);

end
	

%-----------------------------------------------------------------------------------------------------------------------------------
% html_add_linebreak
%-----------------------------------------------------------------------------------------------------------------------------------

function html_add_linebreak(fid,s)

	if (isempty(s))
		fprintf(fid, '<br/>\n');
	else
		fprintf(fid, '<h4>%s</h4>\n', s);
	end

end

%-----------------------------------------------------------------------------------------------------------------------------------
% html_close_div
%-----------------------------------------------------------------------------------------------------------------------------------

function html_close_div(fid)
	fprintf(fid, '</div>');
end

%-----------------------------------------------------------------------------------------------------------------------------------
% html_close
%-----------------------------------------------------------------------------------------------------------------------------------

function html_close(fid)
	fprintf(fid, '<br/><br/></body></html>');
end



%-----------------------------------------------------------------------------------------------------------------------------------
% html_pp_struct
%-----------------------------------------------------------------------------------------------------------------------------------

function html_pp_struct(fid, s, level)

% pretty print the contents of s, recursively if need-be
%
% inputs
%
% fid	- file handle (assumed valid)
% s		- struct
% level - level of recursion (default: 0)
%

if nargin < 3
	level = 0;
end

if ~isstruct(s)
	if	ischar(s)					value = sprintf('%s',s);
	elseif (islogical(s) && s)		value = sprintf('true');
	elseif (islogical(s) && ~s)		value = sprintf('false');
	elseif isvector(s) && ~isempty(s) && isnumeric(s(1))
									imax = 16;
									if (length(s)<imax);imax=length(s);end
									temp = sprintf('%g ',s(1:imax)); 
									value = sprintf('%s',temp);
	% this must come *after* isvector...
	elseif isnumeric(s)				value = sprintf('%s', num2str(s));
	end
	fprintf(fid, '%s : <b>%s</b><br/>\n',  fn{n}, value);
	return;		
end

fn = fieldnames(s);

for n = 1:length(fn)

	tabs = '&nbsp';
	for m = 1:level
		tabs = [tabs '&nbsp'];
	end
		
	fn2 = getfield(s, fn{n});

	value = [];
	
	% the various checks here are the results of fixing many crashes...

	if	ischar(fn2)						value = sprintf('%s',fn2);
		elseif (islogical(fn2) && fn2)	value = sprintf('true');
		elseif (islogical(fn2) && ~fn2) value = sprintf('false');
		elseif isvector(fn2) && ~isempty(fn2) && isnumeric(fn2(1))
										imax = 16;
										if (length(fn2)<imax);imax=length(fn2);end
										temp = sprintf('%g ',fn2(1:imax)); 
										value = sprintf('%s',temp);
		% this must come *after* isvector...
		elseif isnumeric(fn2)			value = sprintf('%s', num2str(fn2));
	end

	fprintf(fid, '%s %s : <b>%s</b><br/>\n', tabs, fn{n}, value);
	
	if isstruct(fn2)
		for index = 1:numel(fn2) % fn2 might be an ARRAY of structs
			html_pp_struct(fid, fn2(index), level+1);
		end
	end
	
	

end

end


