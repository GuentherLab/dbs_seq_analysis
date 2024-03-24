%%%% plot timecourses of example electrodes highly tuned for a given parameter
% run sort_top_tuned_seq first to create srt table

rowlist = 1:6;
% rowlist = [1 2 3 4 5 7];
% rowlist = 7:12; 
% rowlist = 18:25; 
% rowlist = 18:21; 
% rowlist = 22:25;
% rowlist = [2 3 4 6 7 8];
% rowlist = [9 10 12 17 21 22];

% % % y_axmax = 1; 
ylimits = [-1 2]; 
xlimits = [-2.5 1]; 

nplotrows = 2; 

% either plot just timecourses, or timecourses plus brains
plot_brains_on_row2 = 0; 


%% make sorted version of resp table
%%%% find and plot the electrodes which are best tuned for a given parameter

plot_go_trials_only = 0; % exclude STOP trials from plotting



%%

nelcs = length(rowlist);

close all
hfig = figure('WindowState','maximized');

if ~plot_brains_on_row2
    for ielc = 1:nelcs
        thisrow = rowlist(ielc); 
        subplot(nplotrows,nelcs/nplotrows,ielc);
        srt_row = thisrow;
        plot_resp_timecourse
    
% % %         ylimdefault = ylim;
% % %         ylim([ylimdefault(1), min(y_axmax,ylimdefault(2))])

        ylim(ylimits)
        xlim(xlimits)

    
    end
elseif plot_brains_on_row2
    for ielc = 1:nelcs
        thisrow = rowlist(ielc);
        subplot(2,nelcs,ielc)
        srt_row = thisrow;
        plot_resp_timecourse
    
% % %         ylimdefault = ylim;
% % %         ylim([ylimdefault(1), min(y_axmax,ylimdefault(2))])
        ylim(ylimits)
        xlim(xlimits)

        subplot(2, nelcs, nelcs+ielc)
        plot_sorted_resp_mni_on_ctx

    end    
end
 