function [aap,resp] = aamod_epi_from_ANALYZE(aap, task, subj, sess)
%
% aamod_epi_from_ANALYZE
%
% read epi images in Analyze format (.img/.hdr pairs)
%
% user must supply acquisition information that will be used to construct 
% a minimal dicom header. See the accompanying .xml file for details
%
% output streams:
%
%	epi -- single .nii file or colleciton of 3D .nii
%   dummyscans -- dummy scans omitted from epi
%	epi_dicom_header -- minimal dicom header (see notes)
%
% Notes
%
% 1) epi_dicom_header is not a proper dicom header (which typically contain
% hundreds of entries). Rather, it has a few important parameters
% some other modules might use. If you don't include a module in your
% tasklist that takes epi_dicom_header as an input stream, you can fill
% epi_dicom_header with nonsense and aa will never know. However, you
% probably at least want to specify the correct TR.
%
% in fact, TR is so important, it's the only parameter w/o a default value
% you must specify a value in the script or using extraparameters
%
% 2) aamod_epifromnifti can ostensively read .img/.hdr pairs, but it
% requires you to supply the header information as an external file
% in either a custom or json (BIDS) format.
%
% 3) specify the input as a cell array (you only need to specify
% the .img). This is most easily accomplished using spm_select, e.g,:
%
%	sfile = '/fullpath/of/structural.img';
%	flist = spm_select('FPList', '/directory/of/files', '.*img$');
%	aap = aas_addsubject(aap, 'S01', 'S01', 'structural', {sfile}, 'functional', {fList});
%
%
% Revision History
%
% [MSJ] -- New (simplified from aamod_epifromnifti)
%

resp='';

