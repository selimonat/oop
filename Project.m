classdef Project < handle
    % This is the PROJECT object that other objects will
    % be a child of. Here enters all the project specific data (e.g. the
    % subject ids) and methods (for e.g. getting paths from the dicom
    % server).
    %i
    % This branch is mrt/main that is all future branches for new projects
    % should be based on this branch. The CheckConsistency.m file can be
    % used to test the consistency of this branch on a test dataset (the
    % test data set can be found in /common/raw/users/onat/test_project).
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
    %
    
    properties (Hidden, Constant)%adapt these properties for your project
        %All these properties MUST BE CORRECT and adapted to one owns
        %projectpaths
        
        path_project          = '/projects/treatgen/data/';
        path_spm_version      = '/common/apps/spm12-7219/';     %6906   % I renamed this to avoid confusion with path_spm as SPM.mat
        trio_sessions         = {'' '' '' 'PRISMA_19272' '' 'PRISMA_19279'  'PRISMA_19296' 'PRISMA_19293' 'PRISMA_19286' 'PRISMA_19287' 'PRISMA_19292' 'PRISMA_19291' 'PRISMA_19297' 'PRISMA_19318' 'PRISMA_19319' 'PRISMA_19339' '' 'PRISMA_19329' 'PRISMA_19338' 'PRISMA_19335' 'PRISMA_19336' 'PRISMA_19337' 'PRISMA_19334' 'PRISMA_19352' 'PRISMA_19376' 'PRISMA_19361' '' 'PRISMA_19449' 'PRISMA_19391' 'PRISMA_19392' 'PRISMA_19396' 'PRISMA_19411' 'PRISMA_19419' '' 'PRISMA_19427' 'PRISMA_19441' 'PRISMA_19450' '','PRISMA_19467','','PRISMA_19466','PRISMA_19478','PRISMA_19501','PRISMA_19502','PRISMA_19525','PRISMA_19550','','PRISMA_19536','PRISMA_19537'};
        hr_sessions         = {'' '' '' 'PRISMA_19272' '' 'PRISMA_19279'  'PRISMA_19278' 'PRISMA_19293' 'PRISMA_19286' 'PRISMA_19287' 'PRISMA_19292' 'PRISMA_19291' 'PRISMA_19297' 'PRISMA_19318' 'PRISMA_19319' 'PRISMA_19339' '' 'PRISMA_19329' 'PRISMA_19338' 'PRISMA_19335' 'PRISMA_19336' 'PRISMA_19337' 'PRISMA_19334' 'PRISMA_19352' 'PRISMA_19347' 'PRISMA_19361' '' 'PRISMA_19449' 'PRISMA_19391' 'PRISMA_19392' 'PRISMA_19396' 'PRISMA_19411' 'PRISMA_19419' '' 'PRISMA_19427' 'PRISMA_19441' 'PRISMA_19450' '','PRISMA_19467','','PRISMA_19466','PRISMA_19478','PRISMA_19501','PRISMA_19502','PRISMA_19525','PRISMA_19535','','PRISMA_19536','PRISMA_19537'};
        
        dicom_serie_selector  = {'' '' ''  [12:15] '' [12:15]  [7:10]  [12:15] [12:15]  [12:15]  [12:15] [12:15]  [12:15] [12:15] [12:14]  [13:16]  '' [12:15]  [12:15] [12:15] [12 14:16]  [12:15]  [12:15] [22:25]  [7:10]  [12:14 20] ''  [12:15] [12:15] [12:15] [12:15] [12:14 20] [12:15] '' [12:15] [18 19 21 22] [12:15] '' [12:15] '' [12:15] [12:15] [12:15] [12 13 15 16] [13:16] [6:9] '' [12:15] [13:16]};
        %sub                   = [ 1  2  3      4    5     6       7       8       9         10        11    12         13    14       15      16   17   18       19       20        21        22       23     24       25        26     27    28      29      30      31      32         33    34   35         36         37    38    39    40   41     42      43      44            45      46  47    48      49];
        genderinfo            =  [NaN NaN NaN   1    2     2       1       1       1         1         2     2          1      2       2      2     NaN    2       2         2        2         2       2      1        1          2     NaN    1       1       2       2       1          1    NaN   1         2           1    NaN    2   NaN   1      1       1       2             1       1   NaN   2        2];
        ageinfo               =  [NaN NaN NaN   23   27   22      29      26      32        23         19    23        23      24      22     22    NaN    22      25       20       24         21      24    20        22        24     21    21      31      24      24      21         37    18   37         20         22    30    31    24   28     24      24      30            20      30  27    21      22];
        
        %
        %this is necessary to tell matlab which series corresponds to which
        %run (i.e. it doesn't always corresponds to different runs)
        dicom2run             = repmat({[1 2 3 4]},1,length(Project.dicom_serie_selector));%how to distribute TRIO sessiosn to folders.
        data_folders          = {'eye' 'midlevel' 'mrt' 'scr' 'stimulation' 'diary'};%if you need another folder, do it here.
        TR                    = 1.31;
        HParam                = 128;%parameter for high-pass filtering
        surface_wanted        = 0;%do you want CAT12 toolbox to generate surfaces during segmentation (0/1)
        smoothing_factor      = 6;%how many mm images should be smoothened when calling the SmoothVolume method
        atlas2mask_threshold  = 50;%where ROI masks are computed, this threshold is used.
        path_smr              = sprintf('%s%ssmrReader%s',fileparts(which('Project')),filesep,filesep);%path to .SMR importing files in the fancycarp toolbox.
        normalization_method  = 'CAT';%which normalization method to use. possibilities are EPI or CAT
        
        
        selected_fitfun       = 8;%vonmises
        realconds             = -135:45:180;
        faceconds             = [-135:45:180 500];
        allconds              = [-135:45:180 500 3000];
        plotconds             = [-135:45:180 235 280];
        plottitles            = {'Base' 'Cond' 'Test1' 'Test2' 'Test1/2'};
        condnames             = {'' '' '' 'CS+' '' '' '' 'CS-' 'UCS' 't0'};
    end
    properties (Constant,Hidden) %These properties drive from the above, do not directly change them.
        tpm_dir               = sprintf('%stpm/',Project.path_spm_version); %path to the TPM images, needed by segment.
        path_second_level     = sprintf('%sspm/',Project.path_project);%where the second level results has to be stored
        path_groupmeans       = fullfile(Project.path_project,'spm','groupmeans');%where the second level results has to be stored
        path_atlas            = sprintf('%satlas/data.nii',Project.path_project);%the location of the atlas
        current_time          = datestr(now,'hh:mm:ss');
        subject_indices       = find(cellfun(@(x) ~isempty(x),Project.trio_sessions));% will return the index for valid subjects (i.e. where TRIO_SESSIONS is not empty). Useful to setup loop to run across subjects.
    end
    
    methods
        function DU = SanityCheck(self,runs,measure,varargin)
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
        function DicomDownload(self,source,destination)
            % Will download all the dicoms, convert them and merge them to
            % 4D.
            checkdelete = 0; %needs keypress to empty folder if not empty
            
            if ~ismac & ~ispc
                %proceeds with downloading data if we are NOT a mac not PC
                
                fprintf('%s:\n','DicomDownload');
                %downloads data from the dicom dicom server
                if exist(destination) == 0
                    fprintf('The folder %s doesn''t exist yet, will create it...\n',destination)
                    mkdir(destination)
                end
                %% see if there is already rawdata in there.
                files       = cellstr(spm_select('FPListRec',destination,'^fPRISMA'));
                if ~isempty(files)
                    if length(files) ==1 && strcmp(files{:},'')
                        %this is just a readout bug
                    else
                        warning('Found %d file(s) in %s, will remove them first.',size(files,1),destination)
                        if checkdelete
                            disp(files)
                            warning('Really want to delete all these files?')
                            pause
                        end
                        self.EmptyFolder(destination)
                    end
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
        function DicomTo4D(self,destination)
            %A wrapper over conversion and merging functions.
            
            %start with conversion
            self.ConvertDicom(destination);
            %% clean volumes % scanner was still running for windows screen, correct that
            self.CleanVolumes(destination);
            %finally merge 3D stuff to 4D and rename it data.nii.
            self.MergeTo4D(destination);
        end
        function MergeTo4D(self,destination)
            %will create data.nii consisting of all the [f,s]TRIO images
            %merged to 4D. the final name will be called data.nii.
            % merge to 4D
            files       = spm_select('FPListRec',destination,'^[f,s]PRISMA');
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
        function CleanVolumes(self,destination)
            sub = regexp(destination,'(?<=sub)\d+','match');
            sub = str2double(sub{:});
            run = regexp(destination,'(?<=run)\d+','match');
            run = str2double(run{:});
            
            telomerefolder = [destination filesep 'telomere'];
            files       = cellstr(spm_select('FPListRec',destination,'^fPRISMA'));
            
            if ~exist(telomerefolder)
                mkdir(telomerefolder)
            end
            [~,Nvol]   = Subject(sub).get_totalvolumeslogged(run);
            files2move = files(Nvol+1:end);
            fprintf('Moving last %02d files to telomere folder.\n',length(files2move))
            if ~isempty(files2move)
                for f = 1:length(files2move)
                    [success(f)] = movefile(files2move{f},telomerefolder);
                end
                if any(success == 0)
                    fprintf('Moving files to telomere folder didn''t work.\n')
                    keyboard
                end
            end
            files2move = [];
            
            
            dummyfolder = [destination filesep 'dummyscans'];
            if ~exist(dummyfolder)
                mkdir(dummyfolder)
            end
            if run == 3 && sub ==44
                Ndummies = 4;
            else
                Ndummies = 6;
            end
            files2move = files(1:Ndummies);
            fprintf('Moving first %02d files to dummyscan folder.\n',length(files2move))
            for f = 1:length(files2move)
                [success(f)] = movefile(files2move{f},dummyfolder);
            end
            if any(success == 0)
                fprintf('Moving files to dummyscan folder didn''t work.\n')
                keyboard
            end
            files2move = [];
        end
        function ConvertDicom(self,destination)
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
        
        %         function [result]   = dicomserver_request(self)
        %             %will make a normal dicom request. use this to see the state of
        %             %folders
        %             results = [];
        %             if ~ismac & ~ispc
        %                 fprintf('Making a dicom query, sometimes this might take long (so be patient)...(%s)\n',self.current_time);
        %                 [status result]  = system(['/common/apps/bin/dicq --series --exam=' self.trio_session]);
        %                 fprintf('This is what I found for you:\n');
        %             else
        %                 fprintf('To use dicom query you have to use one of the institute''s linux boxes\n');
        %             end
        %
        %         end
        
        function [result]   = dicomserver_request(self)
            %will make a normal dicom request. use this to see the state of
            %folders
            results = [];
            if ~ismac & ~ispc
                fprintf('Making a dicom query, sometimes this might take long (so be patient)...(%s)\n',self.current_time);
                [status result]  = system(['env LD_LIBRARY_PATH= /common/apps/bin/dicq --series --exam=' self.trio_session]);
                
                fprintf('This is what I found for you:\n');
            else
                fprintf('To use dicom query you have to use one of the institute''s linux boxes\n');
            end
        end
        %         function [paths]    = dicomserver_paths(self)
        %             paths = [];
        %             if ~ismac & ~ispc
        %                 fprintf('Making a dicom query, sometimes this might take long (so be patient)...(%s)\n',self.current_time)
        %                 [status paths]   = system(['/common/apps/bin/dicq -t --series --exam=' self.trio_session]);
        %                 paths            = strsplit(paths,'\n');%split paths
        %             else
        %                 fprintf('To use dicom query you have to use one of the institute''s linux boxes\n');
        %             end
        %         end
        function [paths]    = dicomserver_paths(self)
            paths = [];
            if ~ismac & ~ispc
                fprintf('Making a dicom query, sometimes this might take long (so be patient)...(%s)\n',self.current_time)
                [status paths]   = system(['env LD_LIBRARY_PATH= /common/apps/bin/dicq -t --series --exam=' self.trio_session]);
                paths            = strsplit(paths,'\n');%split paths
            else
                fprintf('To use dicom query you have to use one of the institute''s linux boxes\n');
            end
        end
        function [path]     = pathmrfiles(self,run,varargin)
            if isa(self,'Subject')
                sub = self.id;
            else
                sub = 4;
            end
            if nargin < 2
                path = fullfile(self.pathfinder(sub,0),'mrt');
            elseif nargin == 2 % run is given
                path = fullfile(self.pathfinder(sub,run),'mrt');
            else %run and string are given
                filestring = varargin{1};
                path = fullfile(self.pathfinder(sub,run),'mrt',filestring);
                if exist(path,'file')~=2
                    fprintf('File %s doesn''t exist.\n',path)
                    path = [];
                end
            end
        end
        
        function [path]     = pathspmfiles(self,run,model_num,varargin)
            if isa(self,'Subject')
                sub = self.id;
            else
                sub = 001;
            end
            if nargin < 2
                warning('Give run and filestring!')
                path = [];
            elseif nargin == 2 % run is given
                path = sprintf('%sspm%smodel_%02d_chrf_%d%d%s',self.pathfinder(sub,run),filesep,model_num,self.derivatives(1),self.derivatives(2),filesep);
            else %run and string are given
                filestring = varargin{1};
                path = sprintf('%sspm%smodel_%02d_chrf_%d%d%s%s',self.pathfinder(sub,run),filesep,model_num,self.derivatives(1),self.derivatives(2),filesep,filestring);
                if exist(path,'file')~=2
                    fprintf('File %s doesn''t exist.\n',path)
                    path = [];
                end
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
        function CreateFolderHierarchy(self)
            %Creates a folder hiearchy for a project. You must run this
            %first to create an hiearchy and fill this with data.
            for ns = 1:length(self.trio_sessions)
                for nr = 0:length(self.dicom2run{1})
                    for nf = 1:length(self.data_folders)
                        path2subject = sprintf('%s%ssub%03d%srun%03d%s%s',self.path_project,filesep,ns,filesep,nr,filesep,self.data_folders{nf});
                        if ~isempty(self.trio_sessions{ns})
                            a = fullfile(path2subject);
                            a
                            mkdir(a);
                        end
                    end
                end
            end
        end
        function EmptyFolder(self,whichfolder)
            %             dinfo = dir(fullfile(whichfolder,'*.*'));
            %             dinfo = dir(whichfolder);
            %             %get rid of dummy and telomere folder first
            %             subd  = [dinfo(:).isdir];
            %             nameFolds = {dinfo(subd).name}';
            %             nameFolds(ismember(nameFolds,{'.','..'})) = [];
            %             for K = 1:length(nameFolds)
            %                rmdir(fullfile(whichfolder,nameFolds{K}))
            %             end
            %             dinfo(dinfo.isdir) = [];
            
            files = cellstr(spm_select('FPListRec',whichfolder,'*.nii'));
            %then get rid of the files.
            for K = 1 : length(files)
                delete(files{K});
            end
        end
        
        function t          = get.current_time(self)
            t = datestr(now,'hh:mm:ss');
        end
        
        function subs = get_subjects(self,varargin) %might be needed later if there are subj.selection criteria
            if nargin >1
                switch varargin{1}
                    case 1
                        % CS+ vs CS- criterion
                        subs = setdiff(self.subject_indices, [9 20 26 41 49]);
                    case 2
                        % put sth here
                end
            else
                subs = self.subject_indices;
            end
        end
        
    end
    methods(Static) %SPM analysis related methods.
        
        function RunSPMJob(matlabbatch)
            %will run the spm matlabbatch using the parallel toolbox.
            fprintf('Will call spm_jobman...\n');
            
            for n = 1:length(matlabbatch)
                fprintf('Running SPM jobman %i...\n',n);
                spm_jobman('run', matlabbatch(n));
            end
        end
        
        function plot_orthview(filename)
            %will plot the volume using spm_image;
            global st
            spm_image('init',filename)
            spm_clf;
            spm_orthviews('Image',filename)
            %             spm_image('display',filename)
            spm_orthviews('AddColourBar',h(1),1);
            spm_orthviews('AddContext',h(1));
        end
        
    end
    methods %methods that does something on all subjects one by one
        function VolumeGroupAverage(self,run,selector)
            %Averages all IMAGES across all subjects. This can only be done
            %on normalized images. The result will be saved to the
            %project/midlevel/. The string SELECTOR is appended to the
            %folder RUN.
            %
            %For example to take avarage skullstripped image use: RUN = 0,
            %SELECTOR = 'mrt/w_ss_data.nii' (which is the normalized skullstripped
            %image). This method will go through all subjects and compute an average skull stripped image.
            
            %so far not functioanl
            files = [];
            for ns = self.subject_indices
                s     = Subject(ns);
                current = sprintf('%s%s%s',s.path_data(run),filesep,selector);
                if exist(current) ~= 0
                    files = [files ; current];
                else
                    keyboard;%for sanity checks
                end
            end
            v           = spm_vol(files);%volume handles
            V           = mean(spm_read_vols(v),4);%data
            target_path = regexprep(files(1,:),'sub[0-9][0-9][0-9]','midlevel');%target filename
            dummy       = v(1);
            dummy.fname = target_path;
            mkdir(fileparts(target_path));
            spm_write_vol(dummy,V);
        end
        function VolumeSmooth(self,files)
            %will smooth the files by the factor defined as Project
            %property.
            matlabbatch{1}.spm.spatial.smooth.data   = cellstr(files);
            matlabbatch{1}.spm.spatial.smooth.fwhm   = repmat(self.smoothing_factor,[1 3]);
            matlabbatch{1}.spm.spatial.smooth.dtype  = 0;
            matlabbatch{1}.spm.spatial.smooth.im     = 0;
            matlabbatch{1}.spm.spatial.smooth.prefix = sprintf('s%d_',self.smoothing_factor);
            spm_jobman('run', matlabbatch);
        end
        function SecondLevel_ANOVA(self,run,model,beta_image_index)
            % This method runs a second level analysis for a model defined in MODEL using beta images indexed in BETA_IMAGE_INDEX.
            
            %store all the beta_images in a 3D array
            beta_files = [];
            for ns = self.subject_indices
                s        = Subject(ns);
                beta_files = cat(3,beta_files,self.beta_path(run,model,'s_w_')');%2nd level only makes sense with smoothened and normalized images, thus prefix s_w_
            end
            %
            c = 0;
            for ind = beta_image_index;
                %take single beta_images across all subjects and store them
                %in a cell
                c = c +1;
                files                                                              = squeeze(beta_files(:,ind,:))';
                matlabbatch{1}.spm.stats.factorial_design.des.anova.icell(c).scans = cellstr(files);
            end
            %
            spm_dir                                                          = regexprep(s.spmmat_dir(1,1),'sub...','second_level');%convert to second-level path
            matlabbatch{1}.spm.stats.factorial_design.dir                    = cellstr(spm_dir);
            matlabbatch{1}.spm.stats.factorial_design.des.anova.dept         = 0;
            matlabbatch{1}.spm.stats.factorial_design.des.anova.variance     = 1;
            matlabbatch{1}.spm.stats.factorial_design.des.anova.gmsca        = 0;
            matlabbatch{1}.spm.stats.factorial_design.des.anova.ancova       = 0;
            matlabbatch{1}.spm.stats.factorial_design.cov                    = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
            matlabbatch{1}.spm.stats.factorial_design.multi_cov              = struct('files', {}, 'iCFI', {}, 'iCC', {});
            matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none     = 1;
            matlabbatch{1}.spm.stats.factorial_design.masking.im             = 1;
            matlabbatch{1}.spm.stats.factorial_design.masking.em             = {''};
            matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit         = 1;
            matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
            matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm        = 1;
            %
            matlabbatch{2}.spm.stats.fmri_est.spmmat                         = {[spm_dir '/SPM.mat']};
            matlabbatch{2}.spm.stats.fmri_est.method.Classical               =  1;
            %
            spm_jobman('run', matlabbatch);
        end
    end
    methods (Static) %other methods that might be needed (LK made)
        function CheckReg(files)
            matlabbatch = [];
            if isa(files,'char')
                files = cellstr(files);
            end
            matlabbatch{1}.spm.util.checkreg.data = files;
            spm_jobman('run', matlabbatch);
        end
        function plot_bar(X,Y,SEM)
            % input vector of 8 faces in Y, angles in X, and SEM. All
            % vectors of 1x8;
            %%
            
            condnames             = {'' '' '' 'CS+' '' '' '' 'CS-' 'UCS' 't0'};
            cmap  = GetFearGenColors;
            tbar  = length(Y);
            for i = 1:tbar
                try
                    h(i)    = bar(X(i),Y(i),40,'facecolor',cmap(i,:),'edgecolor','none','facealpha',.8);
                catch
                    h(i)    = bar(X(i),Y(i),40,'facecolor',cmap(i,:),'edgecolor','none');
                end
                hold on;
            end
            %%
            hold on;
            if nargin == 3
                errorbar(X,Y,SEM,'k.','LineWidth',2);%add error bars
            end
            
            %%
            set(gca,'xtick',X,'xticklabel',condnames(1:tbar));
            box off;
            set(gca,'color','none');
            drawnow;
            axis tight;box off;axis square;drawnow;alpha(.5);
            xlim([min(X)-mean(diff(X)) max(X)+mean(diff(X))])
            
        end
    end
end
