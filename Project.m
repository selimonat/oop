classdef Project < handle
    % This is the PROJECT object that other objects will
    % be a child of. Here enters all the project specific data (e.g. the
    % subject ids) and methods (for e.g. getting paths from the dicom
    % server).
    %
    % The first set of properties has to be entered by hand. For example
    % TRIO_SESSIONS should be entered manually for your experiment. The
    % other properties drive from these. 
    %
    % To create the standard project structure you will need to call the
    % CreateFolderHierarchy method. Based on dicom2run, trio_sessions,
    % data_folders properties, the folder hierarchy will be created. These 
	% folders will later be populated by dump_epi and dump_hr methods. 
    %
    % Once you data is nicely loaded into the subject/run/ structure,
    % SanityCheck method comes very handy to ensure that your project
    % folders have all the size they should be.
    %
    % Don't forget to add spm, smr to your path, they are defined below,
    % however automatic changing of path names is not recommended.
	% 
	% Current methods:
	%
    % CreateFolderHierarchy: Will create a folder hierarchy to store data
	% SanityCheck: Will bar-plot the content of your folders
    % DicomDownload: connects to dicom server and dumps the epi and hr data
    % DicomTo4D: 3D 2 4D conversion
    % MergeTo4D: 3D 2 4D conversion
    % ConvertDicom: convert dicoms
    % dicomserver_request: unix-specific commands to talk with dicomserser.
    % dicomserver_paths: unix-specific commands to talk with dicomserser.
    % dartel_templates: location of dartel templates
	% SecondLevel_ANOVA: conducts secondlevel analysis.
    % VolumeGroupAverage: can average lots of images.
    % VolumeSmooth: smooths volumes
    % RunSPMJob: runs spm jobs.
    %
    % Feel free to improve this help section.
    %
    % 7
    
    properties (Hidden, Constant)%adapt these properties for your project
        %All these properties MUST BE CORRECT and adapted to one owns
        %project

        path_project          = '/projects/fearamy/data/';        
        path_spm              = '/home/onat/Documents/Code/Matlab/spm12-6685/';        
        trio_sessions         = {  '' '' '' '' 'TRIO_17468' 'TRIO_17476' 'TRIO_17477' 'TRIO_17478' 'TRIO_17479' 'TRIO_17480' 'TRIO_17481' 'TRIO_17482' 'TRIO_17483' 'TRIO_17484' 'TRIO_17485' 'TRIO_17486' 'TRIO_17487' 'TRIO_17488' 'TRIO_17514' 'TRIO_17515' 'TRIO_17516' 'TRIO_17517'  'TRIO_17520' 'TRIO_17521' 'TRIO_17522' 'TRIO_17523' 'TRIO_17524' 'TRIO_17525' 'TRIO_17526' 'TRIO_17527' 'TRIO_17557' 'TRIO_17558' 'TRIO_17559' 'TRIO_17560'  'TRIO_17563' 'TRIO_17564' 'TRIO_17565' 'TRIO_17566' 'TRIO_17567' 'TRIO_17568' 'TRIO_17569' 'TRIO_17570' 'TRIO_17571' 'TRIO_17572'};
        dicom_serie_selector  = {  [] [] []   []      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [5 6 7]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]      [3 4 5]       [3 4 5]       [3 4 5]      [3 4 5]      [3 4 5]    [3 4 5]       [3 4 5]       [3 4 5]     [3 4 5]     [4 5 6]       [3 4 5]      [3 4 5]     [3 4 5]       [3 4 5]      [3 4 5]        [3 4 5]     [3 4 5]       [3 4 5]      [3 4 5]       [3 4 5]     [3 4 5]     [4 5 6]      [3 4 5]    };
        %this is necessary to tell matlab which series corresponds to which
        %run (i.e. it doesn't always corresponds to different runs)
        dicom2run             = [1 1 1];%how to distribute TRIO sessiosn to folders.
        data_folders          = {'eye' 'midlevel' 'mrt' 'scr' 'stimulation' 'pmf' 'rating'};%if you need another folder, do it here.
        TR                    = 0.99;                
        HParam                = 128;%parameter for high-pass filtering
        surface_wanted        = 0;%do you want CAT12 toolbox to generate surfaces during segmentation (0/1)                
        smoothing_factor      = [4 6 8];%how many mm images should be smoothened when calling the SmoothVolume method                
        path_smr              = sprintf('%s%ssmrReader%s',fileparts(which('Project')),filesep,filesep);%path to .SMR importing files in the fancycarp toolbox.
        gs                    = [5 6 7 8 9 12 14 16 17 18 19 20 21 24 25 27 28 30 32 34 35 37 39 40 41 42 43 44];
        subjects              = [];
        bs                    = [10 11 13 15 22 23 26 29 31 33 36 38];        
        %
        mbi_ucs               = [5 13 16 20 22 28 33 36 40 45 47 53 54 61];
        mbi_oddball           = [6 65];
        mbi_transition        = [22 23 45 46];
        mbi_invalid           = sort([Project.mbi_ucs,Project.mbi_oddball,Project.mbi_transition]);
        mbi_valid             = setdiff(1:65,Project.mbi_invalid);
        roi                   = struct('xyz',{[30 0 -24] [30 22 -8] [33 22 6] [39 22 -6] [44 18 -13] [-30 18 -6] [-9 4 4] [40 -62 -12]},'label',{'rAmy' 'rAntInsula' 'rAntInsula2' 'rAntInsula3' 'rFronOper' 'lAntInsula' 'BNST' 'IOC'} );%in mm
        colors                = [ circshift( hsv(8), [3 0] );[0 0 0];[.8 0 0];[.8 0 0]]';
        valid_atlas_roi       = setdiff(1:63,[49 50 51]);%this excludes all the ROIs that are huge in number of voxels
        ucs_vector            = [];  
        ucs_vector_notcleaned = [];
    end
    properties (Constant,Hidden) %These properties drive from the above, do not directly change them.
        tpm_dir               = sprintf('%stpm/',Project.path_spm); %path to the TPM images, needed by segment.         
        path_second_level     = sprintf('%sspm/',Project.path_project);%where the second level results has to be stored        
		current_time          = datestr(now,'hh:mm:ss');
        subject_indices       = setdiff(find(cellfun(@(x) ~isempty(x),Project.trio_sessions)),15);% will return the index for valid subjects (i.e. where TRIO_SESSIONS is not empty). Useful to setup loop to run across subjects.15 has huge motion artefacts.
        PixelPerDegree        = 29;
        screen_resolution     = [768 1024];%%%;%this is the size of the face on the facecircle;[212 212];
        path_stim             = sprintf('%sstim/ave.png',Project.path_project);
    end    
    properties (Hidden,Constant)
        atlas2mask_threshold  = 30;%where ROI masks are computed, this threshold is used.        
        %voxel selection
        selected_smoothing    = 10;%smoothing for selection of voxels;
        selected_model        = 3;%fmri model (see CreateModel)
        selected_betas        = 1:4
        selected_ngroup       = 1;
        %
        scale_feartunings     = 0;
        selected_fitfun       = 8;%3fixed gaussian (3), vonmises (8); vonMises template (55); vM centered
        pval                  = .05;%tuning presence
        borders               = 1000;
        eye_data_type         = 'countw';
        select_scr_trials     = 5;
        tuning_criterium      = 1;%2
    end  
	properties (Hidden)
        normalization_method  = 'CAT';%which normalization method to use. possibilities are EPI or CAT
    end
    methods
        function DU         = SanityCheck(self,runs,measure,varargin)
            %DU = SanityCheck(self,runs,measure,varargin)
			%will run through subject folders and will plot their disk
            %space. Use a string in VARARGIN to focus only on a subfolder.
            %MEASURE has to be 'size' or 'amount', for disk usage and
            %number of files, respectively. This only works on Unix systems.
            cd(self.path_project);%
            total_subjects = length(Project.trio_sessions);
            DU = nan(total_subjects,length(runs));
            warning('off','all');
            for ns = 1:total_subjects
                for nr = runs
                    fprintf('Requesting folder size for subject %03d and run %03d\n',ns,nr);
                    subject_run = self.pathfinder(ns,nr);
                    if ~isempty(subject_run)
                        fullpath = fullfile(subject_run,varargin{:});                    
                        if strcmp(measure,'size')
                            [a b]       = system(sprintf('/usr/bin/du -cd0 %s | grep -e total | grep -oh -e [0-9]*',fullpath));
                             DU(ns,nr+1)= str2double(b)./1024;
                        elseif strcmp(measure,'amount')
                            [a b]       = system(sprintf('/usr/bin/find %s | wc -l',fullpath));
                            DU(ns,nr+1) = str2double(b);
                        else
                            fprint('Please enter a valid MEASURE...\n');
                            return
                        end
                    else
                        fprintf('Folder doesn''t exist: %s\n',subject_run);
                    end
                end                
            end
            %%
            if isempty(varargin)
                varargin{1} = '*';
            end
            n = 0;
            for nr = runs
                n = n + 1;
                subplot(length(runs),1,n)
                bar(DU(:,n));ylabel('MB or #','fontsize',10);xlabel('Subjects','fontsize',10);box off                
                title(sprintf('Subfolder: %s Run: %i',varargin{1},nr),'fontsize',10);
            end
            warning('on','all');
        end
        function              DicomDownload(self,source,destination)
            % Will download all the dicoms, convert them and merge them to
            % 4D.
            
            if ~ismac & ~ispc
                %proceeds with downloading data if we are NOT a mac not PC
                
                fprintf('%s:\n','DicomDownload');
                %downloads data from the dicom dicom server
                if exist(destination) == 0
                    fprintf('The folder %s doesn''t exist yet, will create it...\n',destination)
                    mkdir(destination)
                end
                if ~isempty(source) & ~isempty(destination)%both paths should not be empty.
                    fprintf('Calling system''s COPY function to dump the data...%s\nsource:%s\ndestination:%s\n',self.current_time,source,destination)
                    a            = system(sprintf('cp -r %s/* %s',source,destination));
                    if a ~= 0
                        fprintf('There was a problem while dumping...try to debug it now\n');
                        keyboard
                    else
                        fprintf('COPY finished successully %s\n',self.current_time)
                    end
                else
                    fprintf('Either source or destination is empty\n');
                    return
                end
            else
                fprintf('DicomDownload: To use DicomDownload method you have to use one of the institute''s linux boxes\n');
            end
        end
        function              DicomTo4D(self,destination)
            %A wrapper over conversion and merging functions.
            
            %start with conversion
            self.ConvertDicom(destination);
            %finally merge 3D stuff to 4D and rename it data.nii.
            self.MergeTo4D(destination);
        end
        function              MergeTo4D(self,destination)
            %will create data.nii consisting of all the [f,s]TRIO images
            %merged to 4D. the final name will be called data.nii.
            % merge to 4D
            files       = spm_select('FPListRec',destination,'^fTRIO');
            fprintf('MergeTo4D:\nMerging (%s):\n',self.current_time);
            matlabbatch{1}.spm.util.cat.vols  = cellstr(files);
            matlabbatch{1}.spm.util.cat.name  = 'data.nii';
            matlabbatch{1}.spm.util.cat.dtype = 0;
            self.RunSPMJob(matlabbatch);            
            fprintf('Finished... (%s)\n',self.current_time);
            fprintf('Deleting 3D images in (%s)\n%s\n',self.current_time,destination);
            files = cellstr(files);
            delete(files{:});
        end
        function              ConvertDicom(self,destination)
            % dicom conversion. ATTENTION: dicoms will be converted and
            % then deleted. Assumes all files that start with MR are
            % dicoms.
            %
            
            matlabbatch = [];
            files       = spm_select('FPListRec',destination,'^MR');            
            if ~isempty(files)
                fprintf('ConvertDicom:\nFound %i files...\n',size(files,1));
                
                matlabbatch{1}.spm.util.import.dicom.data             = cellstr(files);
                matlabbatch{1}.spm.util.import.dicom.root             = 'flat';
                matlabbatch{1}.spm.util.import.dicom.outdir           = {destination};
                matlabbatch{1}.spm.util.import.dicom.protfilter       = '.*';
                matlabbatch{1}.spm.util.import.dicom.convopts.format  = 'nii';
                matlabbatch{1}.spm.util.import.dicom.convopts.icedims = 0;
                               
                fprintf('Dicom conversion s#%i... (%s)\n',self.id,self.current_time);
                self.RunSPMJob(matlabbatch);
                fprintf('Finished... (%s)\n',datestr(now,'hh:mm:ss'));
                % delete dicom files
                fprintf('Deleting DICOM images in (%s)\n%s\n',self.current_time,destination);
                files = cellstr(files);
                delete(files{:});
                fprintf('Finished... (%s)\n',self.current_time);                
            else
                fprintf('No dicom files found for %i\n',self.id);
            end
        end        
        function [result]   = dicomserver_request(self)
            %will make a normal dicom request. use this to see the state of
            %folders
            results = [];
            if ~ismac & ~ispc
                fprintf('Making a dicom query, sometimes this might take long (so be patient)...(%s)\n',self.current_time);
                [status result]  = system(['/common/apps/bin/dicq --series --exam=' self.trio_session]);
                fprintf('This is what I found for you:\n');
            else
                fprintf('To use dicom query you have to use one of the institute''s linux boxes\n');
            end
            
        end
        function [paths]    = dicomserver_paths(self)
            paths = [];
            if ~ismac & ~ispc
                fprintf('Making a dicom query, sometimes this might take long (so be patient)...(%s)\n',self.current_time)
                [status paths]   = system(['/common/apps/bin/dicq -t --series --exam=' self.trio_session]);
                paths            = strsplit(paths,'\n');%split paths
            else
                fprintf('To use dicom query you have to use one of the institute''s linux boxes\n');
            end
        end
        function [data_path]= pathfinder(self,subject,run)
            %gets the path
            %Example: s.pathfinder(s.id,[]) => will return the path to
            %subject
            % empty [] above can be replaced with any phase number.
            data_path = self.path_project;
            for no = [subject run]                
                file_list        = dir(data_path);%next round of the forloop will update this
                i                = regexp({file_list(:).name},sprintf('[0,a-Z]%d$',no));%find all folders which starts with
                i                = find(cellfun(@(bla) ~isempty(bla), i  ));
                if ~isempty(i)
                    folder       = getfield(file_list(i),'name');
                    data_path    = sprintf('%s%s%s',data_path,filesep,folder);
                else
                    data_path    = [];
                    return
                end                
            end
            data_path(end+1)         = filesep;
        end
        function [out]      = dartel_templates(self,n)
            %returns the path to Nth Dartel template                                    
            out = fullfile(self.path_spm,'toolbox','cat12','templates_1.50mm',sprintf('Template_%i_IXI555_MNI152.nii',n) );
        end
        function              CreateFolderHierarchy(self)
            %Creates a folder hiearchy for a project. You must run this
            %first to create an hiearchy and fill this with data.
            for ns = 1:length(self.trio_sessions)
                for nr = 0:length(self.dicom2run)
                    for nf = 1:length(self.data_folders)                        
                        path2subject = sprintf('%s%ssub%03d%srun%03d%s%s',self.path_project,filesep,ns,filesep,nr,filesep,self.data_folders{nf});
                        if ~isempty(self.trio_sessions{ns})
                            a = fullfile(path2subject);
                            mkdir(a);
                        end
                    end
                end
            end
        end
        function t          = get.current_time(self)
            t = datestr(now,'hh:mm:ss');
        end
        function files      = collect_files(self,selector)
            %will collect all the files from all subjects that matches the
            %SELECTOR. Example selectors could be:
            %'run001/spm/model_03_chrf_0_0/s_w_beta_0001.nii'; 
            %
            % The selector string is simply appended to subjects' path. And
            % its existence is checked, in case of inexistenz method
            % stops.
            
            files = [];
            for ns = self.subject_indices                
                current = sprintf('%s/sub%03d/%s',self.path_project,ns,selector);
                if exist(current) ~= 0
                    files = [files ; current];
                else
                    cprintf([0 0 1],'Invalid Selector\n');
                    keyboard;%for sanity checks
                end
            end
        end
        function out        = path_atlas(self,varargin)
            %path to subjects native atlas, use VARARGIN to slice out a
            %given 3D volume.
            out = sprintf('%satlas/data.nii',self.path_project);
            if nargin > 1
                out = sprintf('%s,%d',out,varargin{1});
            end
        end
% % %         function out        = path_spmmat_SecondLevel_ANOVA(self,run,model,sk)
% % %             %returns the path to second level analysis for a given
% % %             %smoothening kernel.
% % %             
% % %             out = regexprep(self.path_spmmat(run,model),'sub...',sprintf('second_level_%02dmm',sk));
% % %             
% % %         end
        function [output]=RW_analysis(self,out)
            %
%             [out]  = self.getgroup_all_spacetime(3,0,0,0);
            [sy sx]  = GetSubplotNumber(size(out.d,4));%number of areas
            %%
            for n = 1:size(out.d,4)%run over areas
                bla       = squeeze(mean(out.d(:,:,:,n),3));%average across subjects
                bla       = demean(bla')';
                %slightly smooth over conditions, not time.
                 kernel   = make_gaussian1d(-2:2,1,2.2,0)
                 kernel   = kernel./sum(kernel(:));
                 bla      = Project.circconv2(bla,kernel);
                
                [rw]      = Project.RW_Fit(bla,Project.ucs_vector);
                %[rw]     = Project.Linear_Fit(bla);
                output(n) = rw;
                %         
                figure(1)
                subplot(sy,sx,n);
                R = rw.r;
                R = R.^2;
                imagesc(rw.learning_rates,rw.stds,R);
                xlabel('learning rates');
                ylabel('std');
                colorbar;
                hold on;                
                plot(rw.peak_lr,rw.peak_std,'r+');
                hold off;                
                title(out.name{n},'interpreter','none'); 
                drawnow;
                %%
                figure(2);
                subplot(sy,sx,n);                
                fit = reshape(zscore(Vectorize(rw.fit(self.ucs_vector == 0,:))),sum(self.ucs_vector==0),8);
                bla = reshape(zscore(Vectorize(bla(self.ucs_vector == 0,:))),sum(self.ucs_vector==0),8);
                imagesc([bla,fit]);
                hold on;
                plot([8.5 8.5],ylim,'r');
                hold off;
                title(out.name{n},'interpreter','none'); 
                colorbar;
            end                        
        end
        function [out]   = path_SecondLevel_mask(self,subject_group)
            %returns the path to the secondlevel mask to be used for second-level analysis.
            
            out = sprintf('%s%sw%s_mask_group_%02d.nii',self.path_project,'midlevel/secondlevel_mask/',self.normalization_method,subject_group);
            
        end
        
    end    
    methods %getters                
        function out             = getgroup_all_param(self,varargin)
            %
            out = self.getgroup_pmf_param;
            out = join(out,self.getgroup_rating_param);
            out = join(out,self.getgroup_facecircle_param);
            out = join(out,self.getgroup_detected_oddballs);
            out = join(out,self.getgroup_detected_face);                        
            out = join(out,self.getgroup_scr_param);
            %%
            if nargin > 1%if given take only the selected subjects
                if varargin{1} ~= 0;
                    ngroup          = varargin{1};                
                    i               = ismember(double(out.subject_id),self.get_selected_subjects(ngroup).list);
                    out             = out(i,:);
                end
            end            
        end
        function out             = getgroup_pmf_param(self)
            %collects the pmf parameters for all subjects in a table.
            target_name = sprintf('%smidlevel/%s.mat',self.path_project,'getgroup_pmf_param');
            if exist(target_name) == 0                
                out = [];
                for ns = self.subject_indices
                    s       = Subject(ns);
                    if ~isempty(s.pmf)
                        out = [out;[s.id s.pmf_param(:)' s.fit_pmf.LL']];
                    else
                        out = [out;[s.id NaN(1,size(out,2)-1)]];
                    end
                end
                out = array2table(out,'variablenames',{'subject_id' 'pmf_csp_alpha' 'pmf_csn_alpha' 'pmf_pooled_alpha' 'pmf_csp_beta' 'pmf_csn_beta' 'pmf_pooled_beta' 'pmf_csp_gamma' 'pmf_csn_gamma' 'pmf_pooled_gamma' 'pmf_csp_lamda'    'pmf_csn_lamda'    'pmf_pooled_lamda' 'pmf_csp_LL' 'pmf_csn_LL' 'pmf_pooled_LL' });
                save(target_name,'out');
            else
                load(target_name);
            end
        end
        function out             = getgroup_rating_param(self)            
            %collects the rating parameters for all subjects in a table.
            target_name = sprintf('%smidlevel/%s_fun_%i_borders_%d_pval_%d_zscore_%d.mat',self.path_project,'getgroup_rating_param',Project.selected_fitfun,Project.borders,Project.pval*1000,Project.scale_feartunings );
            if exist(target_name) == 0
                out = [];
                for ns = self.subject_indices%run across all the subjects
                    s   = Subject(ns);
                    out = [out;s.rating_param];
                end
                save(target_name,'out');
            else
                load(target_name);
            end
        end               
        function out             = getgroup_scr_param(self)
            %collects the scr parameters for all subjects in a table.
            target_name = sprintf('%smidlevel/%s_fun_%i_borders_%d_pval_%d_zscore_%d.mat',self.path_project,'getgroup_scr_param',Project.selected_fitfun,Project.borders,Project.pval*1000,Project.scale_feartunings );            
            if exist(target_name) == 0
                out = [];
                for ns = self.subject_indices%run across all the subjects
                    s   = Subject(ns,'scr');
                    out = [out;s.scr_param];
                end
                save(target_name,'out');
            else
                load(target_name);
            end
        end               
        function out             = getgroup_facecircle_param(self)
            %collects the facecircle parameters for all subjects in a table.                        
            target_name = sprintf('%smidlevel/%s_fun_%i_borders_%d_pval_%d_zscore_%d.mat',self.path_project,'getgroup_facecircle_param',Project.selected_fitfun,Project.borders,Project.pval*1000,Project.scale_feartunings );            
            if exist(target_name) == 0
                out = [];
                for ns = self.subject_indices
                    s   = Subject(ns);
                    out = [out;s.facecircle_param];
                end
                save(target_name,'out');
            else
                load(target_name);
            end
        end       
        function out             = getgroup_detected_oddballs(self)            
            target_name = sprintf('%smidlevel/%s.mat',self.path_project,'getgroup_detectedoddballs_param');
            if exist(target_name) == 0
                odd = [];
                for ns = self.subject_indices
                    s       = Subject(ns);
                    odd     = [odd ;[s.id sum(s.detected_oddballs)]];
                end
                out = array2table(odd,'variablenames',{'subject_id' 'detection_oddball'});
                save(target_name,'out');
            else
                load(target_name);
            end
        end
        function out             = getgroup_detected_face(self)
            target_name = sprintf('%smidlevel/%s.mat',self.path_project,'getgroup_detectedface_param');
            if exist(target_name) == 0
                face = [];
                for ns = self.subject_indices
                    s      = Subject(ns);
                    face   = [face ;[s.id s.detected_face]];
                end
                face = [face abs(face(:,2))];
                out = array2table(face,'variablenames',{'subject_id' 'detection_face' 'detection_absface'});
                save(target_name,'out');
            else
                load(target_name);
            end
        end
        function fixmat          = getgroup_facecircle_fixmat(self,subjects)
            %will collect all the fixmats for all subjects from the
            %SUBJECTS.
            
            for ns = subjects(:)';
                s = Subject(ns);
                if ns == subjects(1)
                    fixmat = s.get_facecircle_fixmat;
                else
                    dummy  = s.get_facecircle_fixmat;
                    for nf = fieldnames(dummy)'
                        fixmat.(nf{1}) = [fixmat.(nf{1}) dummy.(nf{1})];
                    end
                end
            end
        end
        function out             = getgroup_behavioral(self,datatype);
            %returns all DATATYPE data of all participants. DATATYPE =
            %'rating' for collecting the rating data.
            %% get the data
            dummy = [];
            for ns = self.subject_indices;
                if strcmp(datatype,'scr')
                    dummy  = vertcat(dummy ,Subject(ns,'scr').(datatype));
                else
                    dummy  = vertcat(dummy ,Subject(ns).(datatype));
                end
            end
            %% massage it to Tuning format
            R     = [];
            R.y   = vertcat(dummy(:).y_mean);
            R.y   = demean(R.y')';
            R.x   = repmat(dummy(1).x(1,:),size(R.y,1),1);
            R.ids = repmat([1:size(R.y,1)]',1,size(R.y,2));
            %% fit and output
            out               = Tuning(R);
            out.visualization = 0;
            out.gridsize      = 10;
            out.GroupFit(self.selected_fitfun);
        end        
        function out             = path_beta_group(self,nrun,model_num,prefix,varargin)
            %returns the path for beta images for the second level
            %analysis. it simply loads single subjects' beta images and
            %replaces the string sub0000 with second_level.           
            dummy     = self.path_beta(nrun,model_num,prefix,varargin{:});
            for n = 1:size(dummy,1)
                out(n,:) = strrep(dummy(n,:),sprintf('sub%03d',self.id),'second_level');
            end
        end        
        function out             = path_contrast_group(self,nrun,model_num,prefix,type)
            %returns the path for F,T images for the second level
            %analysis. it simply loads single subjects' images and
            %replaces the string sub0000 with second_level.
            
            dummy     = self.path_contrast(nrun,model_num,prefix,type);
            for n = 1:size(dummy,1)
                out(n,:) = strrep(dummy(n,:),sprintf('sub%03d',self.id),'second_level');
            end
        end        
        function [spacetime]     = getgroup_all_spacetime(self,ngroup,clean,zsc,bc)
            %returns condition x time matrices for NGROUP and smoothing kernel of 10.
            %GROUP is fed to get_selected_subjects;
                                    
            [spacetime1]     = self.getgroup_bold_spacetime(ngroup,clean,zsc,bc);           
            [spacetime2]     = self.getgroup_scr_spacetime(ngroup,clean,zsc,bc);
            %
            spacetime.d      = cat(4,spacetime1.d,spacetime2.d);
            spacetime.name   = [spacetime1.name spacetime2.name];                                                                                    
        end
        
        
        function [spacetime]          = getgroup_bold_spacetime_roi(self,ngroup,rois,tbin);
            %wrapper around the ROI object            
            %clean   = 1;
            list    = self.get_selected_subjects(ngroup,1).list;            
            %%
%             betas                                                 = reshape(1:715,65,11)';
%             betas(:,[Project.mbi_oddball Project.mbi_transition]) = [];
%             betas(4,self.ucs_vector == 1)                         = betas(9,self.ucs_vector == 1);
%             %            
%             betas(9:11,:)                                         = [];
            
            betas   = reshape(1:715,65,11);
            betas([Project.mbi_oddball Project.mbi_transition],:)   = [];                        
            betas(Project.ucs_vector == 1,:)                  = [];
            betas(:,9:end)                              = [];
            
            %% 
            sk = 10
            r = ROI('roi_based',rois,'chrf_0_0_mumfordian',0,betas(:)',self.get_selected_subjects(ngroup).list,sk);
            %
            data_ori = r.evoked_pattern;
            data_ori = reshape(data_ori,[size(data_ori,1) 47 8]);
            for vox = 1:size(data_ori,1)
                dummy             = squeeze(data_ori(vox,:,:));
                dummy             = Project.circconv2(dummy,[.5 1 .5]./2);
                data_ori(vox,:,:) = dummy;
            end
            %% binning         
%             timebins = reshape(5:46,7,6);            
%             c = 0;
%             for N = timebins;
%                 c = c+1;
%                 data(:,c,:) = squeeze(mean(data_ori(:,N,:),2));
%             end
            %%
            timebins = [zeros(4,tbin);BinningMatrix(43,tbin)];
            for nc = 1:size(data_ori,3)
                data(:,:,nc) = data_ori(:,:,nc)*timebins;
            end            
            
            %%
            spacetime.d      = data;
            spacetime.name   = r.name;
        end        
     
        function spacetime_rsa        = spacetime2RSA(self,spacetime,smooth)
        %given a space time matrix computes the RSA for each microblocks                
        %spacetime     is [VOXELS, MICROBLOCKS, CONDITIONS];
        %spacetime_RSA is [MICROBLOCKS, PAIRWISE CORRELATIONs];
            % slight smoothing over conditions
            if smooth ~= 0
                kernel = [.5  1 .5];
                kernel = kernel./sum(kernel);
                for vox = 1:size(spacetime.d,1)
                    dummy                = squeeze(spacetime.d(vox,:,:));
                    dummy                = Project.circconv2(dummy,kernel);
                    spacetime.d(vox,:,:) = dummy;
                end
            end
            %% get the similarity matrix for each mbi, same representation as the spacetime matrices
            for N = 1:size(spacetime.d,2)
                data                   = squeeze(spacetime.d(:,N,:));
                spacetime_rsa.d(N,:)   = pdist(data','correlation');
            end            
            spacetime_rsa.name = spacetime.name;
        end        
        
        function plot_spacetime_rsa(self,spacetime_rsa)
            %plots for a given area the spacetime profile next to its area
            % st     = s.getgroup_bold_spacetime_roi(1,33);
            % st_rsa = s.spacetime2RSA(st,1);
                        
            %%           
            colors       = GetFearGenColors;
            coeff        = self.RSA_Model(spacetime_rsa.d);
            tbins        = size(spacetime_rsa.d,1);
            [trow, tcol] = GetSubplotNumber(10+1);
            figure;
            c            = 0;
            for N = 1:size(spacetime_rsa.d,1);
                c    = c+1;
                % average over bins
                data = spacetime_rsa.d(N,:,:);
                
                subplot(trow, tcol,c);
                imagesc( CancelDiagonals(squareform_force(data),NaN));
                colorbar
                title(sprintf('time bin %02d',c));
                axis square;
                axis off;                
                %                
                drawnow;
            end
            
            subplot(trow,tcol,c+1);            
            bar(coeff.circ);
            
            subplot(trow,tcol,c+2);            
            C = coeff.ellips./repmat(sum(coeff.ellips,2),1,2);
            bar(C(:,1));           
            
            %%
            ndimen = 2;            
            c      = c+2;
            for N = 1:size(spacetime_rsa.d,1)
                c = c +1;
                subplot(trow,tcol,c);
                y=mdscale(spacetime_rsa.d(N,:),ndimen);
                for nface = 1:8;
                    plot(y(nface,1),y(nface,2),'.','color',colors(nface,:),'markersize',50);
                    hold on;
                    xlim([-1 1]);
                    ylim([-1 1]);
                end
                axis tight;                
                axis equal;
%                 axis square;                
            end
            %%
            

            
            
            supertitle(spacetime_rsa.name,1)
            drawnow;
        end
        
        
        
        
        
        
        
        
        
        function [spacetime]          = getgroup_bold_spacetime(self,ngroup,clean,zsc,bc)
            %spacetime  = getgroup_bold_spacetime(self,ngroup,clean)
            % GROUP is fed to get_selected_subjects.
            % CLEAN == 1 to discard UCS microblocks.
            %            
            %
            % see also getgroup_pupil_spacetime
                        
            sk      = self.selected_smoothing;                            
            list    = self.get_selected_subjects(ngroup,1).list;            
            % get coordinates
%             self.selected_ngroup = ngroup
            coors   = self.get_selected_coordinates(ngroup);
            % get beta indices to be read
            betas   = reshape(1:715,65,11)';
            betas   = betas(1:11,:);
            %% collect                     
            R       = ROI('voxel_based',coors ,'chrf_0_0_mumfordian',0,betas(:)',list,sk);
            R.name
            %% transform, rearrange etc.
            pattern = permute(reshape(permute(R.pattern,[2 3 1]),[11 65 size(R.pattern,3) size(R.pattern,1)]),[2 1 3 4]);size(pattern);
            name    = cellstr(R.name)';
            %% exclude voxels outside of the brain
            invalid                = R.name(:,1) == 'N';
            if sum(invalid) > 0
                pattern(:,:,:,invalid) = [];
                name(invalid)          = [];
                cprintf([1 0 0],'Removed %03d out of rois...\n',sum(invalid));
            end
            out = pattern;
            %% move UCS condition to the 4th column
            for ccc = [10 11]
                i            = find(out(:,ccc,1,1)~=0);
                out(i,4,:,:) = out(i,ccc,:,:);
            end
            out(:,9:end,:,:) = [];
            %% clean the bad microblocks with oddballs and transitions
            out = self.CleanMicroBlocks(out);
            %% clean further
            if clean % and now clean the UCS trials if wanted.
                out(self.ucs_vector == 1,:,:,:,:,:,:) = [];
            end
            %% output
            spacetime.d    = out;;
            spacetime.name = name;
            %% zscore nad baseline correction
            [spacetime.d]  = self.spacetime_preprocess(spacetime.d,zsc,bc);
        end                
        function [out,name]      = getgroup_pupil_spacetime(self,ngroup)
            % this needs to be ADAPTED as in BOLD and SCR
            %will load the group pupil data for the NGROUPth subjects.
            %
            % see also getgroup_bold_spacetime
            
            out = [];
            c = 0;
            for ns = self.get_selected_subjects(ngroup,1).list
                c = c +1;
                fprintf('Collecting subject %03d\n',ns);
                s            = Subject(ns,'pupil');
                out(:,:,c,1) = inpaint_nans(s.get_pupil_spacetime);
%                 out(:,:,c,1) = (s.get_pupil_spacetime);
            end
%             out  = nanmean(out,3);
            name{1} = 'pupil';
        end                
        function [spacetime]     = getgroup_scr_spacetime(self,ngroup,clean,zsc,bc)
            %will load the group pupil data for the NGROUPth subjects.
            %
            % see also getgroup_bold_spacetime, getgroup_pupil_spacetime
            %%
            out = [];
            c   = 0;
            for ns = self.get_selected_subjects(ngroup).list;                
                c            = c + 1;
                s            = Subject(ns);
                scr          = SCR(s);
                scr.run_ledalab;                
                dummy        = reshape(mean(scr.ledalab.y(150:300,:)),65,9);
                out(:,:,c,1) = dummy(:,1:8,:);
            end
            %% clean the bad microblocks with oddballs and transitions
            out = self.CleanMicroBlocks(out);
            %% clean further
            if clean % and now clean the UCS trials if wanted.
                out(self.ucs_vector == 1,:,:,:,:,:,:) = [];
            end
            %% output
            spacetime.d    = out;;
            spacetime.name = {'scr'};
            %% zscore nad baseline correction
            [spacetime.d]  = self.spacetime_preprocess(spacetime.d,zsc,bc);
            
            
        end                
        function  name           = get_atlasROIname(self,roi_index)
            %get_atlasROIname(self,roi_index)
            %
            %returns the name of the probabilistic atlas at ROI_INDEX along
            %the 4th dimension of the atlas data.
            cmd           = sprintf('sed "%dq;d" %s/data.txt',roi_index,fileparts(self.path_atlas));
            [~,name]      = system(cmd);
            name          = deblank(name);
        end
        function roi             = get_atlaslabel(self,XYZmm)
            %returns the label of the ROI at location XYZmm using the
            %Project's atlas.
            
            atlas_labels = regexprep(self.path_atlas,'nii','txt');
            roi.name     = {};
            roi.prob     = {};
            %
            V            = spm_vol(self.path_atlas);
            V            = V(63:end);%take only the bilateral ones.
            %get the probabilities at that point
            [p i]    = sort(-spm_get_data( V, V(1).mat\[XYZmm(:);1]));
            %black list some useless areas
            [~,a]      = system(sprintf('cat %s | grep Cerebral',atlas_labels));
            black_list = strsplit(a);
            %list the first 6 ROIs
            %             fprintf('Cursor located at (mm): %g %g %g\n', x,y,z);
            counter = 0;
            while counter <= 3
                counter               = counter + 1;
                %get the current ROI name
                current_name = self.get_atlasROIname(i(counter)+62);%the first 62 are bilateral rois, not useful.
                %include if the probability is bigger than zero and also if the current roi is not
                %one of the stupid ROI names, e.g. cerebral cortex or so...
                if -p(counter) > 0 & isempty(cell2mat( regexp(current_name,black_list)))
                    %isempty == 1 when there is no match, which is good
                    %
                    roi.name     = [roi.name current_name];
                    roi.prob     = [roi.prob -p(counter)];
                    %fprintf('ROI: %d percent chance for %s.' , roi.prob{end}, roi.name{end}(1:end-1));
                    %fprintf('\n');
                end
            end
            %if at the end of the loop we are still poor, we say it
            if isempty(roi.prob)
                roi.name{1} = 'NotFound';
                roi.prob{1} = NaN;
            end
            
            %fprintf('\n\n');
        end
        function XYZmm           = get_XYZmmNormalized(self,mask_id)
            %Will return XYZ coordinates from ROI specified by MASK_INDEX
            %thresholded by the default value. XYZ values are in world
            %space, so they will need to be brought to the voxel space of
            %the EPIs.
            mask_handle = spm_vol(self.path_atlas(mask_id));%read the mask
            mask_ind    = spm_read_vols(mask_handle) > self.atlas2mask_threshold;%threshold it
            [X Y Z]     = ind2sub(mask_handle.dim,find(mask_ind));%get voxel indices
            XYZ         = [X Y Z ones(sum(mask_ind(:)),1)]';%this is in hr's voxels space.
            XYZmm       = mask_handle.mat*XYZ;%this is world space.
            XYZmm       = unique(XYZmm','rows')';%remove repetititons.
        end
        function XYZvox          = get_mm2vox(self,XYZmm,vh)
            %brings points in the world space XYZmm to voxel space XYZvox
            %of the image in VH.
            XYZvox  = vh.mat\XYZmm;
            XYZvox  = unique(XYZvox','rows')';%remove repetitions
            XYZvox  = (XYZvox);%remove decimals as these are going to be matlab indices.
            %used to round the voxel coordinates but I think it is better
            %to keep them decimal as spm_get_data has no problem with that,
            %mainly it is to be more precise.
        end
        function D               = getgroup_data(self,file,mask_id)
            %will read the data specified in FILE
            %FILE is the absolute path to a 3/4D .nii file. Important point
            %is that the file should be in the normalized space, as MASK_ID
            %refers to a normalized atlas.
            %
            %MASK_ID is used to select voxels.
            %
            vh      = spm_vol(file);
            if spm_check_orientations(vh)
                XYZmm   = self.get_XYZmmNormalized(mask_id);
                XYZvox  = self.get_mm2vox(XYZmm,vh(1));%in EPI voxel space.
                D       = spm_get_data(vh,XYZvox);
            else
                fprintf('The data in\n %s\n doesn''t have same orientations...',file);
            end
        end
        function sub             = get_selected_subjects(self,criteria,inversion)
            %sub        = get_selected_subjects(self,criteria,inversion)
            %
            %will select subjects based on different CRITERIA. Use
            %INVERSION to invert the selection, i.e. use the unselected
            %subjects. LIST is the indices of subjects, NAME is the name of
            %the group, used to write folder names, identifying a given
            %group of subjects. So dont get confused, when INVERSION is 1,
            %you get the selected subjects (generaly performing better).
            cprintf([0 1 0],'Selecting subjects, must loop over once...\n');
            if nargin == 2
                inversion = 1;%will select good subjects
            end
            borders = 1000;
            funname{3} = 'Gau';
            funname{8} = 'vM';
            if criteria == 0
                sub.name = '00_all';
                sub.list = self.subject_indices(:);
                
            elseif     criteria == 1
                %The data must be  described with a Gaussian curve better
                %than null model +
                %the amplitude must be positive +
                %depending on the fitfun value, this will select either a
                %significant vM or Gaussian fits.
                
                sub.name   = ['Rating_' funname{self.selected_fitfun} '_1'];
                %
                t          = self.getgroup_rating_param;
                select     = t.rating_FearTuning == 1;%load the ratings of all subjects                                
                sub.list   = t.subject_id(select);%subject indices.
                %
            elseif     criteria == 11
                %The data must be  described with a Gaussian curve better
                %than null model                
                %depending on the fitfun value, this will select either a
                %significant vM or Gaussian fits.
                
                sub.name = ['Rating_' funname{self.selected_fitfun} '_0'];
                %
                t          = self.getgroup_rating_param;
                select     = t.rating_FearTuning == 0;%load the ratings of all subjects                                
                sub.list   = t.subject_id(select);%subject indices.
                %
            elseif criteria == 2
                %
                sub.name = 'detectors (<=45\circ) ';
                out      = self.getgroup_detected_face;
                select   = abs(out.detection_face) <= 45;
                select   = select==inversion;
                sub.list = out.subject_id(select);
                
            elseif criteria == 3                
                %same as rating tuning, but with saliency data.
                sub.name = ['Saliency_' funname{self.selected_fitfun} '_1'];                
                %
                t          = self.getgroup_facecircle_param;
                select     = t.facecircle_FearTuning == 1;%load the ratings of all subjects                                
                sub.list   = t.subject_id(select);%subject indices.
                %
            elseif criteria == 33
                %same as rating tuning, but with saliency data.
                sub.name = ['Saliency_' funname{self.selected_fitfun} '_0'];
                %
                t          = self.getgroup_facecircle_param;
                select     = t.facecircle_FearTuning == 0;%load the ratings of all subjects                                
                sub.list   = t.subject_id(select);%subject indices.
                %
                
            elseif criteria == 4
                
                sub.name    = '04_perception';
                out     = self.getgroup_pmf_param;%all threshoild values
                m       = nanmedian(out.pmf_pooled_alpha);
                select  = out.pmf_pooled_alpha <= m;%subjects with sharp pmf
                select  = select==1;
                sub.list= out.subject_id(select);             
            end
            %
            sub.list = sub.list(:)';
            %            
        end        
        function [fit,extract]   = get_stanfit(self,area)
            
            group = 3;
            sk    = 6;
            want_baseline = 1;
            want_zscore   = 1;
            filename      = sprintf('%smidlevel/get_stanfit_area_%d_zscore_%d_baseline_%d_sk_%02d_group_%02d.mat',self.path_project,area,want_zscore,want_baseline,sk,group);
            if exist(filename) == 0
                %% load the raw single trial mumfordian data.
                [out_scr,  name]      = self.getgroup_scr_spacetime_full(group);
                [out_bold, name_bold] = self.getgroup_bold_spacetime_full(group,sk);
                out                   = cat(4,out_bold,out_scr);
                out                   = permute(out,[2 1 3 4]);%[face microblock subject area]
                %% for each subject separately make a global zscore transformation + baseline correction.
                dummy3        = [];
                for modality = 1:size(out,4)
                    dummy2 = [];
                    for nsubject = 1:size(out,3)
                        dummy    = out(:,:,nsubject,modality);
                        if want_zscore
                            dummy    = reshape(zscore(dummy(:)),size(dummy,1),size(dummy,2));
                        end
                        if want_baseline
                            dummy    = dummy - repmat(mean(dummy(:,1:4),2),[1 size(dummy,2)]);
                        end
                        dummy2   = cat(3,dummy2,dummy);
                    end
                    dummy3 = cat(4,dummy3,dummy2);
                end
                out              = permute(out,[1 3 2 4]);
                out              = dummy3(:,:,:,area);
                %% organize the data for stan: each microblock is a modality
                tsub             = size(out,3);
                tmicroblock      = size(out,2);
                modality =[];c=0;
                for n = 1:tmicroblock
                    c        = c+1;
                    modality = [modality repmat(c,1,tsub)];
                end
                out              = reshape(out,[8 tmicroblock*tsub]);
                %% store it
                data.y           = out;%[8xN]
                data.x           = deg2rad([-135:45:180]');
                data.X           = length(data.x);
                data.T           = size(out,2);
                data.m           = modality;
                data.M           = length(unique(modality));
                %% give sensible initial values.
                init.sigma_amp   = zeros(1,data.M)+1;
                init.sigma_offset=zeros(1,data.M)+1;
                init.sigma_kappa =zeros(1,data.M)+1;
                init.sigma_y     = zeros(1,data.M)+1;
                init.mu_amp      = zeros(1,data.M);
                init.mu_offset   = zeros(1,data.M);
                init.mu_kappa    = zeros(1,data.M)+.01;
                %
                init.amp            = zeros(1,data.T);
                init.kappa          = zeros(1,data.T)+0.01;%very wide
                init.offset         = zeros(1,data.T);
                %
                %% some path business
                addpath('/home/onat/Documents/Code/C++/cmdstan-2.12.0/');
                addpath('/home/onat/Documents/Code/Matlab/MatlabProcessManager/');
                addpath('/home/onat/Documents/Code/Matlab/MatlabStan/')
                
                cd /mnt/data/project_fearamy/FitVonMises;
                !rm FitVonMises FitVonMises.hpp FitVonMises.cpp  output-* temp.*;
                fit       = stan('file','FitVonMises.stan','data',data,'verbose',true,'iter',400,'init',init);
                keyboard
                extract   = fit.extract;
                save(filename,'fit','extract');
            else
                load(filename)
            end
        end
        function [pmod]          = get_pmodmat(self,model)
            %returns the pmod values used for different models, the idea
            %here is to use this matrix and the fitted coefficients to
            %reconstruct the timexcondition panels.
            %
            if ismember(model,[3 4 5])
                kappa   = .1;
                %create a weight vector for the derivative.
                res     = 8;
                x2      = [0:(res-1)]*(360/res)-135;
                x2      = [x2 - (360/res/2) x2(end)+(360/res/2)];
                deriv   = -abs(diff(Tuning.VonMises(x2,1,kappa,0,0)));
                %this
                mbi_id  = Vectorize(repmat(1:65,8,1));
                stim_id = Vectorize(repmat([-135:45:180]',1,65));
                pmod    = NaN(length(stim_id),6);
                for ntrial = 1:length(stim_id)
                    if stim_id(ntrial) < 1000
                        pmod(ntrial,1) = 1;%constant term
                        pmod(ntrial,2) = mbi_id(ntrial);%onsets
                        pmod(ntrial,3) = Tuning.VonMises( stim_id(ntrial),1,kappa,0,0);%amp
                        pmod(ntrial,5) = deriv(mod(stim_id(ntrial)./45+4-1,8)+1);%dsigma
                    end
                end
                %
                pmod(:,2:3)      = nandemean(pmod(:,2:3));%mean correct
                pmod(:,7)        = nandemean(pmod(:,2).^2);%poly expansion time;
                
                pmod(:,5)        = nandemean(pmod(:,5));%dsigma
                pmod(:,4)        = pmod(:,2).*pmod(:,3);%time x amp
                pmod(:,6)        = pmod(:,2).*pmod(:,5);%time x dsigma
                pmod(:,8)        = pmod(:,7).*pmod(:,3);%time2 x amp
                pmod(:,9)        = pmod(:,7).*pmod(:,5);%time2 x dsigma
                pmod(:,2:end)    = nanzscore(pmod(:,2:end));
                
                if model == 3
                    pmod = pmod(:,1:4);
                elseif model == 4
                    pmod = pmod(:,1:6);
                elseif model == 5
                    pmod = pmod(:,[1 2 3 4 7 8 5 6 9]);
                end
            elseif ismember(model,[33 32 31 44 43 42])
                
                base_kappa([33 44]) = 2;
                base_kappa([32 43]) = 1;
                base_kappa([31 42]) = .1;
                base_kappa = base_kappa(model);
                X          = (linspace(-135,180,8));
                deriv      = zscore(Tuning.VonMises(X,1,base_kappa+.05,0,0)-Tuning.VonMises(X,1,base_kappa-.05,0,0));
                deriv      = deriv - max(deriv);
                vM         = zscore(Tuning.VonMises(X,1,base_kappa,0,0));                
                %%
                mbi_id  = Vectorize(repmat(1:65,8,1));
                stim_id = Vectorize(repmat([-135:45:180]',1,65));
                pmod    = NaN(length(stim_id),6);
                for ntrial = 1:length(stim_id)
                    if stim_id(ntrial) < 1000
                        pmod(ntrial,1) = 1;%constant term
                        pmod(ntrial,2) = mbi_id(ntrial);%time
                        
                        cond_id        = mod(stim_id(ntrial)./45+4-1,8)+1;
                        pmod(ntrial,3) = vM(cond_id);
                        pmod(ntrial,5) = deriv(cond_id);%sigma
                    end
                end
                %                                
                pmod(:,2:3)      = nanzscore(pmod(:,2:3));%zscore time and amplitude.
                pmod(:,4)        = pmod(:,2).*pmod(:,3);%time x amp
                pmod(:,4)        = nanzscore(pmod(:,4));%zscore also the interaction
                pmod(:,6)        = pmod(:,2).*pmod(:,5);%time x dsigma (using the same timevector)
                
                if ismember(model,[33 32 31])
                    pmod = pmod(:,1:4);
                elseif ismember(model,[44 43 42])
                    pmod = pmod(:,1:6);
                end
            end
        end
        function [coors]         = get_SecondLevel_ANOVA_coordinates(self,ngroup,run,models,beta_image_index,sk,covariate_id,nC);            
            %returns the coordiantes displayed on spm figure;
            %%            
            SPM         = self.SecondLevel_ANOVA(ngroup,run,models,beta_image_index,sk,covariate_id);
            xSPM        = struct('swd', SPM.swd,'title',SPM.xCon(nC).name,'Ic',nC,'n',[],'Im',[],'pm',[],'Ex',[],'u',.001,'k',0,'thresDesc','none');
            [SPM, xSPM] = spm_getSPM(xSPM);
            t           = spm_list('table',xSPM);
            coors       = [t.dat{:,end};ones(1,size(t.dat,1))];
        end
        function [st  names]     = get_SecondLevel_ANOVA_fit(self,ngroup,sk);
            model     = 5;
            reg_i     = 1:9;
            %returns the fitted space-time plot            
            coors     = self.get_selected_coordinates;
            cprintf([1 0 0],'returning the first 10...\n');
%             coors     = coors(:,1:10);
            tcoor     = size(coors,2);
            r         = ROI('voxel_based',coors,'chrf_0_0',model,reg_i,self.get_selected_subjects(ngroup).list,sk);
            betas     = r.evoked_pattern';
            if model < 8
                pmod      = self.get_pmodmat(model);
            elseif model == 8
                
                pmod      = self.get_chebyshev(5,3);
                pmod      = reshape(pmod,[65*8 length(reg_i)]);
                
            elseif model == 88
                
                pmod      = self.get_chebyshev(5,6);
                pmod      = reshape(pmod,[65*8 length(reg_i)]);
                
            elseif model == 9
                
                pmod      = self.get_zernike;
                pmod      = reshape(pmod,[65*8 21]);
                
            end
            st        = reshape(pmod*betas,8,65,tcoor);
            st        = permute(st,[2 1 3]);
            names     = cellstr(r.name);
        end
        function [pmodmat names] = get_chebyshev(self,face_order,time_order)
            %Chebyshev polynomials
            %%
            x      = linspace(-1,1,65)';
            n2     = time_order;
            m      = length(x);
            %Generate the z variable as a mapping of your x data range into the interval [-1,1]            
            z      = ((x-min(x))-(max(x)-x))/(max(x)-min(x));            
            A(:,1) = ones(m,1);
            if n2 > 1
                A(:,2) = z;
            end
            if n2 > 2
                for k = 3:n2+1
                    A(:,k) = 2*z.*A(:,k-1) - A(:,k-2);  %% recurrence relation
                end
            end
            %%
            x = linspace(-1,1,8)';
            n = face_order;
            m = length(x);
            %
            %Generate the z variable as a mapping of your x data range into the interval [-1,1]
            
            z = ((x-min(x))-(max(x)-x))/(max(x)-min(x));
            
            B(:,1) = ones(m,1);
            if n > 1
                B(:,2) = z;
            end
            if n > 2
                for k = 3:n+1
                    B(:,k) = 2*z.*B(:,k-1) - B(:,k-2);  %% recurrence relation
                end
            end
            B = B(:,1:2:end);
            %%
            figure;clf;
            c = 0;
            pmodmat = [];degrees= [];
            for i = 1:size(B,2);%face
                for j = 1:size(A,2);%time
                    c = c+1
                    Y = [B(:,i)*A(:,j)'];
                    subplot(size(B,2),size(A,2),c);
                    %imagesc(Y);
                    polarplot3d(Y','plottype','surfn','axislocation','off');
                    view(0,90);axis square;axis tight;axis off;
                    %
                    pmodmat = cat(3,pmodmat,Y);
                    degrees = [degrees [i;j]];                    
                    names{c} = sprintf('time:%02d, face:%02d',j,i);
                end
            end
            
        end        
        function [pmod names]    = get_zernike(self)
            %Zernike polynomials
            %%
            total = 21;
            [y x] = meshgrid(linspace(0,1,65),deg2rad(0:45:(360-45)));
            c     = 0;
            clf;
            pmod = [];
            for n = 0:1:5;
                for m = -n:2:n
                    c=c+1;
                    subplot(3,7,c);
                    pmod(:,:,c) = reshape(zernfun(n,m,y(:),x(:)),size(x,1),size(x,2))';
                    %polarplot3d(pmod(:,:,c),'interpmethod','nearest');
                    %view(0,90);axis square;axis tight;axis off;
                    names{c} = sprintf('N:%02d, M:%02d',n,m);
                    title(names{c});
                    drawnow;                   
                end
            end            
            
        end        
        function [coors,name]    = get_selected_coordinates(self,ngroup)
            %this method simply returns the coordinates of voxels that are
            %selected. This is not supposed to change very often and stay
            %as it is once fixed.
                        
% % %             model                    = self.selected_model
% % %             betas                    = self.selected_betas
% % %             ngroup                   = self.selected_ngroup
% % %             sk                       = self.selected_smoothing
% % %             %
% % %             xSPM                     = self.SecondLevel_ANOVA(ngroup,1,model,betas,sk,[]);
% % %             xSPM                     = struct('swd', xSPM.swd,'title','eoi','Ic',2,'n',1,'Im',[],'pm',[],'Ex',[],'u',.001,'k',0,'thresDesc','none');
% % %             %replace 'none' to make FWE corrections.
% % %             [SPM xSPM]               = spm_getSPM(xSPM);%now get the tresholded data, this will fill in the xSPM struct with lots of information.
% % %             t                        = spm_list('table',xSPM);
% % %             coors                    = [t.dat{:,end};ones(1,size(t.dat,1))];                        
            if ngroup == 3;%verbal + behavioral group
                coors = [26  -2 -28 1;
                         32  22 -10 1;
                         44  18 -13 1]';
                
%                 coors = [28  -4 -28 1; 
%                          28  22  -8 1; 
%                          -27 24  -7 1; 
%                          10  28  -14 1; 
%                          14  32   0  1;
%                          40  32  -14 1; 
%                          36 -44  -22 1; 
%                         -34 -24  -22 1]';
            elseif ngroup  == 1%verbal group;
                coors = [32  22 -10 1;
                         44  18 -13 1]';
                
%                 coors = [-9   4   4 1; 
%                          10   6  10 1; 
%                          30  22 -10 1; 
%                         -28  20  -7 1; 
%                          56 -19 -13 1]';
            end
            
            name = [];invalid=[];
            for n = 1:size(coors,2)
                dummy = self.get_atlaslabel(coors(1:3,n));                
                if strcmpi(dummy.name{1},'NotFound')
                    invalid = [invalid n];
                else
                    name  = strvcat(name,dummy.name{1});
                end
            end
           coors(:,invalid) =[]; 
        end
        function ucs             = get.ucs_vector(self)
            %returns a logical vector with ones where there is a UCS AFTER
            %CLEANING FOR ODDBALL and TRANSITION MICROBLOCKS.
            ucs                                                 = zeros(1,65);
            ucs(Project.mbi_ucs)                                = 1;
            ucs([Project.mbi_oddball Project.mbi_transition])   = [];
        end
        function ucs             = get.ucs_vector_notcleaned(self)
            %returns a logical vector with ones where there is a UCS AFTER
            %CLEANING FOR ODDBALL and TRANSITION MICROBLOCKS.
            ucs                                                 = zeros(1,65);
            ucs(Project.mbi_ucs)                                = 1;            
        end
        function [out2]          = spacetime2correlation(self,out)
            %computes correlation between spacetime pixels and
            %end-experiment behavioral measures.
                param     = self.getgroup_all_param(3);
                data      = double([param.pmf_pooled_alpha param.rating_amp param.rating_LL param.facecircle_amp param.facecircle_LL param.detection_absface]);
                out2.name = {'pmf_pooled' 'rating_amp' 'rating_LL' 'facecircle_amp' 'facecircle_LL' 'detection'};
                %%
                for nparam = 1:size(data,2)
                    nparam
                    for area = 1:size(out.d,4)
                    kernel   = make_gaussian2D(11,7,3,1.5,6,4);
                    kernel   = kernel./sum(kernel(:));
                    for ns = 1:size(out.d,3)
                        dummy(:,:,ns,area)    = Project.circconv2( (mean(out.d(:,:,ns,area),3)),kernel);
                    end
                        for t= 1:size(out.d,1)
                            for m = 1:size(out.d,2)
                                
                                out2.r(t,m,1,area,nparam) = corr(squeeze(dummy(t,m,:,area)),data(:,nparam),'type','pearson');
                            end
                        end
                    end
                end
        end           
        function [count labels]  = get_subject_overlap(self)
            %computes a count matrix for different subject selection
            %method.s            
            
            count  = [];
            labels = {};            
            for ns = [1 2 3 4]
                count  = [count ismember(self.subject_indices(:), self.get_selected_subjects(ns).list(:))];
                labels = [labels self.get_selected_subjects(ns).name];
            end            
            %add the oddball
            count  = [count self.getgroup_detected_oddballs.detection_oddball == 2];            
            labels = [labels '100% oddball'];
            %%
            figure;
            ImageWithText(count'*count,count'*count);
            fs = 10;
            set(gca,'fontsize',fs,'xtick',1:length(labels),'ytick',1:length(labels),'XTickLabelRotation',45,'xticklabels',labels,'fontsize',fs,'YTickLabelRotation',45,'yticklabels',labels,'TickLabelInterpreter','none')
        end        
        function [learning_rate,t] = GetRWIntervals(self)
            %we will compute here the interval to use for testing the
            %RW-based time effect.            
            step          = .01;
            learning_rate = [0.001 0.001];%initial learning rate.
            rw_time0      = rescorlawagner( self.ucs_vector_notcleaned , learning_rate(1) ,Inf, 0);%start time-vector.
            upper         = 0.9;
            t             = rw_time0;
            %%
            while learning_rate(end) < upper         
                %%
                sprintf('Current learning rate is %s \n',mat2str(learning_rate(end)))
                ok = 1                
                while ok
                    learning_rate(end) = learning_rate(end) + .0001%keep updating learning rate until                    
                    rw_time = rescorlawagner( self.ucs_vector_notcleaned , learning_rate(end) ,Inf, 0);
                    if (1-corr2(rw_time,rw_time0)) >= step%correlation decreases by STEP then
                        ok                   = 0;
                        rw_time0             = rw_time;%keep this one as the baseline
                        learning_rate(end+1) = learning_rate(end);%and store the learning rate
                        t                    = [t;rw_time0];
                    end
                    if learning_rate(end) >= upper
                        break
                    end
                end
            end
        end
        function getgroup_firstlevel_RW(self,subjects)
            
            learning_rates = [0 self.GetRWIntervals];            
            sublist        = self.get_selected_subjects(0).list(subjects);
            for ns = sublist
                s=Subject(ns);
                parfor rw = 1:length(learning_rates);
                    modelnum = round(10000+10000*learning_rates(rw));
                    s.analysis_spm_firstlevel(1,modelnum);
                end
            end
        end
        function                   getgroup_meanepi(self,criteria)
            %computes a mean EPI image based on subject pool defined by
            %CRITERIA
            filename = sprintf('%smidlevel/%s/%02d.nii',self.path_project,'getgroup_meanEPI',criteria)
            if exist(filename) == 0 | 0
                if exist(fileparts(filename)) == 0
                    mkdir(fileparts(filename))
                end
                p = [];
                for ns = self.get_selected_subjects(criteria).list
                    s = Subject(ns);
                    %                     s.VolumeNormalize(s.path_meanepi);
                    F = regexprep(s.path_meanepi,'meandata.nii','wCAT_meandata.nii');
                    p = [ p ; F];
                end
                D = spm_vol(p);
                V = mean(spm_read_vols(D),4);
                dummy = D(1);
                dummy.fname = filename
                spm_write_vol(dummy,V);
                
            else
                load(filename)
            end
        end
        function T = extract_coordinates(self,SPM,xSPM,varargin)
            %given an SPM and xSPM, we exctract coordinates and gaussian
            %amplitude parameter for either all the coordinates listed on
            %the table or a selected set of them as specified in VARARGIN.            
                        
            filename = sprintf('%smidlevel/SPM_table_Coordinates_%s.mat',self.path_project,DataHash([getByteStreamFromArray(xSPM) getByteStreamFromArray(SPM) getByteStreamFromArray(varargin) ]));            
            if ~exist(filename)
                t           = spm_list('table',xSPM);
                if nargin == 3
                    coors       = [t.dat{:,end}];
                else
                    coors       = [t.dat{varargin{1},end}];
                end
                %%
                name = {};
                D    = [];
                c=0;
                for coor = coors
                    c = c+1;
                    dummy               = self.get_atlaslabel(coor(:));
                    %                 name                = [name sprintf('%03d',c)]%regexprep(regexprep([dummy.name{1}(6:end) '_' randsample('abcdefghi',1)],'\.',''),'_','')]
                    tsubject            = max(SPM.xX.I(:,1));
                    treg                = max(SPM.xX.I(:,2));
                    XYZvox              = self.get_mm2vox([coor(:) ;1],SPM.xCon(xSPM.Ic).Vspm);
                    data                = reshape(spm_get_data([SPM.xY.VY],XYZvox(:)),tsubject,treg);
                    D                   = [D data(:,3)];
                end
                %
                T = array2table(D);
                save(filename,'T')
            else
                load(filename);
            end
        end
        end
    methods         
        function out                        = SecondLevel_Mask(self,subject_group);
            %constructs a second-level mask based on normalized mask images
            %of for a specific subject pool, returns the path if already
            %computed. Assumes normalized first-level masks already exists.
            
            filename         = self.path_SecondLevel_mask(subject_group);
            path_average_hr  = sprintf('%smidlevel/run000/mrt/w_ss_data.nii',self.path_project);
            %
            force = 1;
            if exist(filename) == 0 || force
                %%
                fprintf('Second Level mask not yet computed will do it now...\n');
                fprintf('Loading all files...\n');
                files = [];
                for ns = self.get_selected_subjects(subject_group).list
                    s = Subject(ns);
                    files = [files;cellstr(s.path_normalized_mask(1,3))];
                end
                %%
                vh = spm_vol(files);
                vh = [vh{:}];
                V  = spm_read_vols(vh);
%                 V  = V > .5;
                V  = sum(V,4) >= (size(files,1));%take voxels present on all participants;
                %% multiply this with the binarized mean skull-stripped image to remove out of brain voxels
                %first get the skull mask using magic wand
                H = spm_vol(path_average_hr);
                vH = spm_read_vols(H);
                M = zeros(size(vH));
                for nslice = 1:size(vH,3)
                    M(:,:,nslice) = ~logical(magicwand(repmat(vH(:,:,nslice),[1 1 3]),1,1,5));
                end
                %%
                V = V.*M;
                %%
                dummy       = vh(1);
                dummy.fname = filename;
                spm_write_vol(dummy,V);
                out = filename;
            else
                fprintf('Second Level mask has been already computed, here is the path...\n')
                out = filename;
            end                                    
        end
        function                              VolumeGroupAverage(self,selector)
            %Averages all IMAGES across all subjects. This can only be done
            %on normalized images. The result will be saved to the
            %project/midlevel/. The string SELECTOR is appended to the
            %folder RUN.             
            %
            %For example to take avarage skullstripped image use: RUN = 0,
            %SELECTOR = 'mrt/w_ss_data.nii' (which is the normalized skullstripped
            %image). This method will go through all subjects and compute an average skull stripped image.
                        
            files       = self.collect_files(selector);            
            v           = spm_vol(files);%volume handles
            V           = mean((spm_read_vols(v)).^2,4);%data
            target_path = regexprep(files(1,:),'sub[0-9][0-9][0-9]','midlevel');%target filename
            dummy       = v(1);
            dummy.fname = target_path;
            mkdir(fileparts(target_path));
            spm_write_vol(dummy,V);
        end   
        function                              VolumeSmooth(self,files)
            %will smooth the files by the factor defined as Project
            %property.
            for sk = self.smoothing_factor
                matlabbatch{1}.spm.spatial.smooth.data   = cellstr(files);
                matlabbatch{1}.spm.spatial.smooth.fwhm   = repmat(sk,[1 3]);
                matlabbatch{1}.spm.spatial.smooth.dtype  = 0;
                matlabbatch{1}.spm.spatial.smooth.im     = 0;
                matlabbatch{1}.spm.spatial.smooth.prefix = sprintf('s%02d_',sk);
                spm_jobman('run', matlabbatch);
            end
        end         
        function [SPM]                      = SecondLevel_ANOVA(self,ngroup,run,models,beta_image_index,sk,covariate_id)
            %%
            %[SPM]     = SecondLevel_ANOVA(self,ngroup,run,models,beta_image_index,sk,covariate_id)
            %
            %
            % This method runs a second level analysis for a model defined
            % in MODELS using beta images indexed in BETA_IMAGE_INDEX. The
            % same model can be ran at different smoothening levels (SK) as well
            % as for different subject groups (NGROUP, see
            % self.get_selected_subjects). If MODELS is a vector then
            % multiple first level analyses are combined into one
            % second-level.
            %
            % Covariate_id = 0 means no covariate
            %
            % Results are saved at the project root. xSPM structure is also
            % saved in the analysis SPM dir. If this file is present, it is
            % directly loaded, so the second level analysis is not reran.
            %
            % Example:
            % for sk=0:10;for ngroup = 0:4;s.SecondLevel_ANOVA(ngroup,1,3,1:4,sk,0);end;end
            %
            % Monkey business: if you add covariates change the folder name
            % aswell.            

            if length(ngroup) == 1
                ngroup(2) = 1;
            end
            
            covariate_id_name=[];
            for C = covariate_id            
                covariate_id_name                                            = [covariate_id_name C{1}];
            end
            %% depending on subject group and smoothening, generate a directory name for this spm analysis.
            subjects   = self.get_selected_subjects(ngroup(1),ngroup(2));
            spm_dir    = regexprep(self.dir_spmmat(run,models(1)),'sub...','second_level');%convert to second-level path, replace the sub... to second-level.
            spm_dir    = sprintf('%scov_id_%s/%02dmm/fitfun_%02d/group_%s/normalization_%s/',spm_dir,covariate_id_name,sk,self.selected_fitfun,subjects.name,self.normalization_method);
            spm_path   = sprintf('%sSPM.mat',spm_dir);
            %% if multiple models are needed to be analized in one single second-level anaylsis change the spmdir to reflect this
            if length(models)>1
                folder      = sprintf('%d+',models([1 end]));
                folder(end) = [];
                spm_dir     = regexprep(spm_dir,mat2str(models(1)),folder);%I shortened the folder name not to exceed the path length limit
            end            
            %%
            if 1%exist(spm_path) == 0;
                %% create path to beta images;                                
                beta_files2= [];
                for ns = subjects.list(:)'                
                    beta_files = [];      
                        for model = models(:)'                        
                        s          = Subject(ns);
                        %store all the beta_images in a 3D array
                        beta_files = cat(3,beta_files,s.path_beta(run,model,sprintf('s%02d_w%s_',sk,s.normalization_method),beta_image_index)');%2nd level only makes sense with smoothened and normalized images, thus prefix s_w_
                    end
                    beta_files2 = cat(4,beta_files2,beta_files);
                end     
                beta_files = beta_files2;%[path,betas,models,subjects]
                %% integrate them to the matlabbatch
                c = 0;                
                for nmodel = 1:size(beta_files,3)
                    for ind = 1:size(beta_files,2)
                    %take single beta_images across all subjects and store them
                    %in a cell
                    c                                                                  = c +1;
                    files                                                              = squeeze(beta_files(:,ind,nmodel,:))';
                    matlabbatch{1}.spm.stats.factorial_design.des.anova.icell(c).scans = cellstr(files);
                    end
                end                                
                %% 
                matlabbatch{1}.spm.stats.factorial_design.dir                    = cellstr(spm_dir);
                matlabbatch{1}.spm.stats.factorial_design.des.anova.dept         = 0;
                matlabbatch{1}.spm.stats.factorial_design.des.anova.variance     = 1;
                matlabbatch{1}.spm.stats.factorial_design.des.anova.gmsca        = 0;
                matlabbatch{1}.spm.stats.factorial_design.des.anova.ancova       = 0;                
                matlabbatch{1}.spm.stats.factorial_design.cov                    = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
                matlabbatch{1}.spm.stats.factorial_design.multi_cov              = struct('files', {}, 'iCFI', {}, 'iCC', {});
                %%
                %overwrite with the covariates if entered                
                if ~isempty(covariate_id)
                    out                                                          = self.getgroup_pmf_param;
                    out                                                          = join(out,self.getgroup_rating_param);
                    out                                                          = join(out,self.getgroup_facecircle_param);
                    out                                                          = out(ismember(out.subject_id,subjects.list),:);
                    param                                                        = out;
                    param.rating_amp_facecircle_amp                              = demean(out.rating_amp).*demean(out.facecircle_amp);
                    
                    %extract the parameters for the currently selected subjects
                    c=[];
                    for C = covariate_id
                        c                                                            = [c param.(C{1})];
                    end
                    c  = zscore(c);
                    %register beta images and covariate values.                    
                    tcell                                                        = length(matlabbatch{1}.spm.stats.factorial_design.des.anova.icell)
                    ccc                                                          = 0;
                    mat                                                          = kron(eye(tcell),c);
                    for ncell = 1:size(mat,2)
                        matlabbatch{1}.spm.stats.factorial_design.cov(ncell)     = struct('c', mat(:,ncell), 'cname', sprintf('cov:%s-cell:%02d',covariate_id_name,ncell), 'iCFI', 1, 'iCC', 1);                        
                    end                    
                end
                matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none     = 1;
                matlabbatch{1}.spm.stats.factorial_design.masking.im             = 1;                
                matlabbatch{1}.spm.stats.factorial_design.masking.em             = {self.SecondLevel_Mask(ngroup(1))};                
                matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit         = 1;
                matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
                matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm        = 1;
                %
                matlabbatch{2}.spm.stats.fmri_est.spmmat                         = {[spm_dir '/SPM.mat']};
                matlabbatch{2}.spm.stats.fmri_est.method.Classical               =  1;
                %                                
                spm_jobman('run', matlabbatch);
                %%
                if isempty(covariate_id)                   
                    %UPDATE THE SPM.mat with the contrast
                    %create the contrast that we are interested in, this could
                    %be later extended into a for loop
                    load(sprintf('%s/SPM.mat',spm_dir));
                    SPM                                                          = rmfield(SPM,'xCon');%result the previous contrasts, there shouldnt by any                    
                    if length(models) ==1
                        if models == 7 | models == 3 | models == 33 | models == 31 | models == 32 | models > 1000
                            M = [[0 0 0 ]' eye(3)];
                            SPM.xCon(2) = spm_FcUtil('set','eoi','F','c',[M]',SPM.xX.xKXs);
                            M(1,2)      = 0;
                            SPM.xCon(1) = spm_FcUtil('set','eoi','F','c',[M]',SPM.xX.xKXs);
                            M           = M(3,:);
                            SPM.xCon(3) = spm_FcUtil('set','interaction','T','c',M(:),SPM.xX.xKXs);
                            
                        elseif models == 4 | models == 44 | models == 43 | models == 42
                            M           = [[0 0 0 0 0]' eye(5)];
                            SPM.xCon(2) = spm_FcUtil('set','eoi','F','c',[M]',SPM.xX.xKXs);
                            M(1,2)      = 0;
                            SPM.xCon(1) = spm_FcUtil('set','eoi','F','c',[M]',SPM.xX.xKXs);
                            M           = zeros(5,6)
                            M(3,4)      = 1;
                            SPM.xCon(3) = spm_FcUtil('set','eoi','F','c',[M]',SPM.xX.xKXs);
                        elseif models == 5
                            M           = [[0 0 0 0 0 0 0 0]' eye(8)];
                            SPM.xCon(2) = spm_FcUtil('set','eoi','F','c',[M]',SPM.xX.xKXs);
                            M(1,2)      = 0;
                            SPM.xCon(1) = spm_FcUtil('set','eoi','F','c',[M]',SPM.xX.xKXs);
                            %                        SPM.xCon(2) = spm_FcUtil('set','eoi','F','c',[[0 0 0 ]' zeros(3) [0 0 0 ]' eye(3)]'  ,SPM.xX.xKXs);
                        elseif models == 8
                            SPM.xCon(1) = spm_FcUtil('set','eoi','F','c',[[zeros(1,11)]' eye(11) ]',SPM.xX.xKXs);
                        elseif models == 88
                            SPM.xCon(1) = spm_FcUtil('set','eoi','F','c',[[zeros(1,20)]' eye(20) ]',SPM.xX.xKXs);
                        end
                    else %multiple models entered, this specific to the RW analysis right now
                        tmodel      = size(beta_files,3);
                        tbeta       = size(beta_files,2);
                        tcolumn     = tmodel*tbeta;
                        for nmodel  = 1:tmodel
                            M                   = [zeros(3,4*(nmodel-1))  [[0 0 0 ]' eye(3)] zeros(3,tcolumn-4*(nmodel))];
                            SPM.xCon(nmodel) = spm_FcUtil('set',sprintf('eoi-%03d',nmodel-1),'F','c',[M]',SPM.xX.xKXs);
                        end
                        M               = eye(tmodel*tbeta);
                        SPM.xCon(end+1) = spm_FcUtil('set','time','F','c',M(repmat([0 1 0 0],1,tmodel)==1,:)',SPM.xX.xKXs);
                        SPM.xCon(end+1) = spm_FcUtil('set','gau','F','c',M(repmat([0 0 1 0],1,tmodel)==1,:)',SPM.xX.xKXs);
                        SPM.xCon(end+1) = spm_FcUtil('set','timeXgau','F','c',M(repmat([0 0 0 1],1,tmodel)==1,:)',SPM.xX.xKXs);
                    end
                    %%  
                    SPM = spm_contrasts(SPM);
                    save(sprintf('%s/SPM.mat',spm_dir),'SPM');%save the SPM with the new xCon field
                    %xSPM is used to threshold according to a contrast.
%                     xSPM = struct('swd', spm_dir,'title','eoi','Ic',1,'n',1,'Im',[],'pm',[],'Ex',[],'u',.00001,'k',0,'thresDesc','none');                    
%                     xSPM = struct('swd', spm_dir,'title','eoi','Ic',length(SPM.xCon),'n',[],'Im',[],'pm',[],'Ex',[],'u',.05,'k',0,'thresDesc','FWE');
                    %replace 'none' to make FWE corrections.
%                     [SPM xSPM] = spm_getSPM(xSPM);%now get the tresholded data, this will fill in the xSPM struct with lots of information.
%                     save(sprintf('%s/SPM.mat',spm_dir),'SPM');%save the SPM with the new xCon field
%                     save(xspm_path,'xSPM');
                end
            else
                load(spm_path);                                
            end            

        end        
        function B                          = SecondLevel_Mumfordian(self,nrun,mask_id)
            %
            B = [];
            for ns = self.subject_indices
                s        = Subject(ns);
                beta     = s.analysis_mumfordian(nrun,mask_id);
                B        = cat(3,B,mean(beta,3));
            end
        end
        function                              LatencyMap(self,midlevel_path,xBF)
            %Will read all beta images in midlevel_path consisting of a FIR
            %model.
            beta_files      = strvcat(FilterF(sprintf('%smidlevel/',self.path_project),midlevel_path,'beta'));
            total_beta      = size(beta_files,1);
            target_path     = strvcat(regexp(fileparts(beta_files(1,:)),'run0.*','match'));
            target_path     = sprintf('%smidlevel/%s/',self.path_project,target_path);
            target_path     = regexprep(target_path,'spm','latencymaps');
            if exist(target_path) == 0
                mkdir(target_path);
            end                
            fprintf('Found %i beta files here...\n',total_beta);
            if total_beta == 0
                fprintf('Found 0 beta files here...\n');
                keyboard
            end
            %% read the data [x,y,z,time,cond], and put it into a [x*y*z,time,cond];
            time_points     = size(xBF.bf,2);
            total_condition = total_beta/time_points;
            D               = spm_read_vols(spm_vol(beta_files));%[x,y,z,time,cond]
            ori_size        = size(D);
            D               = reshape(D,size(D,1)*size(D,2)*size(D,3),total_beta/total_condition,total_condition);%[x*y*z,time,cond]
            D               = mean(D,3)';%average across conditions for more reliable estimation, this is the first step in this line.
            cprintf([1 0 0],'ATTENTION ONLY FIRST 13 values are taken...\n');
            D               = xBF.bf(:,1:13)*D(1:13,:);
            %%
            Time            = linspace(0,xBF.order*self.TR,xBF.order*xBF.T+1)-5;
            pre_stim        = Time <= 0;
            pre_std         = std(D(pre_stim,:));
            post_std        = std(D(~pre_stim,:));
            post_amp        = mean(D(~pre_stim,:));
            for p = linspace(10,90,10)
                threshold  = prctile(post_amp,p);
                for factor = linspace(1,5,10)
                    valid           = post_std > (pre_std*factor);%valid voxels with high SNR
                    valid           = valid & (post_amp > threshold);                    
                    [~,Latency]     = max(D);%sample with peak value.
                    Latency         = Time(Latency);
                    valid           = valid & (Latency<7);
                    Latency(~valid) = 0;
                    %cancel all voxels with low SNR
                    Latency         = reshape(Latency,ori_size(1),ori_size(2),ori_size(3));
                    %%
                    dummy           = spm_vol(beta_files(1,:));
                    dummy.fname     = sprintf('%s/latency_map_factor_%1.2g_%1.2g.nii',target_path,factor,p);
                    spm_write_vol(dummy,Latency);
                end
            end
        end
        function nface                      = analysis_selected_face(self,varargin)
            %will plot an histogram of detected faces 
            subjects = self.subject_indices
            if nargin > 1
                subjects = varargin{1};
            end
            nface = [];            
            for ns = subjects;
                s     = Subject(ns);
                nface = [nface s.detected_face];                
            end  
            self.plot_newfigure;
            self.plot_bar(histc(nface,linspace(-135,180,8)));
        end
        function [count_facewc,count_facew] = analysis_facecircle(self)
            % will conduct a group level face saliency analysis, will also
            % save the weights associated to each position. The analysis is
            % limited to the first 60 fixations, this seems to be the
            % number of fixations where everybody has equal numbers i.e.
            % number of participants with 70, 80, 90 fixations drops
            % linearly with number of fixations.
            %
            viz = 1;
            raw   = [];%will contain fix by fix all the info
            for ns = self.subject_indices;
                s         = Subject(ns);
                [dummy]   = s.get_facecircle(1);%with no partition.
                raw       = [raw dummy.raw];
            end
                        %                     .RAW field is [ 
            %                            1/X coor;
            %                            2/Y coor
            %                            3/duration of fixation
            %                            4/Angle of the fixation
            %                            5/distance to center
            %                            6/Wedge Index, meaning position that PTB used to draw
            %                            7/Wedge Angle, the angle in PTB definition,
            %                            basically rounded fixation angles.
            %                            8/Face angle, this is the angular distance to CS+
            %                            9/Face Index, this is the filename of the stimulus
            %                            10/Rank; this is the order of the fixation along the 30 seconds
            %                            11/START time
            %                            12/angle of fixation maps aligned to CS+.
            %                            13/old amp.
            %                            14/subject index.
            counts       = histc( raw(10,:) , 1:100);
            limit        = 60;
            fprintf('I will take the first %i fixations\n',limit);
            %delete all fixations above LIMIT
            valid        = raw(10,:) <= limit;
            raw          = raw(:,valid);
            PositionBias = accumarray(raw(6,:)',1);
            W            = 1./PositionBias;
            save(sprintf('%smidlevel/run003/facecircle_position_weights_limit_%i.mat',s.path_project,limit),'W');
            %%
            if viz
                figure(1);set(gcf,'position',[67   350   327   752]);
                bar(circshift(PositionBias,[2 0]),.9,'k')
                set(gca,'color','none','xticklabel',{'' '' '' '12 Uhr' '' '' '' '6 Uhr'});xlabel('positions');box off;ylabel('# fixations');xlim([.5 8.5]);ylim([0 700]);SetTickNumber(gca,3,'y');                            
                % sanity check
                figure(2);set(gcf,'position',[67   350   327   752]);
                bar(accumarray(raw(6,:)',W(raw(6,:)')),.9,'k');
                set(gca,'color','none','xticklabel',{'' '' '' '12 Uhr' '' '' '' '6 Uhr'},'ytick',1);xlabel('positions');box off;ylabel('# wfixations');xlim([.5 8.5]);ylim([0 1.5]);
                % overall saliency profile            
                figure(3);set(gcf,'position',[67   350   327   752]);
                h=bar(accumarray(raw(9,:)',W(raw(6,:)')),.9);
%                 SetFearGenBarColors(h);
                set(gca,'color','none','xticklabel',{'' '' '' 'CS+' '' '' '' 'CS-'},'ytick',1,'ygrid','on');xlabel('positions');box off;ylabel('# wfixations');xlim([.5 8.5]);ylim([0 1.5]);
                set(get(h,'Children'),'FaceAlpha',1)
                % overall saliency without correction
                figure(4);set(gcf,'position',[67   350   327   752]);
                h=bar(accumarray(raw(9,:)',1),.9);
%                SetFearGenBarColors(h)                
                set(gca,'color','none','xticklabel',{'' '' '' 'CS+' '' '' '' 'CS-'},'ygrid','on');xlabel('positions');box off;ylabel('# wfixations');xlim([.5 8.5]);
                set(get(h,'Children'),'FaceAlpha',1)
            end
            %%  sort fixations rank by rank
            count_facew=[];
            count_posw =[];
            for nrank = 1:limit;
                valid                = raw(10,:) == nrank;                       
                count_facew(nrank,:)  = accumarray(raw(9,valid)',W(raw(6,valid)'),[8 1]);
                count_posw(nrank,:)   = accumarray(raw(6,valid)',W(raw(6,valid)'),[8 1]);                
            end
            %%
            if viz
                figure(4);set(gcf,'position',[680         681        1001         417]);
                subplot(1,4,1);
                imagesc(1:8,1:60,count_facew);axis xy;ylabel('fixation order');xlabel('condition');
                set(gca,'xticklabel',{'' '' '' 'CS+' '' '' '' 'CS-'},'xtick',1:8);                
                subplot(1,4,2);
                count_facewc = conv2([count_facew count_facew count_facew],ones(2,2),'same');
                count_facewc = count_facewc(:,9:16);
                imagesc(count_facewc);axis xy;set(gca,'xticklabel',{'' '' '' 'CS+' '' '' '' 'CS-'},'xtick',1:8,'yticklabel',{});                
                subplot(1,4,3);
                imagesc(1:8,1:60,cumsum(count_facewc));axis xy;set(gca,'yticklabel',{''});set(gca,'xticklabel',{'CS+'  'CS-'},'xtick',[4 8],'xgrid','on');
                subplot(1,4,4);
                contour(1:8,1:60,cumsum(count_facewc),30);axis xy;set(gca,'yticklabel',{''});set(gca,'xticklabel',{'CS+' 'CS-'},'xtick',[4 8],'xgrid','on');
            end
            %% model comparison
            data.y           = cumsum(count_facewc);
            data.x           = repmat(linspace(-135,180,8),size(data.y,1),1);
            data.ids         = 1:size(data.y,1);
            t2               = Tuning(data);
            t2.visualization = 0;
            t2.gridsize      = 10;
            t2.SingleSubjectFit(8);
            t2.SingleSubjectFit(7);
            winfun = [8 7];
            if viz
                figure(5);clf;
                for nfix = 1:limit
                    hold on;
                    X = t2.fit_results{7}.x_HD(1,:);
                    
                    if (t2.fit_results{8}.pval(nfix) > t2.fit_results{7}.pval(nfix))%Gaussian wins
                        winfun = 8
                        Est    = t2.fit_results{winfun}.params(nfix,:);
                        Est(4) = 0;
                        c = 'r';
                    else% cosine wins
                        winfun = 7
                        Est    = t2.fit_results{winfun}.params(nfix,:);
                        Est(3) = Est(1);
                        c = 'b';
                    end
                    Y      = t2.fit_results{winfun}.fitfun(X,Est);
                    plot3(X,repmat(nfix,1,size(X,2)),Y,'color',c,'linewidth',1);
                end
                hold off;
                view(43,32)
                ylim([0 60])
                DrawPlane(gcf,.4);
                
                set(gca,'xtick',[0 180],'xticklabel',{'high' 'low'},'xgrid','on','ytick',[0 30 60],'ztick',[0 .35 .7],'ygrid','on','color','none')
                xlabel('similarity');
                ylabel('fixation');
                figure(6)
                plot(t2.fit_results{7}.pval,'linewidth',3);
                hold on;
                plot(t2.fit_results{8}.pval,'r','linewidth',3);
                box off;
                xlabel('fixations');
                ylabel('LRT (-log(p))');
                ylim([0 8])
                legend({'Cosine vs. Null','Gaussian vs. Null'});legend boxoff;
                set(gca,'color','none')
            end
        end                        
        function [names]                    = CacheROI(self)
           %run this method to cache all the ROIs that are potentially interesting
           
           %% the mumfordian analysis at ROIs which are shown to be            
           sk               = 6;           
           ngroup           = 3;
           run              = 1;
           model            = 3;
           beta_image_index = 1:4;
           covariate_id     = 0;
           t                = spm_list('table',self.SecondLevel_ANOVA(ngroup,run,model,beta_image_index,sk,covariate_id));%SecondLevel_ANOVA(ngroup,run,model,beta_image_index,sk,covariate_id)           
           betas            = reshape(1:715,65,11)';
           betas            = betas(1:8,self.mbi_valid);
           names            = [];
           list1            = self.get_selected_subjects(0).list;           
           for sk = [0 6];
               for coor = [t.dat{:,end};ones(1,size(t.dat,1))];                                          
                       r = ROI('voxel_based',coor ,'chrf_0_0_mumfordian',0,betas(:)',list1,sk);                                                                                            
               end
           end           
           fprintf('-------------------------------------------------------------------------------------------\n');
           fprintf('-------------------------------------------------------------------------------------------\n');
           fprintf('------------------7-------------------------------------------------------------------------\n');
           %% get rois for all the ROIs as well.
           for sk = [0 6];               
                   for nroi = self.valid_atlas_roi
                       r = ROI('roi_based',nroi,'chrf_0_0_mumfordian',0,betas(:)',list1,sk);                                                                                            
                   end
           end
        end
        function cmat                       = analysis_behavioral_correlation(self,type,varargin)
            %%            
            if nargin > 2
                ngroup = varargin{1};
            else
                ngroup = 0;
            end
           
            viz                    = 1;                        
            param_ori              = self.getgroup_all_param(ngroup);
            %%
            if self.selected_fitfun == 8
                interesting_parameters = [4 16 17 18 20 23 24 25 27 30  34 35 37 40 31 33];
            elseif self.selected_fitfun == 3
                interesting_parameters = [4 16 17:22 26:28 23 25 ];
            end
            param                  = param_ori(:,interesting_parameters);                          
            tvar                   = size(param,2);
            names                  = param.Properties.VariableNames
            data                   = table2array(param);
            
            cmat = corr(data,'type',type);                     
            %%
            if viz
                clf; 
                hold off
                imagesc(CancelDiagonals(cmat.^2,NaN));colorbar;axis ij
                caxis([0 .3])
                set(gca,'xtick',[1:tvar],'XTickLabel',names,'ytick',[1:tvar],'YTickLabel',names','XAxisLocation','top','TickLabelInterpreter','none','XTickLabelRotation',45,'YTickLabelRotation',45)
                axis square
                hold on
                if self.selected_fitfun == 8
                    plot([3 3]-.5,ylim,'k','linewidth',2);
                    plot(xlim,[3 3]-.5,'k','linewidth',2);                    
                    plot(xlim,[7 7]-.5,'k','linewidth',2);
                    plot([7 7]-.5,ylim,'k','linewidth',2);
                    plot(xlim,[11 11]-.5,'k','linewidth',2);
                    plot([11 11]-.5,ylim,'k','linewidth',2);
                    plot(xlim,[15 15]-.5,'k','linewidth',2);
                    plot([15 15]-.5,ylim,'k','linewidth',2);
                elseif self.selected_fitfun == 3
                    plot([3 3]-.5,ylim,'k','linewidth',2);
                    plot(xlim,[3 3]-.5,'k','linewidth',2);                    
                    plot(xlim,[6 6]-.5,'k','linewidth',2);
                    plot([6 6]-.5,ylim,'k','linewidth',2);
                    plot(xlim,[9 9]-.5,'k','linewidth',2);
                    plot([9 9]-.5,ylim,'k','linewidth',2);
                    plot(xlim,[12 12]-.5,'k','linewidth',2);
                    plot([12 12]-.5,ylim,'k','linewidth',2);
                end
                title(sprintf('Type: %s',type));
            end
        end        
    end    
    methods %plotters
        function plot_normalized_surface(self);
            %will plot the inflated brain with the F maps.
            close all;
%             cmap      = parula(256);
            cmap      = hot(256);
            threshold = 10;
            group     = 3;
            inflated  = 1;
            %%
            cat_surf_display(struct('data',{{'/mnt/data/project_fearamy/data/midlevel/run000/mrt/surf/rh.central.w_ss_data.gii'}},'multisurf',0));
%             cat_surf_display(struct('data',{{'/mnt/data/project_fearamy/data/midlevel/run000/mrt/surf/lh.central.w_ss_data.gii'}},'multisurf',0))            
            
            MAP  = cat_surf_render('ColourMap',gca,cmap);
            P    = spm_mesh_project(MAP.patch,'/mnt/data/project_fearamy/data/second_level/run001/spm/model_04_chrf_0_0/cov_id_/10mm/fitfun_08/group_Saliency_vM_1/spmF_0002.nii','nn');
            cat_surf_render('overlay',gca,P);
            ab   = cat_surf_render('clim',gca,[0 threshold]);
            if inflated
                spm_mesh_inflate(MAP.patch,Inf,1);            
            end
            colorbar
            
            SaveFigure(sprintf('~/Desktop/fearamy_figure2_group_%02d_side_%02d_inflated_%02d.png',group,1,inflated),'-r300');pause(.5);            
            view(-90,0);
            SaveFigure(sprintf('~/Desktop/fearamy_figure2_group_%02d_side_%02d_inflated_%02d.png',group,2,inflated),'-r300');pause(.5);
            %%
            group = 1;
            cat_surf_display(struct('data',{{'/mnt/data/project_fearamy/data/midlevel/run000/mrt/surf/rh.central.w_ss_data.gii'}},'multisurf',0));
%             cat_surf_display(struct('data',{{'/mnt/data/project_fearamy/data/midlevel/run000/mrt/surf/lh.central.w_ss_data.gii'}},'multisurf',0))                        
            MAP  = cat_surf_render('ColourMap',gca,cmap);
            P    = spm_mesh_project(MAP.patch,'/mnt/data/project_fearamy/data/second_level/run001/spm/model_04_chrf_0_0/cov_id_/10mm/fitfun_08/group_Rating_vM_1/spmF_0002.nii','nn');
            cat_surf_render('overlay',gca,P);
            ab   = cat_surf_render('clim',gca,[0 threshold]);
            if inflated
                spm_mesh_inflate(MAP.patch,Inf,1);            
            end
            colorbar
            
            SaveFigure(sprintf('~/Desktop/fearamy_figure2_group_%02d_side_%02d_inflated_%02d.png',group,1,inflated),'-r300');pause(.5);
            view(-90,0)
            SaveFigure(sprintf('~/Desktop/fearamy_figure2_group_%02d_side_%02d_inflated_%02d.png',group,2,inflated),'-r300');pause(.5);
            
            %%
            group = 0;
            cat_surf_display(struct('data',{{'/mnt/data/project_fearamy/data/midlevel/run000/mrt/surf/rh.central.w_ss_data.gii'}},'multisurf',0));
%             cat_surf_display(struct('data',{{'/mnt/data/project_fearamy/data/midlevel/run000/mrt/surf/lh.central.w_ss_data.gii'}},'multisurf',0))            
            MAP  = cat_surf_render('ColourMap',gca,cmap);
            P    = spm_mesh_project(MAP.patch,'/mnt/data/project_fearamy/data/second_level/run001/spm/model_04_chrf_0_0/cov_id_/10mm/fitfun_08/group_00_all/spmF_0001.nii','nn');
            cat_surf_render('overlay',gca,P);
            ab   = cat_surf_render('clim',gca,[0 threshold]);
            if inflated
                spm_mesh_inflate(MAP.patch,Inf,1);            
            end            
            SaveFigure(sprintf('~/Desktop/fearamy_figure2_group_%02d_side_%02d_inflated_%02d.png',group,1,inflated),'-r300');pause(.5);
            view(-90,0)
            SaveFigure(sprintf('~/Desktop/fearamy_figure2_group_%02d_side_%02d_inflated_%02d.png',group,2,inflated),'-r300');pause(.5);
        end
        function plot_ss_ratings(self,varargin)
            figure;set(gcf,'position',[5           1        1352        1104]);
            %will plot all single subject ratings in a big subplot
            tsubject = length(self.subject_indices);
            [y x]    = GetSubplotNumber(tsubject);
            c =0;            
            if ~isempty(varargin)
                T     = self.getgroup_all_param;
                [~,i] = sort(T.(varargin{1}));
            else
                i = 1:tsubject;
            end
            for ns = self.subject_indices(i)
                c        = c+1;
                s        = Subject(ns);
                subplot(y,x,c)                
                s.plot_rating;
            end
            supertitle(self.path_project,1)
        end
        function plot_ss_pmf(self,chains)
            figure;set(gcf,'position',[5           1        1352        1104]);
            %will plot all single subject ratings in a big subplot
            tsubject = length(self.subject_indices);
            [y x]    = GetSubplotNumber(tsubject);
            c =0;
            for ns = self.subject_indices                
                c        = c+1;
                s        = Subject(ns);
                subplot(y,x,c)                                
                s.plot_pmf(chains);                
            end
            supertitle(self.path_project,1)
        end
        function plot_ss_facecircle(self,partition,varargin)
            if nargin < 2
                partition = 1
            end
            figure;set(gcf,'position',[5           1        1352        1104]);
            %will plot all single subject ratings in a big subplot
            tsubject = length(self.subject_indices);
            [y x]    = GetSubplotNumber(tsubject);
            
            
            if ~isempty(varargin)
                T     = self.getgroup_all_param;
                [~,i] = sort(T.(varargin{1}));
            else
                i = 1:tsubject;
            end
            
            c =0;
            for ns = self.subject_indices(i)
                c        = c+1;
                s        = Subject(ns);
                subplot(y,x,c)                
                s.plot_facecircle(partition);
            end
            supertitle(self.path_project,1)
        end
        function plot_ss_detected_oddballs(self)
            o = self.getgroup_detected_oddballs;
            o = o.detection_oddball;
            bar(1:40,o,.9,'k');
            xlabel('subjects');
            ylabel('# detected oddballs out of 2');
            box off;
            ylim([0 3]);
            xlim([0 41]);
            set(gca,'ytick',[0 1 2],'xtick',1:40,'xticklabel',5:44);
            title('oddball performace');
        end
        function plot_ss_scr(self)
            figure;set(gcf,'position',[5           1        1352        1104]);
            %will plot all single subject ratings in a big subplot
            tsubject = length(self.subject_indices);
            [y x]    = GetSubplotNumber(tsubject);
            c =0;
            for ns = self.subject_indices                
                c        = c+1;
                s        = Subject(ns,'scr');
                subplot(y,x,c)                
                s.plot_scr;
            end
            supertitle(self.path_project,1);            
        end
        function plot_activitymap_normalized(self,files)
            %plots the data in a volume as average intensity projection, as
            %a 3xN panel, where N is the number of volumes. Masking
            %operates in the normalized space.
            
            %%                        
            %%                    
            files      = vertcat(files{:});
            vh         = spm_vol(files);%volume handle
            data_mat   = spm_read_vols(vh);%read the activity data, bonus: it checks also for orientation.
            [XYZmm]    = self.get_nativeatlas2mask(120);%world space;
            XYZvox     = self.get_mm2vox(XYZmm,vh(1));%get indices for the selected voxels.
            s          = size(data_mat);if length(s) == 3;s = [s 1];end
            mask       = logical(zeros(s(1:3)));%create an empty mask.
            i          = sub2ind(size(data_mat),XYZvox(1,:),XYZvox(2,:),XYZvox(3,:));
            mask(i)    = true;              
            %%
            tcond      = size(data_mat,4);
            %mask the data
            data_mat   = data_mat.*repmat(mask,[1 1 1 tcond]);
            %
            x          = [min(find(sum(squeeze(sum(mask,3)),2) ~= 0)) max(find(sum(squeeze(sum(mask,3)),2) ~= 0))];
            y          = [min(find(sum(squeeze(sum(mask,3))) ~= 0)) max(find(sum(squeeze(sum(mask,3))) ~= 0))];
            z          = [min(find(sum(squeeze(sum(mask))) ~= 0)) max(find(sum(squeeze(sum(mask))) ~= 0))];
                        
            %vectorize it so that we can get the contribution of all voxels to the
            %colormap computation
            
            %for the first COL conditions
            col                                    = tcond;            
            dummy                                  = reshape(data_mat,prod(s(1:3)),s(4));
            dummy                                  = mean(dummy(mask(:),:),2);
            sigma_cmap = 4;
            [roi.cmap(1:tcond,1) roi.cmap(1:tcond,2)]  = GetColorMapLimits(dummy(:),sigma_cmap);
            %            
            for n = 1:tcond
                current          = data_mat(x(1):x(2),y(1):y(2),z(1):z(2),n);                
                current_mask     = mask(x(1):x(2),y(1):y(2),z(1):z(2));                
                % get the data
                roi.x(:,:,n)     = squeeze(nanmean(current,1));
                roi.y(:,:,n)     = squeeze(nanmean(current,2));
                roi.z(:,:,n)     = squeeze(nanmean(current,3));
                
                % get the alpha masks
                roi.x_alpha      = squeeze(mean(double(current_mask),1) ~=  0);
                roi.y_alpha      = squeeze(mean(double(current_mask),2) ~=  0);
                roi.z_alpha      = squeeze(mean(double(current_mask),3) ~=  0);
                %
            end            
            %%
            fields_alpha = {'x_alpha' 'y_alpha' 'z_alpha' };
            fields_data  = {'x' 'y' 'z'};
            ffigure(1);clf;
            for ncol = 1:tcond;%run over conditions
                for nrow = 1:3%run over rows
                    subplot(3,tcond, ncol+(tcond*(nrow-1)) );                    
                    imagesc(roi.(fields_data{nrow})(:,:,ncol),[roi.cmap(1,1) roi.cmap(1,2)]);
                    alpha(double(roi.(fields_alpha{nrow})));
                    box off  
                    axis off
                    thincolorbar('horizontal');            
                    set(gca,'xtick',[],'ytick',[],'linewidth',1);
                    axis image;
                    drawnow;
                end
            end
            
        end
        function plot_volume(self,filename)
            %will plot the volume using spm_image;
            global st                        
            spm_image('init',filename)
            spm_clf;
%             st.callback = @self.test
            spm_orthviews('Image',filename)
%             spm_image('display',filename)
            spm_orthviews('AddColourBar',h(1),1);
            spm_orthviews('AddContext',h(1));
%             keyboard
        end        
        function plot_newfigure(self)
            figure;
            set(gcf,'position',[671   462   506   477]);
        end
        function test3(self)
            
            global st;
            try               
                coor   = (st.centre);                                
                betas  = self.path_beta(1,6,'s04_wCAT_',1:488);                
                tbeta  = size(betas,1);
                XYZvox = self.get_mm2vox([coor ;1],spm_vol(betas(1,:)));
                d = spm_get_data(betas,XYZvox);
                d = reshape(d,tbeta/8,8);                
                d = conv2([d d d],ones(2,2),'same');
                d = d(:,9:16);
                figure(10005);
                set(gcf,'position',[919        1201         861        1104])                
                subplot(1,3,1)
                imagesc(d);colorbar;axis xy;
                subplot(1,3,2)
                imagesc(cumsum(d));colorbar
                axis xy;
                subplot(1,3,3);
                bar(mean(d));                
                
                
            catch
                fprintf('call back doesn''t run\n')
            end
        end        
        function cb_fir_vs_hrf(self)
            global st
            try               
                coor                   = (st.centre);
                figure(10002);
                set(gcf,'position',[950        1201         416        1104])                
                set(gca, 'ColorOrder', GetFearGenColors, 'NextPlot', 'replacechildren');
                %% get BF for FIR and HRF, this should be exactly the same
                %ones we used for the first-levels
                TR              = self.TR;
                xBF.T           = 16;
                xBF.T0          = 1;
                xBF.dt          = TR/xBF.T;
                xBF.UNITS       = 'scans';
                xBF.Volterra    = 1;
                xBF.name        = 'Finite Impulse Response';
                xBF.order       = 15;
                xBF.length      = 15*TR;
                fir_xBF         = spm_get_bf(xBF);
                %
                TR              = self.TR;
                xBF.T           = 16;
                xBF.T0          = 1;
                xBF.dt          = TR/xBF.T;
                xBF.UNITS       = 'scans';
                xBF.Volterra    = 1;
                xBF.name        = 'hrf';
                xBF.order       = 1;
                xBF.length      = 15*TR;
                hrf_xBF         = spm_get_bf(xBF);
                %
                %% now load the betas for both the FIR and HRF models.
                betas           = FilterF(sprintf('%s/midlevel/run001/spm/model_02_fir_15_15/s_w_beta_*',self.path_project));
                betas           = vertcat(betas{:});                
                XYZvox          = self.get_mm2vox([coor ;1],spm_vol(betas(1,:)));
                d               = spm_get_data(betas,XYZvox);
                d               = reshape(d,15,9);%this is the FIR model fit.
                subplot(2,1,1);
                set(gca, 'ColorOrder', GetFearGenColors, 'NextPlot', 'replacechildren');
                plot(d);
                %% now load the hrf model
                betas           = FilterF(sprintf('%s/midlevel/run001/spm/model_02_chrf_0_0/s_w_beta_*',self.path_project));
                betas           = vertcat(betas{:});
                XYZvox          = self.get_mm2vox([coor ;1],spm_vol(betas(1,:)));
                B               = spm_get_data(betas,XYZvox);%these are 9 betas images
                Fit             = hrf_xBF.bf(:,1:16:end,:)*B';
                subplot(2,1,2);
                set(gca, 'ColorOrder', GetFearGenColors, 'NextPlot', 'replacechildren');
                Time            = [1:518]*hrf_xBF.dt;                
                plot(Time,Fit);xlim([0 15]);

            end
        end        
        function test2(self)
            
            global st;
            try
                TR                     =.99;
                xBF.T                  = 16;
                xBF.T0                 = 1;
                xBF.dt                 = TR/xBF.T;
                xBF.UNITS              = 'scans';
                xBF.Volterra           = 1;
                xBF.name               = 'Fourier set';
                xBF.order              = 20;
                xBF.length             = 20*TR;
                xBF                    = spm_get_bf(xBF);
                %
                Time                   = linspace(0,20*TR,20*16+1)-5;
                %
                
                coor = (st.centre);
                self.default_model_name                                 = 'fourier_20_20';
                %betas = self.path_beta(1,2,'s_',1:135);
                betas  = FilterF(sprintf('%s/midlevel/run001/spm/model_02_fourier_20_20/s_w_beta_*',self.path_project));
                betas  = vertcat(betas{:});
                XYZvox = self.get_mm2vox([coor ;1],spm_vol(betas(1,:)))
                d = spm_get_data(betas,XYZvox);
                d = reshape(d,41,9);
                d(13:end,:) = 0;
                d = xBF.bf*d;                
                figure(10002);
                set(gcf,'position',[950        1201         416        1104])                
                subplot(3,1,1)
                set(gca, 'ColorOrder', GetFearGenColors, 'NextPlot', 'replacechildren');
                plot(Time,d);
                box off;
                hold on;
                plot(Time,mean(d(:,1:8),2),'k--','linewidth',3);                
                plot([0 0], ylim,'k');
                xlabel('time (s)');
                hold off;
                subplot(3,1,2)
                imagesc(d);colormap jet;
                subplot(3,1,3)                
                set(gca, 'ColorOrder', [linspace(0,1,15);zeros(1,15);1-linspace(0,1,15)]', 'NextPlot', 'replacechildren');
                data = [];
                data.x   = repmat(linspace(-135,180,8),15,1);
                data.y   = d(:,1:8);
                data.ids = 1:15;
                Y = repmat([1:15]',1,8);
                h=bar(mean(d));
%                 SetFearGenBarColors(h);
                grid on;
                self.default_model_name                                 = 'chrf_0_0';
                %
                betas  = FilterF(sprintf('%s/second_level/run001/spm/model_05_chrf_0_0/beta_*',self.path_project));
                betas  = vertcat(betas{:});
                XYZvox = self.get_mm2vox([coor(:); 1],spm_vol(betas(1,:)));
                d      = spm_get_data(betas,XYZvox);
                Weights2Dynamics(d(:)');
            catch
                fprintf('call back doesn''t run\n')
            end
        end
        function feargen_canonical_correlation(self,ngroup,run,models,beta_image_index,sk,covariate_id,NCONTRAST)
            %% [SPM xSPM] = spm_getSPM
            SPM         = self.SecondLevel_ANOVA(ngroup,run,models,beta_image_index,sk,covariate_id);
%             xSPM        = struct('swd', SPM.swd,'title',SPM.xCon(NCONTRAST).name,'Ic',NCONTRAST,'n',[],'Im',[],'pm',[],'Ex',[],'u',.001,'k',0,'thresDesc','none');
            %% get coordinates from the xSPM [1x3]
            coors       = self.get_SecondLevel_ANOVA_coordinates(ngroup,run,models,beta_image_index,sk,[],NCONTRAST)
            tSite       = size(coors,2);
            %% get the data matrix [Nx5]
            data  = {};
            narea = 0;
            for coor = coors
                narea          = narea+1;
                XYZvox         = self.get_mm2vox(coor(:),SPM.xCon(NCONTRAST).Vspm);
                dummy          = reshape(spm_get_data([SPM.xY.VY],XYZvox),39,6);
                data{narea}    = dummy(:,2:end);
            end                        
            %% get the canonical correlation weights for all pair-wise combinations. [NxN]
            tSite = length(data);
            for n = 1:tSite
                for m = 1:tSite
                    if n < m
                    [n m ]
                    R        = 1-squareform(pdist([data{n},data{m}]','correlation'));
                    R        = R(1:5,6:10);
                    SUPER    = eye(5);
                    X        = ([Vectorize([0 0 0 0 0; 0 1 1 0 0;0 1 1 0 0;0 0 0 0 0 ;0 0 0 0 0]) Vectorize([0 0 0 0 0; 0 0 0 0 0;0 0 0 0 0;0 0 0 1 1 ;0 0 0 1 1]) Vectorize([0 0 0 0 0; 0 0 0 1 1;0 0 0 1 1;0 1 1 0 0 ;0 1 1 0 0]) Vectorize([ 0 1 1 1 1; 1 0 0 0 0; 1 0 0 0 0 ; 1 0 0 0 0 ; 1 0 0 0 0 ])]);
                    
                    dummy    = fitlm(zscore(X),zscore(R(:)),'Intercept',false);
                    
                    P(n,m,:)      = dummy.Coefficients.pValue < 0.01;
                    P(m,n,:)      = P(n,m,:);
                    
                    B(n,m,:)      = dummy.Coefficients.Estimate;
                    B(m,n,:)      = B(n,m,:);
                    end
                end
            end
            %% test amp2amp, sigma2sigma, amp2sigma, sigma2amp and time2all models
            clf;
            for n = 1:tSite
                for m = 1:tSite
                    if n ~= m
                        for nRegress = 1:size(X,2)
                            subplot(2,4,nRegress)
                            
                            h1                 = plot(coors(2,[n m]),-coors(1,[n m]),'o','markersize',12);
                            h1.MarkerFaceColor = [1 0 0 ];
                            h1.MarkerEdgeColor = [1 0 0 ];
                            
                            if P(n,m,nRegress)
                                h           = line(coors(2,[n m]),-coors(1,[n m]));
                                hold on;
                                h.LineWidth = (abs(B(n,m,nRegress))*2).^2;
                                h.Color     = [0 0.45 0.74 .3];
                            end                            
                            
                            subplot(2,4,nRegress+4)
                            h1                 = plot(coors(2,[n m]),coors(3,[n m]),'o','markersize',12);
                            h1.MarkerFaceColor = [1 0 0 ];
                            h1.MarkerEdgeColor = [1 0 0 ];
                            if P(n,m,nRegress)
                                h = line(coors(2,[n m]),coors(3,[n m]));
                                hold on;
                                h.LineWidth = (abs(B(n,m,nRegress))*2).^2;
                                h.Color = [0 0.45 0.74 .3];
                            end                            
                        end                        
                    end                    
                end               
            end                
            hold off
            for n =  1:8
                subplot(2,4,n)
                box off;axis equal
            end
        end
        
        function callback_rw(self)
            %s=Subject(5);global SPM;global xSPM;global st;st.callback = @s.callback_rw;clear global t;t=s.getgroup_all_param(0);global t
            global st
            global SPM
            global xSPM
            global model
%             global a 
%             SPM = a.SPM;
%             xSPM= a.xSPM;
            global t                        
            p = pwd;
            figure(1000);clf;
            set(gcf,'position',[1114 1 1034        1093])
            fs = 8;
            common = {'fontweight','bold'};            
            try                                
                %%
                coor      = st.centre;
                XYZvox    = self.get_mm2vox([coor(:) ;1],SPM.xCon(xSPM.Ic).Vspm);
                %%   
                tsubject            = max(SPM.xX.I(:,1));
                treg                = max(SPM.xX.I(:,2));
                data                = reshape(spm_get_data([SPM.xY.VY],XYZvox(:)),tsubject,treg);
                t.brain_time        = data(:,2);
                t.brain_gau         = data(:,3);
                t.brain_time_gau    = data(:,4);
                try
                    t.brain_dsigma      = data(:,5);
                    t.brain_time_dsigma = data(:,6);
                end
                font_size_axis = 14;
                font_size_labels = 16;
                %%         plot the mean beta values & SEM, and make a ttest.
                subplot(8,8,[1 2 9 10 17 18 ]);
                predictors = {'Time (t)',' Strength (\alpha)' ' t \times \alpha' 'dG/d\sigma' 'time \times dG/d\sigma'};
                    %'$\frac{dG}{d\sigma}$' '$\frac{dG}{d\sigma}$' };
                total_beta = size(data,2);
                bar(2:total_beta,mean(data(:,2:end)),'k');
                hold on;
                errorbar(2:total_beta,mean(data(:,2:end)),std(data(:,2:end))./sqrt(tsubject),'ro','linewidth',2);
                hold off;
                set(gca,'xticklabel',predictors,'XTickLabelRotation',45,'fontweight','normal','fontsize',font_size_axis);
                ylabel(sprintf('Weight'),common{:},'fontsize',font_size_labels);
                box off;
                xlim([1.5 total_beta+.5])                
                axis tight;
                Publication_Ylim(gca,1,2);
                Publication_NiceTicks(gca,1);
                %                
                [h p] = ttest(data);                
                [sh sp] = signrank_mat(data);                
                [p ;sp]
                for n = 2:total_beta
                    if p(n) <= .05                        
                        text(n,max(ylim),pval2asterix(p(n)),'HorizontalAlignment','center',common{:},'fontsize',25);
                    end
                end
                grid on;
                %% Plot the fitted temporal dynamics
                subplot(8,8,[4 5 12 13 20 21]);
                [pmod]      = self.get_pmodmat(model);%most complex model                                                
%                 pmod(:,2) = 0;
                contourf(reshape(pmod(:,1:size(data,2))*mean(data)',8,520/8)',9,'color','none');
                S         = get(gca,'position');
%                 h         = colorbar('Location','WestOutside');
%                 h.Box     = 'off';
%                 cbarticks = linspace(min(h.Ticks),max(h.Ticks),3);
%                 h.Ticks   = cbarticks;
                axis xy;
                box off;
                set(gca,'ytick',[],'xtick',[2 4 6 8],'xticklabel',{sprintf('-90%c',char(176))  'CS+' sprintf('90%c',char(176)) 'CS-'},'fontsize',font_size_axis); 
                grid on;
                ylabel('Time','fontsize',font_size_labels,'fontweight','bold');        
                xlabel('Faces','fontsize',font_size_labels,'fontweight','bold')
                a=gca;
                a.XRuler.Axle.LineStyle = 'none';
                a.YRuler.Axle.LineStyle = 'none';
                %% plot the RW model
                
                subplot(8,8,[7 8 15 16 23 24]);
                b              = load('~/Desktop/learning_rates.mat');
                learning_rates = round(10000+[0 b.learning_rates]*10000);
                total_step     = length(learning_rates);
                models         = (learning_rates-10000)/10000;
                xticks         = 1:4:total_step;
                labels         = RemoveLeadingZeroForTickLabels(    models(xticks));
                labels{1}      = sprintf('linear');
                
                count          = 0;
                markerset      = {'-' '--' '+'};
                for groups = {'group_00_all'}%{'group_00_all' 'group_Rating_vM_1' 'group_Saliency_vM_1'};
                    count      = count + 1;
                    files      = [];betas=[];
                    for i = 1:total_step
                        files  = [files;sprintf('/mnt/data/project_fearamy/data/second_level/run001/spm/model_%d_chrf_0_0/cov_id_/06mm/fitfun_08/%s/normalization_CAT/spmF_0002.nii',learning_rates(i),groups{1})];
                        betas  = [betas;sprintf('/mnt/data/project_fearamy/data/second_level/run001/spm/model_%d_chrf_0_0/cov_id_/06mm/fitfun_08/%s/normalization_CAT/spmT_0003.nii',learning_rates(i),groups{1})];
                    end
                    datarw.(groups{1})    = spm_get_data(spm_vol(files),XYZvox(:));
                    databetas.(groups{1}) = spm_get_data(spm_vol(betas),XYZvox(:));
                    yyaxis right;
                    plot(datarw.(groups{1}),markerset{count},'linewidth',2,'color',get(gca,'ycolor'));
                    hold on;
                    axis tight;
                    %
                    yyaxis left;
                    plot(databetas.(groups{1}),markerset{count},'linewidth',2,'color',get(gca,'ycolor'));
                    hold on;
                    axis tight;
                end
                hold off;yyaxis right;hold off;
                %                
                xlabel(sprintf('Learning\nRate'),'fontsize',font_size_labels,'fontweight','bold');
                xlim([0 total_step+1]);box off;                
                set(gca,'xtick',xticks,'xticklabels',labels,'xticklabelrotation',45,'fontweight','normal','fontsize',font_size_axis);
                %
                yyaxis right
                ylabel('F-value','fontsize',font_size_labels,'fontweight','bold');
                Publication_Ylim(gca,0,2);
                Publication_NiceTicks(gca,2);
                a = gca;
                a.XRuler.Axle.LineStyle = 'none';
                a.XRuler.TickLength = [0 0];                
                                                
                yyaxis left;
                Publication_Ylim(gca,0,2);
                Publication_NiceTicks(gca,2);
                a = gca;
                a.YRuler.Axle.LineWidth = 2;
                a.YRuler.TickLength = [.01 .02];
                set(gca,'fontsize',font_size_axis);
                ylabel('Time \times Strength','fontsize',font_size_labels,'fontweight','bold');
                for n = 1:2
                    a.YAxis(n).LineWidth = 2;
                    a.YAxis(n).TickLength = [.025 0];
                end
                grid on;
                %%
%                 figure(10001);clf
%                 
%                 b              = load('~/Desktop/learning_rates.mat');
%                 learning_rates = round(10000+b.learning_rates*10000);
%                 total_step     = length(learning_rates);
%                 
%                 betas=[];
%                 for ns = t.subject_id(:)';
%                     for i = 1:total_step
%                         betas = [betas;sprintf('/mnt/data/project_fearamy/data/sub%03d/run001/spm/model_%d_chrf_0_0/s06_wCAT_beta_0004.nii',ns,learning_rates(i))];
%                     end
%                 end
%                 %
%                 betas = reshape(spm_get_data(spm_vol(betas),XYZvox(:)),total_step,length(t.subject_id(:)));                
%                 subplot(2,1,1)
% %                 B     = zscore(betas);
%                 imagesc(betas);
%                 colorbar                
%                 subplot(2,1,2);
%                 r=[];
%                 for i = 1:total_step;
%                     r(i,1)=corr(t.rating_amp,betas(i,:)');
%                     r(i,2)=corr(t.facecircle_amp,betas(i,:)');
%                 end                
%                 plot(1:total_step,(r(:,1)),'r--','linewidth',4)                
%                 hold on;
%                 plot(1:total_step,(r(:,2)),'b+','linewidth',4)                
%                 hold off;
%                 set(gca,'ylim',[-.5 .5])
%                 
%                 models = (learning_rates-10001)/10000;
%                 i      = 1:4:total_step;
%                 set(gca,'xtick',i,'xticklabels',models(i),common{:});
%                 ylabel('subjects');
%                 grid on
%                 title('timexGau')
%                 drawnow;

                %%
                pause(.4)
                figure(1000)
                
                try
                    o    =  fitlm(t,'rating_nonparam     ~ 1 + brain_time + brain_gau + brain_time_gau + brain_dsigma + brain_time_dsigma','RobustOpts','on')
                    o2   =  fitlm(t,'facecircle_nonparam ~ 1 + brain_time + brain_gau + brain_time_gau + brain_dsigma + brain_time_dsigma','RobustOpts','on')
                catch
                    o    =  fitlm(t,'rating_metric_box     ~ 1 + brain_time + brain_gau + brain_time_gau','RobustOpts','on')
                    o2   =  fitlm(t,'facecircle_metric_box ~ 1 + brain_time + brain_gau + brain_time_gau','RobustOpts','on')
                end
                
                o3 = fitlm(t,'brain_gau ~ 1 + rating_metric_box*facecircle_metric_box')
                model2text(o,'~/gdrive/Office/Fearamy/paperfigures/')
                model2text(o2,'~/gdrive/Office/Fearamy/paperfigures/')
                pos =  {[33 34 41 42 ] [36 37 44 45] [39 47 40 48 ] [52 53 60 61] [55 56 63 64] [49 50 57 58] };
                h   =  [];
                for n = 1:total_beta-1
                    h(n) = subplot(8,8,pos{n});
                    %
                    s=scatter((t.rating_metric_box(:)),data(:,n+1),40,'filled');                    
                    s.MarkerFaceAlpha = .6;
                    %
                    hold on
                    s = scatter((t.facecircle_metric_box(:)),data(:,n+1),40,[.85 .33 .1],'filled');
                    s.MarkerFaceAlpha = .6;
                    
                    axis tight;
                    xlim([-2 2]);
                    
                    hl = lsline;
                    hl(2).LineWidth= 3;
                    if o.Coefficients.pValue(n+1) < .05                   
                        hl(2).Color = [0 .45 .74];
                        hl(2).LineWidth = 5;
                    else
                        hl(2).Color = [0 .45 .74 .5];
                    end
                    hl(1).LineWidth= 3;
                    if o2.Coefficients.pValue(n+1) < .05
                       hl(1).Color = [.85 .33 .1];
                       hl(1).LineWidth = 5;
                    else
                       hl(1).Color = [.85 .33 .1 .5];
                    end
                    %
                    hold off ;                            
                    box off;
                    drawnow;
                    axis square            ;  
                    Publication_Ylim(gca,1,2);
                    Publication_SymmetricYlim(gca);
%                     EqualizeSubPlotYlim(h);
                    Publication_NiceTicks(gca,1);
                    set(gca,'fontweight','normal','fontsize',font_size_axis);
                    grid on;               
                    a = gca;
                    set(a.XRuler.Axle,'linestyle','none');set(a.XRuler,'TickLength',[0 0]);set(a.YRuler.Axle,'linestyle','none');set(a.YRuler,'TickLength',[0 0]);
                    
                    xlabel(sprintf('Fear Tuning\n(post-experiment)'),'fontweight','bold','fontsize',font_size_labels);                                        
                    ylabel(sprintf('Weight\n%s',predictors{n}),'fontweight','bold','fontsize',font_size_labels);                         
                    % add legend
                    if n == 2
                        P = get(gca,'position');
                        hl = legend({'Rating Tuning (\alpha)' 'Saliency Tuning (\alpha)'},'box','off','location','NorthOutside');
                        set(gca,'position',P) ;                       
                    end
                end                 
%                 
                axis(h(1));
                %%
%                 subplotChangeSize(h,-.06,-.06);                
                try
                    [fileparts(SPM.swd) filesep 'normalization_CAT' filesep SPM.xCon(xSPM.Ic).Vspm.fname]
                    [fileparts(SPM.swd) filesep 'normalization_EPI' filesep SPM.xCon(xSPM.Ic).Vspm.fname]
                    f_cat = spm_get_data(spm_vol([fileparts(SPM.swd) filesep 'normalization_CAT' filesep SPM.xCon(xSPM.Ic).Vspm.fname]),XYZvox(:));
                    f_epi = spm_get_data(spm_vol([fileparts(SPM.swd) filesep 'normalization_EPI' filesep SPM.xCon(xSPM.Ic).Vspm.fname]),XYZvox(:));
                    
                    mysupertext = sprintf('[%3.4g mm, %3.4g mm, %3.4g mm]\n F value = [%3.4g vs. %3.4g]\n for CAT vs. EPI normalization.',coor(1),coor(2),coor(3),f_cat,f_epi);
                    supertitle(mysupertext,1,common{:});
                catch
                    mysupertext = sprintf('[%3.4g mm, %3.4g mm, %3.4g mm]\n',coor(1),coor(2),coor(3));
                    supertitle(mysupertext,1,common{:});
                end
              %%
              %plot cluster RW curves                  
              st.centre(1:3)
              i                  = find(sum(abs(xSPM.XYZmm - repmat(st.centre(1:3),1,size(xSPM.XYZmm,2)))) == 0);
              clusters           = spm_clusters(xSPM.XYZ);              
              XYZvox             = xSPM.XYZ(:,ismember(clusters,clusters(i)));
              D                  = spm_get_data(spm_vol(files),XYZvox);
%               D                 = spm_get_data(spm_vol(betas),XYZvox);
              %
              figure(121212);clf
              set(gcf,'position',[1923         643         570/2         450])
              %
              H = shadedErrorBar([],mean(D,2),std(D,1,2)./sqrt(length(XYZvox)));
              H.edge(1).LineStyle='none';
              H.edge(2).LineStyle='none';
              ylim([0 12]);
%               plot(),'linewidth',.1,'color',[0 0 0 .3])
              %% plot the interaction of behavior and ratings
              figure(1002);
              set(gcf,'position',[238         160        1535         734]);
              fieldz    = {'brain_time' 'brain_gau' 'brain_time_gau'};
              clf;
              for n = 1:3
                  SH =subplot(2,3,n);          
                  pause(.2);
                  %
                  fieldy = {'facecircle_amp'};
                  fieldx = {'rating_amp'};


                  [m]=scatter_stat(t,{fieldz{n},fieldx{1},fieldy{1}})
                  hold on
                  pos=get(gca,'position');
                  colorbar;                  
                  set(gca,'position',pos);
                  
%                   Z     =   Vectorize(Scale(t.(fieldz{n})));
%                   scatter(t.(fieldx{1}),t.(fieldy{1}),(1+Z*3).^4,[Z(:) zeros(length(Z),1) 1-Z(:)],'filled');                  
                  %%
%                   subplotChangeSize(SH,-.05,-.05);
                  hold off;
                  axis tight;
                  axis square;
                  ylabel(sprintf('Fear Tuning\nin Behavior'));
                  xlabel(sprintf('Fear Tuning\nin Ratings'));                                    
                  
                  %% Plot the results
                  try
                      subplot(2,3,n+3);
                      effect   = m.Coefficients.Estimate(2:end);
                      effectSE = m.Coefficients.SE(2:end);
                      y = 1:3;
                      ci       = [effect effect] + effectSE*tinv([.025 .975],m.DFE);
                      h = bar(1:length(effect),effect,.9,'k');
                      hold on;
                      errorbar(1:length(effect),effect,effectSE,'ro','linewidth',1);
                      hold off;
                      box off
                      axis square;
                      Publication_NiceTicks(gca,1);
                      Publication_RemoveXaxis(gca);
                      %%
                      for n = 1:3
                          P = m.Coefficients.pValue(n+1);
                          if P < .05
                              text(n,max(ylim)-range(ylim)*.1,pval2asterix(P),'HorizontalAlignment','center','fontsize',16);
                          end
                      end
                      set(gca,'xticklabels',{'Ratings' 'Saliency' 'R*S'},'XTickLabelRotation',45);
                  end
              end
              supertitle(mysupertext,1,common{:});
            catch ME
                fprintf('call back doesn''t run\n')
                rethrow(ME)                
            end
%             cd(p)
        end
        function test(self,SPM,xSPM)
                        
            global st;
            global SPM;
            global xSPM;
            try
                
                coor = (st.centre);
%                 self.default_model_name                                 = 'fir_15_15';
%                 %betas = self.path_beta(1,2,'s_',1:135);
%                 betas  = FilterF(sprintf('%s/midlevel/run001/spm/model_02_fir_15_15/s_w_beta_*',self.path_project));
%                 betas  = vertcat(betas{:});
%                 XYZvox = self.get_mm2vox([coor ;1],spm_vol(betas(1,:)))
%                 d = spm_get_data(betas,XYZvox);
%                 d = reshape(d,15,9);
                figure(10001);
                set(gcf,'position',[ 1921         478        1098         588]);
%                 set(gcf,'position',[1370 1201 416  1104])                
%                 subplot(3,1,1)
%                 set(gca, 'ColorOrder', GetFearGenColors, 'NextPlot', 'replacechildren');
%                 plot(d);box off;
%                 hold on;plot(mean(d(:,1:8),2),'k--','linewidth',3);                
%                 hold off;
%                 subplot(3,1,2)
%                 imagesc(d);colormap jet;
%                 subplot(3,1,3)                
%                 set(gca, 'ColorOrder', [linspace(0,1,15);zeros(1,15);1-linspace(0,1,15)]', 'NextPlot', 'replacechildren');
%                 data = [];
%                 data.x   = repmat(linspace(-135,180,8),15,1);
%                 data.y   = d(:,1:8);
%                 data.ids = 1:15;
%                 Y = repmat([1:15]',1,8);
%                 h=bar(mean(d));
%                 SetFearGenBarColors(h);
%                 grid on;
%                 self.default_model_name                                 = 'chrf_0_0';
                %                
                cd(SPM.swd)
                betas  = vertcat(SPM.Vbeta(:).fname);
                %betas  = FilterF(sprintf('%s/second_level/run001/spm/model_04_chrf_0_0/cov_id_/06mm/fitfun_08/group_Rating_vM_1/beta_*',self.path_project));
                %betas  = vertcat(betas{:});
                size(betas)
                XYZvox    = self.get_mm2vox([coor(:); 1],spm_vol(betas(1,:)));
                beta      = spm_get_data(betas,XYZvox);
                
                
                ResMS = spm_get_data(SPM.VResMS,XYZvox);
                Bcov  = ResMS*SPM.xX.Bcov;
                
                CI    = 1.6449;%90
                CI    = 1.96;%95
                CI    = 2.3263;%99
                % compute contrast of parameter estimates and 90% C.I.
                %------------------------------------------------------------------
                Ic    = xSPM.Ic; % Use current contrast
                cbeta = SPM.xCon(Ic).c'*beta;
                SE    = sqrt(diag(SPM.xCon(Ic).c'*Bcov*SPM.xCon(Ic).c));
                CI    = CI*SE;

                %%                
                [pmod]      = self.get_pmodmat(5);%most complex model
                size(pmod)
                size(betas,1)
                pmod        = pmod(:,1:size(betas,1));
                %%
                subplot(1,2,2)
%                 imagesc(reshape(pmod*beta,8,520/8)');
                contourf(reshape(pmod*beta,8,520/8)',9,'color','none');
                S         = get(gca,'position');
                h         = colorbar('Location','WestOutside');
                h.Box     = 'off';
                cbarticks = linspace(min(h.Ticks),max(h.Ticks),3);
                h.Ticks   = cbarticks;
%                 set(gca,'position',S);
                axis xy;
                box off
                set(gca,'ytick',[],'xtick',[2 4 6 8],'xticklabel',{sprintf('-90%c',char(176))  'CS+' sprintf('90%c',char(176)) 'CS-'},'fontsize',16,'fontweight','bold'); 
                grid on;
                ylabel('time','fontsize',16,'fontweight','bold');
                %%
                subplot(1,2,1);
                bar(cbeta,.9,'k');                
                hold on;
                h=errorbar(cbeta,CI,'ro','linewidth',2,'marker','none');                
                box off;
                hold off;                
                grid on
                set(gca,'xticklabel',{'time','tuning' 'time \times tuning' '\sigma' 't x \sigma'},'XTickLabelRotation',45,'fontsize',16,'fontweight','bold','ytick',[-.8 -.4 0 .4 .8],'ylim',[-1 1]);
                
                ylabel(sprintf('Beta Weight\n(99%% CI)'));
                ylim([-.65 .2]);
                drawnow;                
                
            catch
                fprintf('call back doesn''t run\n')
            end
        end        
        function plot_overlay(self,file1,file2)
            spm_image('init',file1)
            spm_clf;
            pause(0.5);                                    
            v1 = spm_vol(file1);
            v2 = spm_vol(file2);        
            
            global st                                                
            st.callback = @self.test
            
            
            h  = spm_orthviews('Image' ,v1 );            
            spm_orthviews('Addtruecolourimage', h(1), file2, jet, 0.4 );
            spm_orthviews('Redraw');
            spm_orthviews('AddColourBar',h(1),1);
            spm_orthviews('AddContext',h(1));
            spm_orthviews('Caption', h(1),file2);
        end
        function hist_pmf_param(self,fields)
            %will generate an histogram of the pmf parameters
            out = self.getgroup_pmf_param;
            counter = 0;
            for fields = fields
                counter = counter+1;
                x   = linspace(0,120,11);
                c   = histc(out.(fields{1}),x);
                subplot(1,length(fields),counter)
                bar(x,c,1,'k');
                axis tight;
                box off;
                xlabel('alpha');                
                M = mean(out.(fields{1}));
                S = std(out.(fields{1}))./sqrt(size(M,1));
                hold on;
                plot([M M],ylim,'r','linewidth',4);
                hold off;
                title(sprintf('%s: %3.4g ? %3.4g (M?SEM)',fields{1},M,S),'interpreter','none');
            end
        end
        function hist_rating_param(self)
            %%will generate an histogram of the rating parameters.
            out     = self.getgroup_rating_param;
            counter = 0;            
            for fields = {'amp' 'kappa' 'mu'}
                counter = counter+1;                
                Y   = out.(fields{1});
                x   = linspace(min(Y),max(Y),20);
                c   = histc(Y,x);                
                subplot(1,3,counter)
                bar(x,c,1,'k');
                axis tight;
                box off;
                xlabel('alpha');                
                M = mean(out.(fields{1}));
                S = std(out.(fields{1}))./sqrt(size(M,1));
                hold on;
                plot([M M],ylim,'r');
                hold off;
                title(sprintf('%s: %3.4g ? %3.4g (M?SEM)',fields{1},M,S),'interpreter','none');
            end
        end
        function plot_spacetime(self,varargin)
            ffigure(10);clf;
            baseline = 1;
            zs = 1;
            %%each varargin is one condition x time plot
            Y     = varargin{1};
            name  = varargin{2};
            %            
            tarea = size(Y,4);
            tcol  = 6;
            nplot = 0;
            for narea = 1:tarea
                y      = Y(:,:,:,narea);
                y      = permute(y,[2 1 3 4]);
                if baseline
                   y = y - repmat(mean(y(:,1:5,:),2),[1 size(y,2) 1]);
                end
                if zs
                    y = zscore(y,1,1);
                end
                for ns = 1:size(y,3)
                    ys(:,:,ns) = self.circconv2(y(:,:,ns)');
                end
                ymean = mean(ys,3);%average across subjects;                                
                dp    = ymean(:,4)-ymean(:,8);
                ci    = bootci(1000,@mean,squeeze(diff(ys(:,[8 4],:),1,2))');
                %                
                for ns = 1:size(ys,3)
                    param     = self.fit_spacetime(ys(:,:,ns));                
                    amp(:,ns) = param.fit_results{3}.params(:,1);
                    sd(:,ns)  = param.fit_results{3}.params(:,2);
                end                
                rank                                 = 1:size(ymean,1);
                
                %1
                nplot = nplot+1;
                subplot(tarea,tcol,nplot)             
                imagesc(mean(y,3)');axis xy;                
                title(sprintf('%s-raw',name{narea}),'interpreter','none');
                colorbar
                set(gca,'xticklabel',{'' '' '' 'cs+' '' '' '' 'cs-'},'xtick',1:8,'ytick',5:10:50);
                box off;                
                ylabel('non-shocked microblock');                
                xlabel('faces');
                hold on
                plot(xlim,[4 4],'r')
                ii = self.paradigm{1}.presentation.mblock(self.paradigm{1}.presentation.ucs);
                ii = ii - (1:length(ii));
                plot(8.5,ii,'kp','markersize',4)
                
                %2
                nplot = nplot+1
                subplot(tarea,tcol,nplot)                             
                imagesc(ymean);axis xy
                if narea == 1;
                    title(sprintf('circ.\nsmooth'),'interpreter','none');
                end
                  hold on
                plot(xlim,[4 4],'r')
                ii = self.paradigm{1}.presentation.mblock(self.paradigm{1}.presentation.ucs);
                ii = ii - (1:length(ii));
                plot(8.5,ii,'kp','markersize',4)
                axis off;;colorbar
                
                %3
                nplot = nplot+1;
                subplot(tarea,tcol,nplot)             
                contourf(ymean,4);axis xy;
                if narea == 1;
                title(sprintf('spline'),'interpreter','none');
                end
                  hold on
                plot(xlim,[4 4],'r')
                ii = self.paradigm{1}.presentation.mblock(self.paradigm{1}.presentation.ucs);
                ii = ii - (1:length(ii));
                plot(8.5,ii,'kp','markersize',4)
                axis off;colorbar
                
                
                %4
                nplot = nplot+1;
                subplot(tarea,tcol,nplot)             
                plot(dp,rank,'k','linewidth',2);hold on;                
                hold on
                plot(ci',rank','k--');                
                hold off
                if narea == tarea
                    xlabel('\Delta amplitude');
                end                
                grid on;
                box off;
                if narea == 1;
                title('Differences','interpreter','none');
                end
                ylim([0 max(rank)]);
                
                %5
                nplot = nplot+1;                
                subplot(tarea,tcol,nplot)                             
                plot(mean(amp,2),rank,'k-','linewidth',2);hold on;
                ci    = bootci(1000,@mean,amp');
                plot(ci,rank,'k--');hold off;                
                if narea == tarea
                    xlabel('\alpha');                
                end
                grid on;
                box off;
                if narea == 1;
                title('vM \alpha');
                end
                ylim([0 max(rank)]);                
                %     
                %6
                nplot = nplot+1;                
                subplot(tarea,tcol,nplot)                             
                plot(mean(sd,2),rank,'k-','linewidth',2);hold on;
                ci    = bootci(1000,@mean,sd');
                plot(ci,rank,'k--');hold off;                
                if narea == tarea
                    xlabel('\alpha');                
                end
                grid on;
                box off;
                if narea == 1;
                title('vM \alpha');
                end
                ylim([0 max(rank)]);                
                %     
                drawnow;
            end
            %Ys  = self.circconv2(Y);%smooth
            %Ycs = cumsum(Ys);%./repmat([1:size(Ys,1)]',1,8);            
            %t   = self.fit_spacetime(zscore(Ycs')');
            %%
%             figure;set(gcf,'position',[25 7 831 918]);
%             subplot(2,2,1);imagesc((Ys')');colorbar;axis xy;set(gca,'xtick',[4 8],'xticklabel',{'CS+' 'CS-'});
%             subplot(2,2,2);imagesc((Ycs')');colorbar;axis xy;set(gca,'xtick',[4 8],'xticklabel',{'CS+' 'CS-'});
%             subplot(2,2,3);bar(((t.fit_results{8}.params(:,1))));box off;title('amplitude')
%             subplot(2,2,4);bar(((vM2FWHM(t.fit_results{8}.params(:,2)))));box off;title('fwhm')
        end
        function plot_spacetime2(self,spacetime,type)
            %simple spacetime plots
            plot_ucs = false;
            if nargin < 3
                type = 1;
            end
            a = ffigure;
            tarea = size(spacetime.d,4);
            [yy xx] = GetSubplotNumber(tarea);
            
               %%         
            for narea = 1:tarea;                
                h = subplot(yy,xx,narea);
                if type == 1
                    [d u] = GetColorMapLimits(Vectorize(spacetime.d(:,:,:,narea)),.2);
                    d=0;
                    u=.25;
                    imagesc(Project.circconv2( mean(spacetime.d(:,:,:,narea),3)),[d u]);
                    colorbar;
                    hold on
                    axis xy;
                    plot(xlim,[4 4],'r')
                    plot([4 4],ylim,'--k')                    
                    hold off;
                elseif type == 2                               
                    %%
                    posori = get(h,'position');
                    posori(3) = .2;
                    posori(2) = posori(2) - .05;
                    posori(4) = 0.7;
                    set(h,'position',posori);
                    %
%                     kernel   = make_gaussian2D(11,7,6,2.5,6,4);
                    III      = 1:size(spacetime.d,1);
                    kernel      = make_gaussian2D(3,3,10,10,3,1.5);
                    kernel      = kernel./sum(kernel(:));
                    % smooth single subjects.
                    for ns = 1:size(spacetime.d,3)
                        spacetime.d(:,:,ns,narea) = Project.circconv2(spacetime.d(:,:,ns,narea),kernel);
                    end                                        
                    % average across subjects
                    D           = mean(spacetime.d(III,:,:,narea),3);%data with 2 dimensions                    
                    
                    % plot the average st plot.
                    contourf(D,5,'color','none');
                    box off;
                    %                     contourf(mean(spacetime.d(:,:,:,narea),3),3,'color','none');
                    %                     imagesc(mean(spacetime.d(:,:,:,narea),3));
                    hold on
                    axis xy;
                    plot(xlim,[4 4],'r','color',[1 0 0 .75]);%plot a center line
                    plot([4 4],ylim,'--k','linewidth',1,'color',[0 0 0 .25]);%plot a safe zone line
                    plot([2 2],ylim,'--k','linewidth',1,'color',[0 0 0 .25]);%plot a safe zone line
                    plot([6 6],ylim,'--k','linewidth',1,'color',[0 0 0 .25]);%plot a safe zone line
                    set(gca,'ytick',[10 20 30 40],'yticklabels',{'10' '20' '30' '40'},'xtick',[2 4 6 8],'xticklabels',{sprintf('-90%c',char(176)) 'CS+' sprintf('+90%c',char(176)) sprintf('180%c',char(176))},'XAxisLocation','bottom','YAxisLocation','left','fontsize',16);
                    ylabel('microblocks');
                    %                    
                    h     = colorbar;
                    h.Label.String = ['\muSiemens'];
                    h.FontSize = 14
                    h.Label.FontSize = 14;
                    wcbar = .01;
                    set(gca,'position',posori);
                    h.Position = [posori(1)+posori(3)+wcbar*2 posori(2) wcbar posori(4)/3];
                    h.Box = 'off';
                    
                    %%
                    self.decorate_ucs;
                    
                    %% plot the feargen bar plot
                    pos     = posori+[0 posori(4)+posori(4)*0 0 0];
                    pos(4)  = .15;
                    Dbar    = squeeze(mean(spacetime.d(III,:,:,narea)))';%data with 2 dimensions
                    %average across participants and compute the SEM
                    DbarM   = mean(Dbar);
                    DbarSEM = std(Dbar)./sqrt(length(Dbar));                                        
                    
                    axes('position',pos);
                    cmap  = GetFearGenColors;
                    tbar  = 8;                    
                    for nbar = 1:tbar
                        bar(nbar,DbarM(nbar),1,'facecolor',cmap(nbar,:),'edgecolor','none','facealpha',.8);
                        hold on;
                        errorbar(nbar,DbarM(nbar),DbarSEM(nbar),'ko');
                    end
                    axis tight
                    xlim([.5 8.5])
                    ylim([min(DbarM)*0.9 max(DbarM)*1.1]);
                    set(gca,'ylim',[.04 .07])
                    Publication_NiceTicks(gca,2);
                    set(gca,'fontsize',16)
                    box off;
                    set(gca,'xcolor','w','xtick',[]);                    
                    % fit a Gaussian
                    data = [];
                    data.y   = Dbar';
                    data.x   = repmat(-135:45:180',[size(data.y,2) 1])';
                    data.ids = 1:size(data.y,2);
                    t        = Tuning(data);
                    t.GroupFit(8);
                    plot(linspace(1,8,100),t.groupfit.fit_HD,'k','linewidth',2)                                        
                    
                    %% plot the difference time-course
                    pos = posori+[posori(3)+posori(3)/2 0 0 0];                    
                    axes('position',pos);
                    
                    Dtimecourse = mean(D(III,[3 4 5]),2)-mean(D(:,[7 8 1]),2);
                    data        = squeeze(mean(spacetime.d(III,[3 4 5],:,narea) - spacetime.d(III,[7 8 1],:,narea),2));
                    ci          = bootci(5000,@mean,data')';
                    
                    plot(Dtimecourse,1:length(D),'linewidth',2,'color','k');
                    hold on
                    plot([0 0],ylim,'k--');
                    plot(ci(:,1),1:length(D),'--','linewidth',1,'color','k');
                    plot(ci(:,2),1:length(D),'--','linewidth',1,'color','k');                    
                    box off;                    
                    xticks = get(gca,'XTick');
                    set(gca,'ytick',[],'YColor','w','xtick',xticks(2:end));
                    xlabel('CS+ minus CS-')                    
%                     xlim([-.4 .4]);
                    axis tight;                    
                    plot(xlim,[4 4],'r','color',[1 0 0 .75]);%plot a center line
                    ylim([1,length(D)]);
                    hold off;
                elseif type == 3
                    dummy         = Project.circconv2( mean(spacetime.d(:,:,:,narea),3));
                    [theta,r]     = meshgrid(deg2rad(-135:45:180),linspace(0,1,47));
                    X             = r(:,[1:8 1]).*cos(theta(:,[1:8 1]));
                    Y             = r(:,[1:8 1]).*sin(theta(:,[1:8 1]));
                    contourf(X,Y,dummy(:,[1:8 1]),5,'color','none');
                end 
                                
                if plot_ucs
                    hold on
                        bla                          = self.ucs_vector;
                        bla(find(self.ucs_vector)+1) = 1;
                        bla(self.ucs_vector==1)      = [];
                        bla                          = find(bla);
                        for n = 1:length(bla)
                            h2 = plot(xlim,[bla(n) bla(n)],'k--');
                            h2.Color = [ 0 0 0 .7];
                        end
                        hold off;
                    end
                drawnow;
                title(spacetime.name{narea},'interpreter','none');
            end
        end
        function [coeffs]=RSA_Model(self,spacetime_rsa)
            
            %% get the predictors
            x            = [pi/4:pi/4:2*pi];
            w            = [cos(x);sin(x)];
            model1       = 1-squareform_force(w'*w);%we use squareform_force as the w'*w is not perfectly positive definite matrix due to rounding errors.
            %
            model2_c     = 1-squareform_force(cos(x)'*cos(x));%
            model2_s     = 1-squareform_force(sin(x)'*sin(x));%
            %
            %getcorrmat(amp_circ, amp_gau, amp_const, amp_diag, varargin)
            [cmat]       = getcorrmat(0,3,1,1);%see model_rsa_testgaussian_optimizer
            model3_g     = 1-squareform_force(cmat);%
            % add all this to a TABLE object.
            t            = table(model1(:),model2_c(:),model2_s(:),model3_g(:),'variablenames',{'circle' 'specific' 'unspecific' 'Gaussian' });
            %%
            for nbin = 1:size(spacetime_rsa,1)
                t.y            = spacetime_rsa(nbin,:)';
                dummy          = fitlm(t,'y ~ 1 + unspecific +specific');
                coeffs.ellips(nbin,:) = dummy.Coefficients.Estimate(2:end);
                
                dummy               = fitlm(t,'y ~ 1 + circle');
                coeffs.circ(nbin,:) = dummy.Coefficients.Estimate(2:end);
            end
        end
        
        function [leafOrder]=plot_spacetime_dendrogram(self,spacetime)
            
            figure;
            data             = mean(spacetime.d,3);%take average across subjects;
            s                = size(data);
            data             = reshape(data,[prod(s(1:2)) s(end)]);
            
            corrmat          = corr(data);
            Z                = linkage(data','average','correlation');
            
            tree             = linkage(corrmat,'average','correlation')
            D                = pdist(corrmat,'correlation');
            leafOrder        = optimalleaforder(tree,D);
            [H1,T1,outperm1] = dendrogram(tree,0,'Reorder',leafOrder,'ColorThreshold','default');
            set(gca,'XTickLabel',spacetime.name(leafOrder),'XTickLabelRotation',45,'ticklabelinterpreter','none')
            set(H1,'linewidth',2);
        end                        
        function figure_Draw3D(self,D)

            %%
            winfun = [8];
            data.y           = D;
            data.x           = repmat(linspace(-135,180,8),size(data.y,1),1);
            data.ids         = 1:size(data.y,1);
            t2               = Tuning(data);
            t2.visualization = 1;
            t2.gridsize      = 10;
            t2.SingleSubjectFit(winfun);            
            %%                     
            if 1
                figure(5);clf;
                
                for nfix = 1:size(data.y,1)
                    hold on;
                    X = t2.fit_results{8}.x_HD(1,:);
                    
                    
                        Est    = t2.fit_results{winfun}.params(nfix,:);
                        Est(4) = 0;
                        c = 'k';
                        
                        Y      = t2.fit_results{winfun}.fitfun(X,Est);
                        plot3(X,repmat(nfix,1,size(X,2)),Y,'color',c,'linewidth',1);
                end
            end
            view(43,32)
            ylim([0 size(data.y,1)])
            %            
            [X Y ] = meshgrid(linspace(-135,180,8),1:size(D,1));
            h = contourf(X,Y,D,9,'color','none');
%             h      = surf(X,Y,D);
%             set(h,'FaceColor','texturemap','CData',D,'LineStyle','none')
            hold off;
            %                 DrawPlane(gcf,.4);
            %
            set(gca,'xtick',[-90 0 90 180],'xticklabel',{sprintf('-90%c',char(176)) 'CS+' sprintf('+90%c',char(176)) sprintf('180%c',char(176))},'xgrid','on','ytick',[0 20 40],'ztick',[0 .01 .02],'ygrid','on','color','none','fontsize',16)
            axis tight;
            xlabel('');
            ylabel('microblocks');
            zlabel('\muSiemens')            
        end
        function figure_PostExperimentTests(self,ngroup)
            
            s            = Subject(5);
            X_pmf        = s.fit_pmf.x(1:58);
            X_detection  = -135:45:180;
            out          = s.getgroup_all_param;
            %% select subjects to plot
            %selected      = out.subject_id(abs(out.detection_face) <= 45);%randsample( 5:44,20,1);
            %selected      = out.subject_id(abs(out.rating_mu) <= 45);%randsample( 5:44,20,1);
            for selection = ngroup(:)
                selected      = s.get_selected_subjects(selection).list;
                tit           = sprintf('%s (n = %02d)',s.get_selected_subjects(selection).name,length(selected));
                all_subjects  = 5:44;
                subjects{1}   = selected;%selected subjects.
                if ngroup ~= 0
                    subjects{2}   = setdiff(all_subjects,selected);                                
                end
                    tgroup        = length(subjects);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % average pmf Curve
                figure;
                set(gcf,'position',[83         313        1149         730]);
                clf
                for groups = 1:tgroup;
                    subplot(tgroup,4,1+4*(groups-1))
                    i = subjects{groups};
                    i = ismember(out.subject_id,i);
                    params_csp = nanmean([out.pmf_csp_alpha(i)  out.pmf_csp_beta(i) out.pmf_csp_gamma(i) out.pmf_csp_lamda(i)]);
                    params_csn = nanmean([out.pmf_csn_alpha(i)  out.pmf_csn_beta(i) out.pmf_csn_gamma(i) out.pmf_csn_lamda(i)]);
                    Y_P        = PAL_Weibull(params_csp,X_pmf);
                    Y_N        = PAL_Weibull(params_csn,X_pmf);
                    plot(X_pmf,Y_P,'r',X_pmf,Y_N,'c','linewidth',5);
                    axis square;box off;axis tight;
                    ylabel('p(correct)')
                    xlabel('\Delta Difference')
                    ylim([0 1]);
                    SetTickNumber(gca,5,'y');
                    set(gca,'xtick',[0:45:90],'xticklabel',{'CS+/-' '45'  '90'},'xgrid','on')
                    title(sprintf('Perceptual\nDiscrimination'));
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % polar plot of the detected faces.
                cdata = GetFearGenColors;
                for groups = 1:tgroup;
                    subplot(tgroup,4,1+1+4*(groups-1))
                    i  = subjects{groups};
                    i  = ismember(out.subject_id,i);
                    Y  = out.detection_face(i);
                    Y  = histc(Y,X_detection);
                    Project.plot_bar(-135:45:180,Y);
                    
                end
                subplot(tgroup,4,2);title('Detection');
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % explicit ratings
                R = [];
                for ns = all_subjects
                    s = Subject(ns);
                    R = [R;s.rating.y_mean];
                end
                R = demean(R')';
                for groups = 1:tgroup;
                    subplot(tgroup,4,2+1+4*(groups-1))
                    i = ismember(all_subjects,subjects{groups});
                    Project.plot_bar(-135:45:180,mean(R(i,:)),std(R(i,:))./sqrt(sum(i)))

                    data.y           = R(i,:);
                    data.x           = repmat(linspace(-135,180,8),sum(i),1);
                    data.ids         = 1:sum(i);
                    t2               = Tuning(data);
                    t2.visualization = 0;
                    t2.gridsize      = 10;
                    t2.GroupFit(2);
                    hold on;
                    if t2.groupfit.pval > -log10(0.01)
                        plot(t2.groupfit.x_HD,t2.groupfit.fit_HD,'k','linewidth',3)                    
                    else
                        plot(t2.groupfit.x_HD,repmat(mean2(R(i,:)),1,100),'k','linewidth',3)                    
                    end
                end
                subplot(tgroup,4,3);title('Ratings');
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% saliency
                F = [];
                for ns = all_subjects
                    s = Subject(ns);
                    F = [F; s.get_facecircle(1).count];                    
                end
                F = demean(F')';
                %%
                for groups = 1:tgroup
                    subplot(tgroup,4,3+1+4*(groups-1))
                    i = ismember(all_subjects,subjects{groups});
                    Project.plot_bar(-135:45:180,mean(F(i,:))',std(F(i,:))./sqrt(sum(i)));
                    
                    data.y           = F(i,:);
                    data.x           = repmat(linspace(-135,180,8),sum(i),1);
                    data.ids         = 1:sum(i);
                    t2               = Tuning(data);
                    t2.visualization = 0;
                    t2.gridsize      = 10;
                    t2.GroupFit(3);
                    hold on
                    
                    if t2.groupfit.pval > -log10(0.05)
                        plot(t2.groupfit.x_HD,t2.groupfit.fit_HD,'k','linewidth',3)                    
                    else
                        plot(t2.groupfit.x_HD,repmat(mean2(F(i,:)),1,100),'k','linewidth',3)                    
                    end
                                        
                end
                subplot(tgroup,4,4);supertitle(tit,1,'interpreter','none','fontsize',12);
                drawnow;
%                 SaveFigure(sprintf('/home/onat/Dropbox/selim/Office/Fearamy/FigureCache/%s.png',s.get_selected_subjects(selection).name));
                pause(1);
                %
            end
        end
        function figure_ModelExplanation(self,w)
            %Project().figure_ModelExplanation([0 .6 0 0; 0 .6 .4 0;0  .6 .4 .3])
            %%
            
            for N = 1:size(w,1)
                figure;
                set(gcf,'position',[1921          93        1278         942]);
                %%
                subplot(3,3,[1 4]);
                
                pmod  = self.get_pmodmat(3);
                cbeta = w(N,2:end);
                
                bar(cbeta,.9,'k');
                hold on;
                plot(1:3,cbeta,'or','markersize',10);
                box off;
                hold off;
                grid on
                set(gca,'xticklabel',{'time','tuning' 'time \times tuning' '\sigma' 't x \sigma'},'XTickLabelRotation',45,'fontsize',20,'fontweight','bold','ytick',[0  2],'ylim',[-1 1]);
                
                ylabel(sprintf('Beta Weight'));
                ylim([0 .75]);
                drawnow;
                %%
                subplot(3,3,[2 3 5 6 8 9]);
                hold off
                D = pmod*w(N,:)';
                D = reshape(D,8,65)';
                D = D - min(D(:));
                D = D./max(D(:));
                for nfix =1:10:size(D,1)
                    data.y = D(nfix,:);
                    data.x = -135:45:180;
                    data.ids = 1;                    
                    t        = Tuning(data);
                    t.GroupFit(5);                    
                    plot3(t.groupfit.x_HD,repmat(nfix,1,100),t.groupfit.fit_HD,'color',[0 0 0 .5],'linewidth',3);
                    hold on;
                end
                view(43,32);
                %%
                [X Y ] = meshgrid(linspace(-135,180,8),1:size(D,1));
                h      = contourf(X,Y,D,6,'color','none');
                
                set(gca,'fontsize',16,'xtick',[-90 0 90 180],'xticklabel',{sprintf('-90%c',char(176)) 'CS+' sprintf('+90%c',char(176)) sprintf('\\pm180%c',char(176))},'xgrid','on','ytick',[0 20 40],'ztick',[],'ygrid','on','color','none','fontsize',16,'fontweight','bold','yticklabel',{''})
                axis tight;
                xlabel('');
%                 ylabel('time','Rotation',40);
                zlabel(sprintf('BOLD\nResponse'))
                set(gca,'zlim',[0 1.5]);
                drawnow;
            end
        end
        function T = spacetime_fit(self,st,fun)
            %fits a function to every microblock and subject in the
            %spacetime matrix
            force = 0;
            X = linspace(-135,180,8);
            T = [];
            filename = sprintf('%smidlevel/spacetime_type_%s_fun_%03d.mat',self.path_project,st.name{1},fun);
            if exist(filename) == 0 | force
            %%
            for mbi = 1:size(st.d,1)
                for ns = 1:size(st.d,3)
                    [mbi ns]
                    data.y    = st.d(mbi,:,ns);
                    data.x    = X;
                    data.ids  = ns;
                    t         = Tuning(data);
                    t.SingleSubjectFit(3);
                    dummy     = t.fit_results{3}.table;
                    dummy.mbi = mbi;
                    T = [T;dummy]
                end
            end            
            save(filename,'T')
            else
                load(filename)
            end
            
        end
        function figure_02_scr(self)
            %%
            spacetime    = self.getgroup_scr_spacetime(0,1,0,0);%no baseline no zscore correction, all subjects
            for n = 1:size(spacetime.d,3)
                spacetime.d(:,:,n) = Project.circconv2(spacetime.d(:,:,n),ones(1,3));
            end
            
            mat                     = mean(spacetime.d,3);                         % average across subjects
            x                       = linspace(-135,180,8);                        % x-axis
            mbi                     = 1:length(mat);
            
            spacetime_facecircle    = self.getgroup_behavioral('facecircle');
            spacetime_rating        = self.getgroup_behavioral('rating');
            spacetime_scr           = self.getgroup_behavioral('scr');
            
            tuning_facecircle = Tuning(spacetime_facecircle);tuning_facecircle.GroupFit(self.selected_fitfun);
            tuning_rating     = Tuning(spacetime_rating);tuning_rating.GroupFit(self.selected_fitfun);
            tuning_scr        = Tuning(spacetime_scr);tuning_scr.GroupFit(self.selected_fitfun);                                    
            
            
            T            = self.spacetime_fit(spacetime,self.selected_fitfun);
            A = [];
            for n = 1:47;               
                A(:,n) = T(T.mbi == n,:).amp
            end
            
            t                       = self.getgroup_all_param;
            
            %%
            figure
            set(gcf,'position',[0 0 1000 1000])
            v       = {'PlotBoxAspectRatio',[1 1 1],'DataAspectRatioMode','auto'};
            s       = .04;
            w_small = .12;
            h_small = .12;
            B       = 1-0.15;
            L       = 0.1;
            H(1) = axes('position',[L                   B                                               w_small      h_small]);
            
            H(2) = axes('position',[L                   B-(h_small+s)*3                                 w_small      (h_small)*3+s*2]);            
            H(3) = axes('position',[L+w_small+s         B-(h_small+s)*3                                 w_small      h_small*3+s*2]);
            
            H(4) = axes('position',[L+w_small*2+s*2     B-(h_small+s)*3                                 w_small      h_small]);
            H(5) = axes('position',[L+w_small*2+s*2     B-(h_small+s)*3+(h_small+s)                     w_small      h_small]);
            H(6) = axes('position',[L+w_small*2+s*2     B-(h_small+s)*3+(h_small+s)*2                   w_small      h_small]);
            
            H(7) = axes('position',[L                   B-(h_small+s)*3-(h_small*1.5)-s                 w_small*1.5  h_small*1.5]);
            H(8) = axes('position',[L+w_small*1.5+s*2   B-(h_small+s)*3-(h_small*1.5)-s                 w_small*1.5  h_small*1.5]);

            %%
            axes(H(2))
            imagesc(mat);      
            set(gca,'xtick',[1:8]+.5,'xticklabel',{'' '' '' 'CS+' '' '' '' sprintf('\\pm180%c',char(176))},'XAxisLocation','top','fontsize',12);                                    
%             axis image;
            axis xy;
            pos = plotboxpos(gca)
            ylabel('Micro-block index');            
            self.decorate_ucs;            
            Publication_Ylim(gca,6)
            h             = Publication_addcolorbar(gca);
            h.Location    = 'westoutside'
            h.Position(4) = .1;
            h.Position(3) = h.Position(3)/2;
            h.Position(1) = H(2).Position(1)-.04;
            Publication_Ylim(h,1)
            %             Publication_NiceTicks(gca,2);
            %%
            axes(H(1))                     
            h = Project.plot_bar(x,spacetime_scr.y_mean,spacetime_scr.y_SEM);
            hold on;
            plot(tuning_scr.groupfit.x_HD,tuning_scr.groupfit.fit_HD,'k','linewidth',3);
            hold off
            Publication_RemoveXaxis(gca)
            title('SCR')
            Publication_NiceTicks(gca,1)
            grid on
            set(gca,'xticklabel',[]);
            %%
            axes(H(3))
            %
            P     = squeeze(spacetime.d(:,4,:))';
            N     = squeeze(spacetime.d(:,8,:))';
            M     = P - N;
            S     = std(M)/sqrt(39);
            
            
            M     = A;
            
            X     = 1:size(P,2);            
            h=[];p=[];
            for n = X  
                %[p(n) h(n)] = signtest(M(:,n));
                [h(n) p(n) ] = ttest(M(:,n),[],'tail','right');
                if h(n) == 1
                    barh(n,mean(M(:,n)),1,'facecolor',[.6 .1 .1],'linestyle','none');
                else
                    barh(n,mean(M(:,n)),1,'facecolor',[.5 .5 .5],'linestyle','none');
                end
                hold on
            end
            title('Amplitude')
            set(gca,'yticklabel',[],'ytick',[])
            hold off
            box off
            axis tight;
            Publication_RemoveYaxis(gca)
            Publication_RemoveXaxis(gca)                                    
            %%
            %Publication_NiceTicks(H(5),1)
            axes(H(6))
            h = Project.plot_bar(x,spacetime_facecircle.y_mean,spacetime_facecircle.y_SEM)            
            hold on;
            plot(tuning_facecircle.groupfit.x_HD,tuning_facecircle.groupfit.fit_HD,'k','linewidth',3);
            hold off;
            Publication_RemoveXaxis(H(6))
            Publication_Ylim(gca)
            Publication_NiceTicks(H(6),1)
            title(sprintf('Fixation Count'))
            set(gca,'xticklabel',[]);
            grid on
            %%
            axes(H(5))
            h = Project.plot_bar(x,spacetime_rating.y_mean,spacetime_rating.y_SEM)            
            hold on;
            plot(tuning_rating.groupfit.x_HD,tuning_rating.groupfit.fit_HD,'k','linewidth',3);
            hold off
            Publication_RemoveXaxis(H(5))
            Publication_Ylim(gca)
            Publication_NiceTicks(H(5),1)
            title(sprintf('Ratings'))
            set(gca,'xticklabel',[]);
            grid on
            %%
            axes(H(4))
            c = hist(t.detection_absface,[0 45 90 135 180]);
            bar([0 45 90 135 180],c,'linestyle','none','facecolor',[.5 .5 .5])
            title(sprintf('Detection error'))
            set(gca,'color','none')
            Publication_Ylim(gca)
            Publication_NiceTicks(H(4),2)
            axis tight
            box off
            %%
            axes(H(7))
            x = 'rating_amp';
            y = 'facecircle_amp';
            scatter_stat(t,{'detection_absface' x y})
            xlabel(x);
            ylabel(y);
            title('Detection Error')
            %
            axes(H(8))            
            scatter_stat(t,{'scr_amp',x,y})
            xlabel(x)
            ylabel(y)
            title('SCR amplitude')
            %%
            filename=sprintf('~/gdrive/Office/Fearamy/paperfigures/%s.png','figure_02_scr');
            SaveFigure(filename,'-r400')
            
            
            
        end
        function figure_01(self);
            %%
            
            %%            
            set(gcf,'position',[2412         595        1261         472])
            clf;
            datatype = {'rating' 'scr' 'get_facecircle'};
            titles = {'Rating' 'SCR' 'Saliency'};
            ylabels= {'VAS' sprintf(['Phasic\nSCR (' char(181) 'Siemens)']) sprintf('Fixation\nProbability')};
            for n = 1:3
                subplot(2,6,[n*2-1 n*2]);
                out = self.getgroup_behavioral(datatype{n});
                self.plot_bar(out.x(1,:),out.y_mean,out.y_SEM);
                title(titles{n});
                ylabel(ylabels{n});
                %
                hold on;                
                PlotTransparentLine(out.groupfit.x_HD,out.groupfit.fit_HD(:),.35,'k','linewidth',2.5);
            end
            %%
            t   = self.getgroup_all_param;
            %%
            titels = {'SCR\nTuning' 'Detection\nError'};
            transparency = .8;
            subs = 1:size(t,1);%find(t.pmf_pooled_alpha < 70)';%
            X = t.rating_amp;
            Y = t.facecircle_amp;
            Z = t.scr_amp;
            for n = 1:2
                subplot(2,6,6+[n*3-2 n*3-1 n*3]);
                hold off;
                if n == 1
                    for np = subs
                        h                   = scatter(X(np),(Y(np)),1000,'filled','markerfacealpha',transparency);
                        hold on;
                        h.SizeData          = ((Z(np))-min(Z)+1).^4;
                        h.MarkerFaceColor   = [1-((Z(np))-min(Z))./max(Z-min(Z)) ((Z(np))-min(Z))./max(Z-min(Z)) 0];
                    end
                elseif n == 2
                    for np = subs
                        h = scatter(t.rating_metric_box(np),t.facecircle_metric_box(np),1000,'filled','markerfacealpha',transparency);
                        hold on;
                        h.SizeData  = (((t.detection_absface(np)./180)+1)*5).^3;
                        h.MarkerFaceColor     = [t.detection_absface(np)/180 1-t.detection_absface(np)/180  0];
                    end
                end                                
                title(sprintf(titels{n}));
                xlabel(sprintf('Fear-Tuning\nRating'))
                ylabel(sprintf('Fear-Tuning\nSaliency'))                
                axis tight;box off;axis square;
%                 xlim([-2 2]);
%                 ylim([-2 2]);
                axis tight
                set(gca,'color','none','xtick',[-2:1:2],'ytick',[-2:1:2]);                                                                
                grid on
                drawnow;            
                hold off;
            end            
            %%
            figure(40);
            tits = {'ratings' 'saliency'}
            c = 0;h=[];
            
            for N = {'rating_metric_box' 'facecircle_metric_box'}
                c = c+1;
                [y x] = hist(t.(N{1}));
                h = [h subplot(1,2,c)]
                bar(x,y,.9,'k')
                axis square;
                box off
                ylim([0 10])
                xlim([-2 2])
                xlabel('Generalization Index')
                title(tits{c})
                set(gca,'fontsize',20)
            end            
            Publication_NiceTicks(h,2)                
            %%
            figure(41);clf;
            [y i]  = sort(t.facecircle_metric_box)
            sub_id = t.subject_id(i)
            c = 0;
            h = [];
            for I = 1:8:length(sub_id)
                ns = sub_id(I);
                c  = c+1;
                h  = [h subplot(1,5,c)];
                s  = Subject(ns);
%                 Project.plot_bar(-135:45:180,zscore(s.rating.y_mean))
                Project.plot_bar(-135:45:180,zscore(s.get_facecircle.y_mean));
                axis square;
                box off;
                h(end).XTick = [];
                title(sprintf('GI: %1.1g',y(I)))
            end
            EqualizeSubPlotYlim(h)
        end
        function plot_model_04_predictors(self,base_kappas)
            %%
            for base_kappa = base_kappas(:)'
                old = 0;
                figure;
                X          = (linspace(-135,180,8));
                if ~old
                    deriv      = zscore(Tuning.VonMises(X,1,base_kappa+.05,0,0)-Tuning.VonMises(X,1,base_kappa-.05,0,0));
                    deriv      = deriv - max(deriv);
                else
                    base_kappa   = .1;
                    %create a weight vector for the derivative.
                    res     = 8;
                    x2      = [0:(res-1)]*(360/res)-135;
                    x2      = [x2 - (360/res/2) x2(end)+(360/res/2)];
                    deriv   = -abs(diff(Tuning.VonMises(x2,1,base_kappa,0,0)));
                    deriv   = zscore(deriv);
                end
                vM         = zscore(Tuning.VonMises(X,1,base_kappa,0,0));
                i=0;
                for y = linspace(-12,12,5);
                    for x= linspace(-40,40,5);
                        i=i+1;
                        subplot(5,5,i);
                        plot((x*vM+y*deriv),'ko-','linewidth',3);
                        
                        if i <=5
                            title(sprintf('A: %d',x),'fontsize',20);
                        end
                        grid on;
                        set(gca,'xtick',[2 4 6 8],'xticklabel',{'' 'CS+' '' '180'});
                        if rem(i-1,5)==0
                            ylabel(sprintf('K: %d',y),'fontsize',20,'fontweight','bold');
                        end
                        axis square;
                        axis tight;
                        box off;
                    end;
                end
                EqualizeSubPlotYlim(gcf);
                set(gcf,'position',[680    92   995   949]);
                filename = sprintf('~/gdrive/Office/Fearamy/FigureCache/pmod_%d_old_%d.png',base_kappa*10,old);
                supertitle(filename,1,'interpreter','none');
                SaveFigure(filename,'-r120');
            end
        end
        function decorate_ucs(self)
            plot_ucs = 1;
            if plot_ucs
                hold on
                bla                          = self.ucs_vector;
                bla(find(self.ucs_vector)+1) = 1;
                bla(self.ucs_vector==1)      = [];
                bla                          = find(bla);
                for n = 1:length(bla)
                    h2 = plot(max(xlim),bla(n),'p','markersize',12);
                    h2.Color = [ 1 0.1 0];
                    h2.MarkerFaceColor = [ 1 0.1 0];
                end
                hold off;
            end
        end
    end    
    methods (Static)
        function h           = plot_bar(X,Y,SEM)
            % input vector of 8 faces in Y, angles in X, and SEM. All
            % vectors of 1x8;
            %%
            cmap  = GetFearGenColors;
            tbar  = 8;            
            for i = 1:tbar                
                h(i)    = bar(X(i),Y(i),45,'facecolor',cmap(i,:),'edgecolor','none','facealpha',.8);
                hold on;
            end            
            %%
            hold on;
            if nargin == 3
               errorbar(X,Y,SEM,'ko');%add error bars
            end            
            %%
            %h = gca;            set(h,'xtick',X,'xticklabel',{'' sprintf('-90%c',char(176)) '' 'CS+' '' sprintf('+90%c',char(176)) '' sprintf('\\pm180%c',char(176))});
            h = gca;            set(h,'xtick',X,'xticklabel',{'' '' '' 'CS+' '' '' '' sprintf('\\pm180%c',char(176))});
            box off;
            set(h,'color','none');
            xlim([0 tbar+1])
            drawnow;            
            axis tight;box off;axis square;drawnow;alpha(.5);              
        end
        function Yc          = circconv2(Y,varargin)
            %circularly smoothes data using a 2x2 boxcar kernel;
            
            if nargin == 1
                
                %kernel   = make_gaussian2D(11,7,6,2.5,6,4);                
                %kernel   = kernel./sum(kernel(:));
                
                kernel   = make_gaussian2D(7,5,3,2,4,3);  
                kernel   = kernel./sum(kernel(:));
                
%                 kernel = [kernel ; zeros(size(kernel))];
            elseif nargin == 2
                kernel = varargin{1};
                kernel = kernel./sum(kernel(:));
            end        
            [Yc]= conv2([Y Y Y],kernel,'same');
            Yc  = Yc(:,(size(Yc,2)/3+1):(size(Yc,2)/3+1)+8-1);          

        end
        function [t2]        = fit_spacetime(Y);
            data.y           = Y(:,1:8);
            data.x           = repmat(linspace(-135,180,8),size(data.y,1),1);
            data.ids         = 1:size(data.y,1);
            t2               = Tuning(data);
            t2.visualization = 0;
            t2.gridsize      = 10;
            t2.SingleSubjectFit(3);
%             t2.SingleSubjectFit(7);
%             t2.SingleSubjectFit(3);
        end
        function               RunSPMJob(matlabbatch)
            %will run the spm matlabbatch using the parallel toolbox.
            fprintf('Will call spm_jobman...\n');
           
            for n = 1:length(matlabbatch)
                fprintf('Running SPM jobman %i...\n',n);
                spm_jobman('run', matlabbatch(n));
            end            
        end
        function [data]      = CleanMicroBlocks(data);
            %will remove all the microblocks where there is a transition or
            %oddball trial. the ucs are still here.
                        
            data([Project.mbi_oddball Project.mbi_transition],:,:,:,:,:,:,:,:)   = [];                        
        end
        function [spacetime] = spacetime_preprocess(data,zsc,bc)
            % zscore and baseline correction of spacetime data matrices
                       
            s    = size(data);
            if zsc
                %zscore                
                data = reshape(data,[prod(s(1:2)) s(3:end)]);
                data = zscore(data);
                data = reshape(data,s);
            end
            if bc
                %baseline
                base = repmat(mean(mean(data(1:4,:,:,:)),2),[s(1) s(2) 1 1]);
%                 base = repmat((mean(data(1:4,:,:,:))),[s(1) 1 1 1]);
                data = data - base;
            end
            spacetime = data;
        end
        function [out]       = Linear_Fit(y)
            

            %%
            R         = Project.ucs_vector;%we still need this events to measure the correlation on non-contaminated ST profiles.
            tsample   = size(y,1);
            grid_size = 100;
            x         = -135:45:180;;
            time      = [0 0 0 0 linspace(0,1,tsample-4)];
            slopes    = linspace(-1,1,grid_size);
            stds      = linspace(22.5,180,grid_size);
            viz       = 0;
            %%
            for c1 = 1:length(stds);
                c1
                stdd = stds(c1);
                for n1 = 1:length(slopes);
                    slope  = slopes(n1);
                    alpha  = time*slope;
                    %generate fitted responses.
                    for n = 1:length(y);
                        %                         fit(n,:) = Tuning.VonMises(x,alpha(n),kappa,0,offset);
                        fit(n,:) = demean(Tuning.make_gaussian_fmri_zeromean(x,alpha(n),stdd));
                    end                
                    if viz
                        subplot(1,3,1);imagesc(y(~R,:));colorbar;subplot(1,3,2);imagesc(fit(~R,:));colorbar;subplot(1,3,3);plot(alpha);drawnow;;
                    end
                    r(c1,n1) = corr(Vectorize(fit(~R,:)),Vectorize(y(~R,:)));
                end
            end
            %%                        
            [yp xp]            = find(r == max(r(:)),1);            
            out.learning_rates = slopes;
            out.r              = r;
            out.stds           = stds;            
            out.peak_std       = stds(yp);
            out.peak_lr        = slopes(xp);
            %collect the fit too;            
            slope  = slopes(xp);
            alpha  = time*slope;
            %generate fitted responses.
            for n = 1:length(y);
                %                         fit(n,:) = Tuning.VonMises(x,alpha(n),kappa,0,offset);
                fit(n,:) = demean(Tuning.make_gaussian_fmri_zeromean(x,alpha(n),stdd));
            end
            out.fit            = fit;                        
        end        
        function [out]       = RW_Fit(y,R);
            %let's see if we can understand the amplitude changes using a rescorla
            %wagner model of update of the alpha parameter. to this end I will use the learning rate and
            %initial value as free parameters, so will be the case for Offset and Kappa
            %parameters, I will try all combinations using a brute-force approach and
            %see the best learning rate parameter. The Kappa and Offset parameters are
            %kept constnant over time in this analyis.
            x              = -135:45:180;
            grid_size      = 200;
            kappas         = logspace(-3,1.17,grid_size);
            stds           = linspace(22.5,180,grid_size);
            %alpha is a function of 2 parameters, these two parameters jointly returns
            %a time-course of alpha parameter
            learning_rates = linspace(0,.5,grid_size);
            learning_rates = [-fliplr(learning_rates(2:end)) learning_rates];
            indicator      = Vectorize(repmat([-1 1],grid_size,1))';
            alpha_inits    = 0;
            %% create the fitted data and measure the GOF using r
            clear r;
            viz = 0;
            for c1 = 1:length(stds)%
                fprintf('%03d\n',c1)
                kappa  = kappas(c1);
                stdd   = stds(c1);
                %
                for n1 = 1:length(learning_rates);%learning_rate
                    alpha     = rescorlawagner( R , abs(learning_rates(n1)), Inf ,0);
                    alpha     = alpha*indicator(n1);
                    %generate fitted responses.
                    for n = 1:length(y);
%                        fit(n,:) = Tuning.VonMises(x,alpha(n),kappa,0,offset);
                         fit(n,:) = demean(Tuning.make_gaussian_fmri_zeromean(x,alpha(n),stdd));
                    end
                    %fit = fit + randn(size(fit))*eps;
                    %
                    if viz
                        subplot(1,3,1);imagesc(y(~R,:));colorbar;subplot(1,3,2);imagesc(fit(~R,:));colorbar;subplot(1,3,3);plot(alpha);drawnow;;
                    end
                    r(c1,n1) = corr(Vectorize(fit(:,:)),Vectorize(y(:,:)));
                    if isnan(r(n1));
%                        keyboard
                    end
                end
            end
            [yp xp]            = find(r == max(r(:)));
            out.learning_rates = learning_rates;
            out.r              = r;
            out.stds           = stds;            
            out.peak_std       = stds(yp);
            out.peak_lr        = learning_rates(xp);
            %collect the fit too;            
            alpha     = rescorlawagner( R , abs(out.peak_lr),Inf ,0);
            alpha     = alpha*indicator(xp);
            for n = 1:length(y);
%              fit(n,:) = Tuning.VonMises(x,alpha(n),kappa,0,offset);
               fit(n,:) = Tuning.make_gaussian_fmri_zeromean(x,alpha(n),out.peak_std);
            end                    
            out.fit            = fit;
        end        
        function out         = IsTuned(out,tuning_criterium);
            borders    = Project.borders;
            pval       = Project.pval;
            fun        = Project.selected_fitfun;
            %applies the tuning criterium and returns logical YES or NO
            if tuning_criterium ==1
                if fun == 8;
                    out.params.FearTuning = logical((out.params.LL > -log10(pval))&(out.params.mu > -borders)&(out.params.mu < borders)&(out.params.amp > 0));
                    %                     out.FearTuning = logical((out.LL > -log10(pval)));
                else
                    out.params.FearTuning = logical((out.params.LL > -log10(pval))&(out.params.amp > 0));
                end                
            elseif tuning_criterium == 2
                out.params.FearTuning = logical((out.params.LL > -log10(pval)));                
            end
        end        
        function [out]=extendout(out)
            out.params.metric_box         = mean(out.y([3 4 5])-out.y([1 7 8]));
            out.params.metric_ratio       = out.params.amp/out.params.sigma;
            out.params.metric_dispersion  = out.x.^2*out.y(:).^2;
            Gs                            = abs(out.y)./sum(abs(out.y));
            out.params.metric_entropy     = sum(-Gs.*log(Gs+eps));
        end        
    end
end