switch task
	
    case 'report'
		
    case 'doit'
		
        %% Select
		
        series = horzcat(aap.acq_details.subjects(subj).seriesnumbers{:});
				
		if ~iscell(series)
  			aas_log(aap, true, sprintf('\n%s: Was expecting a list of .img in a cell array.\n', mfilename));
		end
		
        series = series{sess};
        
        %% Process
				
        headerFn ='';
        imageFn = series;
		
        if isstruct(imageFn)
            headerFn = imageFn.hdr;
            imageFn = imageFn.fname;
		end
		
        headerfile = headerFn;
        niftifile = imageFn;
		
        if ~iscell(niftifile), niftifile = {niftifile}; end % 4D-NIFTI
		
        if ~exist(niftifile{1},'file') % assume path realtive to (first) rawdatadir
            niftisearchpth=aas_findvol(aap,'');
            if ~isempty(niftisearchpth)
                niftifile = spm_file(imageFn,'path',niftisearchpth);
                if ~isempty(headerFn)
                    headerfile = spm_file(headerFn,'path',niftisearchpth);
                end
            end
		end
		        
		% Generate a faux dicom header from xml parameters
		%
		% user MUST define TR, but we supply defaults for the other values
		% because they typically don't get used so the typical user 
		% doesn't need to known them.
		%
		% Software 101: don't make the user care about irrelevant things.
		%
	
        DICOMHEADER{1} = struct;
		
		if (isempty(aap.tasklist.currenttask.settings.repetition_time)) 
			aas_log(aap, true, sprintf('\n%s: You must specify a repetition time.\n', mfilename));
		else
			TR = aap.tasklist.currenttask.settings.repetition_time;
			aas_log(aap, false, sprintf('\n%s: Using TR of %d ms.\n', mfilename, TR));
		end
		
		DICOMHEADER{1}.RepetitionTime = aap.tasklist.currenttask.settings.repetition_time;
		DICOMHEADER{1}.EchoTime = aap.tasklist.currenttask.settings.echo_time;
		DICOMHEADER{1}.SliceTiming = aap.tasklist.currenttask.settings.slice_timing;
		DICOMHEADER{1}.EchoSpacing = aap.tasklist.currenttask.settings.echo_spacing;

        DICOMHEADER{1}.volumeTR = DICOMHEADER{1}.RepetitionTime/1000;
        DICOMHEADER{1}.volumeTE = DICOMHEADER{1}.EchoTime/1000;
        DICOMHEADER{1}.slicetimes = DICOMHEADER{1}.SliceTiming/1000;
        DICOMHEADER{1}.echospacing = DICOMHEADER{1}.EchoSpacing/1000;
        
		[junk, DICOMHEADER{1}.sliceorder] = sort(DICOMHEADER{1}.slicetimes);
  		
        % read the image data
		
        epi_file_list = {};
		
        V = spm_vol(niftifile); V = cell2mat(V);
        session_path=aas_getsesspath(aap,subj,sess);
        aas_makedir(aap,session_path);
        fle = spm_file(niftifile,'basename');
        ext = spm_file(niftifile,'Ext');
		
        for fileind=1:numel(V)
            Y = spm_read_vols(V(fileind));
            if numel(niftifile) == 1
				% 4D-NIFTI
                fn = fullfile(session_path,sprintf('%s_%04d.%s',fle{1},fileind,ext{1}));
			else
				% 3D-NIFTI
                fn = fullfile(session_path,[fle{fileind} '.' ext{fileind}]);
            end
            V(fileind).fname = fn;
            V(fileind).n = [1 1];
            spm_write_vol(V(fileind),Y);
            epi_file_list = [epi_file_list fn];
        end;
        
  		if (~isempty(aap.tasklist.currenttask.settings.phase_encoding_direction)) 
			DICOMHEADER{1}.PhaseEncodingDirection = aap.tasklist.currenttask.settings.phase_encoding_direction;
			DICOMHEADER{1}.NumberOfPhaseEncodingSteps = V(1).dim(cell_index({'x' 'y'}, DICOMHEADER{1}.PhaseEncodingDirection(1)));
		end
		
		% Write out the files
        
        % First, move dummy scans to dummy_scans directory
		
		numdummies = aap.acq_details.numdummies;
        if ~isempty(aap.tasklist.currenttask.settings.numdummies)
            numdummies=aap.tasklist.currenttask.settings.numdummies;
		end
		
		dummylist=[];
        if numdummies
            dummypath = fullfile(session_path, 'dummy_scans');
            aap = aas_makedir(aap,dummypath);
            for d=1:numdummies
                cmd = ['mv ' epi_file_list{d} ' ' dummypath];
                [pth nme ext]=fileparts(epi_file_list{d});
                dummylist=strvcat(dummylist,fullfile('dummy_scans',[nme ext]));
                [s w]=aas_shell(cmd);
                if (s)
                    aas_log(aap,1,sprintf('%s: Problem moving dummy scan\n%s\nto\n%s\n', mfilename, convertedfns{d}, dummypath));
                end
            end
        else
            d = 0;
		end
			
		% 4D conversion
		%
		% we do an automatic 4D conversion for two reasons: 1) many times it's the right thing
		% to do (i.e. NIFTI4D == true) 2) many modules don't play nice w/ streams consisting
		% of collections of .img/.hdr files even though they're supposed to. So we at least
		% need to convert to a colleciton of .nii files. Testing indicates the most reliable
		% way to do this is make a 4D then unpack it, even though that may seem ridiculous 
	
	    subjname = aap.acq_details.subjects(subj).subjname;
		sessname = aap.acq_details.sessions(sess).name;
		final_epi_file = [ subjname '_' sessname '.nii' ];
		final_epi_file = fullfile(session_path, final_epi_file);
					
		if iscell(V), V = cell2mat(V); end
		spm_file_merge(char({V(numdummies+1:end).fname}), final_epi_file, 0);
		
		% we no longer need the .img/.hdr files
		
		delete(fullfile(session_path,'*.img'));
		delete(fullfile(session_path,'*.hdr'));
		
		% if user doesn't want 4D nifti, unpack and delete the package
		% (assume 4D is default -- user has to explicitly not want it)
		
		if (isfield(aap.options,'NIFTI4D') && aap.options.NIFTI4D==false)
			V = spm_vol(final_epi_file);
			temp = spm_file_split(V);
			delete(final_epi_file);
			final_epi_file = char(temp(:).fname);
		end
		
        %  describe outputs
		
		aap=aas_desc_outputs(aap,subj, sess, 'epi', final_epi_file);
		
        aap = aas_desc_outputs(aap, subj, sess, 'dummyscans', dummylist);
		
        dicomheader_fname = fullfile(session_path, 'dicom_headers.mat');
        save(dicomheader_fname, 'DICOMHEADER');
        aap = aas_desc_outputs(aap, subj, sess, 'epi_dicom_header', dicomheader_fname);
        
    case 'checkrequirements'
        
    otherwise
        aas_log(aap,1,sprintf('%s: Unknown task %s\n', mfilename, task));
		
end;


end
