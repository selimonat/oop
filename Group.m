classdef Group < Project
    properties (Hidden,Constant)
        mean_correction = 1;%decides if mean correction should be applied
        align_tunings   = 1;%should ratings be aligned to CS+ face
    end
    properties
        subject
        ids
        pmf
        tunings
        SI        
        sigma_cond
        sigma_test
        SCR_ampl
    end
    
    methods
        %%
        function group = Group(subjects)
            c = 0;
            for s = subjects(:)'
                fprintf('subject: %03d\n',s)
                c                = c+1;
                dummy            = Subject(s);
                group.subject{c} = dummy;
                group.ids        = subjects;
                try
                group.getPMF;
                end
            end
        end
        function csps = getcsp(self)
            csps = [];
            for s = 1:length(self.subject)
                csps = [csps self.subject{s}.csp];
            end
        end        
        %
        function ModelRatings(self,run,funtype)
            %create a tuning object and fits FUNTYPE to it.
            self.tunings.rate{run} = Tuning(self.Ratings(run));%create a tuning object for the RUN for ratings.
            self.tunings.rate{run}.SingleSubjectFit(funtype);%call fit method from the tuning object
        end
        function ModelSCR(self,run,funtype)
            %create a tuning object and fits FUNTYPE to it.
            self.tunings.scr = Tuning(self.getSCRs(run));%create a tuning object for the RUN for SCRS.
            self.tunings.scr.SingleSubjectFit(funtype);%call fit method from the tuning object
        end
        function getSCRtunings(self,run,funtype)
            self.ModelSCR(run,funtype);
            self.SCR_ampl = self.tunings.scr.params(:,1);
        end
        
        function [out] = getSCRmeans(phase)
            for n = 1:length(self.ids)
                    ind = self.subject{n}.scr.findphase(phase);
                    self.subject{n}.scr.cut(ind);
                    self.subject{n}.scr.run_ledalab;
                    out(:,:,n) = self.subject{n}.scr.ledalab.mean(1:800,1:8);
            end
        end
           
        function getSI(self,funtype)
            %fits FUNTYPE to behavioral ratings and computes Sharpening
            %Index.
            self.ModelRatings(3,funtype);
            self.ModelRatings(4,funtype);
            self.sigma_cond = [];
            self.sigma_test = [];
            for s = 1:length(self.subject)
                self.SI         = [self.SI; self.tunings.rate{3}.singlesubject{s}.Est(:,2) - self.tunings.rate{4}.singlesubject{s}.Est(:,2)];%take the diff of sigma parameters.
                self.sigma_cond = [self.sigma_cond; self.tunings.rate{3}.singlesubject{s}.Est(:,2)];
                self.sigma_test = [self.sigma_test; self.tunings.rate{4}.singlesubject{s}.Est(:,2)];
            end
        end
       
        %%
        function getPMF(self)
            c = 0;
            for s = 1:length(self.subject)
                c = c + 1;
                self.pmf.csp_before_alpha(c,1) = self.subject{s}.pmf.params1(1,1);
                self.pmf.csp_after_alpha(c,1)  = self.subject{s}.pmf.params1(3,1);
                self.pmf.csp_before_beta(c,1)  = self.subject{s}.pmf.params1(1,2);
                self.pmf.csp_after_beta(c,1)   = self.subject{s}.pmf.params1(3,2);
                %
                self.pmf.csn_before_alpha(c,1) = self.subject{s}.pmf.params1(2,1);
                self.pmf.csn_after_alpha(c,1)  = self.subject{s}.pmf.params1(4,1);
                self.pmf.csn_before_beta(c,1)  = self.subject{s}.pmf.params1(2,2);
                self.pmf.csn_after_beta(c,1)   = self.subject{s}.pmf.params1(4,2);
            end
        end
       
        function plotPMFbars(self)
            means     = reshape(mean(self.pmf.params1(:,1,:),3),2,2);%compute the mean
            stds      = reshape(std(self.pmf.params1(:,1,:),0,3),2,2);
            sem       = stds/sqrt(length(self.ids));
            
            fig=figure;
            [h,e] = barwitherr(sem,means);
            set(gca,'XTickLabel',{'CS+','CS-'})
            set(e,'LineWidth',1.5)
            set(h(1), 'FaceColor','r')
            set(h(2), 'FaceColor',[143/255 0 0 ])
            ylim([20 80])
            ylabel('threshold \alpha (degrees)')
            legend('before','after','orientation','horizontal','location','southoutside')
        end
        function [out labels] = parameterMat(self)
            labels = {'csp_before_alpha' 'csp_after_alpha' 'csn_before_alpha' 'csn_after_alpha' ...
                      'csp_before_beta' 'csp_after_beta' 'csn_before_beta' 'csn_after_beta' ...                     
                      'csp_improvmt' 'csn_improvmnt' ...
                      'csp_imprvmtn_cted' ...
                      'rating_cond' ... 
                      'rating_test' ... 
                      'SI'...
                      'SCR ampl'};
                  
            out = [self.pmf.csp_before_alpha,...
                   self.pmf.csp_after_alpha,...              
                   self.pmf.csn_before_alpha,...
                   self.pmf.csn_after_alpha,...   
                   self.pmf.csp_before_beta,...
                   self.pmf.csp_after_beta,...              
                   self.pmf.csn_before_beta,...
                   self.pmf.csn_after_beta,... 
                   self.pmf.csp_before_alpha - self.pmf.csp_after_alpha,...
                   self.pmf.csn_before_alpha - self.pmf.csn_after_alpha,...                   
                   (self.pmf.csp_before_alpha-self.pmf.csp_after_alpha)-(self.pmf.csn_before_alpha-self.pmf.csn_after_alpha),...
                   self.sigma_cond,...
                   self.sigma_test,...
                   self.SI,...
                   self.SCR_ampl];
               
               try
               if strcmp(self.tunings.rate{3}.singlesubject{1}.funname,'vonmisses_mobile')
                   
                   for s = 1:size(out,1)
                       out(s,15) = self.tunings.rate{3}.singlesubject{s}.Est(3);
                       out(s,16) = self.tunings.rate{4}.singlesubject{s}.Est(3);
                   end
                   out(:,14) = out(:,13) - out(:,12);
                   labels = [labels(1:14) { 'mu_cond' 'mu_test'}];
               end
               end
        end
        
        function PlotRatingFit(self,subject)
            if ~isempty(self.tunings.rate)
               
                i    =  find(self.ids == subject);
                ave  = mean(reshape(self.tunings.rate{3}.y(i,:),2,8));                                             
                x    = mean(reshape(self.tunings.rate{3}.x(i,:),2,8));
                x_HD = linspace(min(x),max(x),1000);
                h    = figure(100);clf
                subplot(1,2,1)
                title(sprintf('Sub: %i, Likelihood: %03g (p = %5.5g)',subject,self.tunings.rate{3}.singlesubject{i}.Likelihood,self.tunings.rate{3}.singlesubject{i}.pval));
                hold on;               
                plot(x_HD,self.tunings.rate{3}.singlesubject{i}.fitfun(x_HD,self.tunings.rate{3}.singlesubject{i}.Est),'ro','linewidth',3);
                plot(x,ave, 'b','linewidth', 3);
                ylabel('Cond')
                drawnow;
                grid on;
                
                subplot(1,2,2)
                ave  = mean(reshape(self.tunings.rate{4}.y(i,:),2,8));  
                title(sprintf('CSP: %i, Likelihood: %03g (p = %5.5g)',self.subject{i}.csp,self.tunings.rate{4}.singlesubject{i}.Likelihood,self.tunings.rate{4}.singlesubject{i}.pval));
                hold on;
                plot(x_HD,self.tunings.rate{4}.singlesubject{i}.fitfun(x_HD,self.tunings.rate{4}.singlesubject{i}.Est),'ro','linewidth',3);
               
                 plot(x,ave, 'b','linewidth', 3);
                ylabel('Test')
                EqualizeSubPlotYlim(h);               
                drawnow;
                grid on;
            else
                fprintf('No tuning object found here yet...\n');
            end
        end                                
        %%       
        function [rating] = PlotRatings(self,runs)            
            hvfigure;
            trun = length(runs);
            crun = 0;
            for run = runs(:)'%for each run make a subplot column
                crun    = crun + 1;
                %
                subplot(2,trun,crun);                
                rating  = self.Ratings(run);%collect group ratings                
                imagesc(rating.y,[0 10]);thincolorbar('vert');%single subject data
                set(gca,'xticklabel',{'CS+' 'CS-'},'xtick',[4 8],'fontsize',20,'yticklabel',{''});
                colormap hot
                %
                subplot(2,trun,crun+trun);
                [y x] = hist(rating.y);
                y     = y./repmat(sum(y),size(y,1),1)*100;%make it a percentage
                imagesc(rating.x(1,:),x,y,[0 75]);axis xy;
                thincolorbar('vert');
                hold on                
                h     = errorbar(mean(rating.x),mean(rating.y),std(rating.y),'g-');
                axis xy;
                set(gca,'xticklabel',{'CS+' 'CS-'},'xtick',[0 180]);                
                hold off;
            end
        end
        function PlotRatingResults(self)
            %%
            f=figure;
            subplot(1,2,1);
            h = bar(self.tunings.rate{3}.x(1,:),self.tunings.rate{3}.y_mean);SetFearGenBarColors(h);
            hold on;
            errorbar(self.tunings.rate{3}.x(1,:),self.tunings.rate{3}.y_mean,self.tunings.rate{3}.y_std./sqrt(length(self.ids)),'k.');
            xlim([-160 200]);
            box off
            set(gca,'xtick',[0 180],'xticklabel',{'CS+' 'CS-'});
            x = linspace(self.tunings.rate{3}.x(1,1),self.tunings.rate{3}.x(1,end),100);
            plot(x ,  self.tunings.rate{3}.singlesubject{1}.fitfun( x,mean(self.tunings.rate{3}.params(:,1:2))) ,'k--','linewidth',1);
            hold off
            set(gca,'fontsize',14);
            axis square
            t=title('Conditioning');set(t,'FontSize',14);
            %
            subplot(1,2,2);
            h = bar(self.tunings.rate{4}.x(1,:),self.tunings.rate{4}.y_mean);SetFearGenBarColors(h);hold on;
            errorbar(self.tunings.rate{4}.x(1,:),self.tunings.rate{4}.y_mean,self.tunings.rate{4}.y_std./sqrt(length(self.ids)),'k.');
            EqualizeSubPlotYlim(gcf);
            box off
            xlim([-160 200]);
            set(gca,'xtick',[0 180],'xticklabel',{'CS+' 'CS-'});
            x = linspace(self.tunings.rate{4}.x(1,1),self.tunings.rate{4}.x(1,end),100);
            plot(x ,  self.tunings.rate{4}.singlesubject{1}.fitfun( x,mean(self.tunings.rate{4}.params(:,1:2))) ,'k','linewidth',1);
            x = linspace(self.tunings.rate{3}.x(1,1),self.tunings.rate{3}.x(1,end),100);
            plot(x ,  self.tunings.rate{3}.singlesubject{1}.fitfun( x,mean(self.tunings.rate{3}.params(:,1:2))) ,'k--','linewidth',1);
            set(gca,'fontsize',14);
            axis square
            t=title('Test');set(t,'FontSize',14);
            annotation(f,'textbox',[0.78 0.65 0.1 0.1],'String',['SI = ' num2str(mean(self.SI))],'FitBoxToText','off','LineStyle','none');
            hold off
        end
        %%
        function [scr] = getSCRs(self,run)
            %will collect the ratings from single subjects 
            scr.y = [];
            scr.x = [];
            for s = 1:length(self.subject)
                if ~isempty(self.subject{s})
                    dummy = self.subject{s}.GetSubSCR(run);
                    if ~isempty(dummy)
                        scr.y   = [scr.y; dummy.y];
                        scr.x   = [scr.x; dummy.x];
                    end
                end
            end
        end
        function [rating] = Ratings(self,run)
            %will collect the ratings from single subjects 
            rating.y  = [];
            rating.x  = [];
            rating.ids = [];
            c = 0;
            for s = 1:length(self.subject)
                if ~isempty(self.subject{s})
                    dummy = self.subject{s}.GetRating(run,self.align_tunings);
                    if ~isempty(dummy)
                        c = c+1;
                        if self.mean_correction
                            dummy.y_mean = dummy.y_mean-mean(dummy.y_mean);
                            dummy.y      = dummy.y - mean(dummy.y(:));
                        end
                        rating.y   = [rating.y ; dummy.y(:)'];
                        rating.x   = [rating.x ; dummy.x(:)'];
                        rating.ids  = [rating.ids; self.ids(s)];
                    end
                end
            end
        end
        
    end
end
