%%%% plot timecourses of example electrodes highly tuned for a given parameter
% run sort_top_tuned_seq first to create srt table

%% params

rowlist = 1:6;
% rowlist = 7:12; 
% rowlist = 13:18; 
% rowlist = 19:24; 
% rowlist = 25:30; 
% rowlist = 31:36; 
% rowlist = 22:25;
% rowlist = [2 3 4 6 7 8];
% rowlist = [9 10 12 17 21 22];

% % % y_axmax = 1; 

ylimits = []; % use defaults
% ylimits = [-1 2]; 

% xlimits = []; % use defaults
xlimits = [-2.5 1]; 


nplotrows = 2; 

% either plot just timecourses, or timecourses plus brains
plot_brains_on_row2 = 0; 

plot_go_trials_only = 1; % exclude STOP trials from plotting

sort_by_trial_cond = 1; 
%     sort_cond = 'learn_con';
%     sort_cond = 'is_nat';
%     sort_cond = 'word';
    sort_cond = 'vow';
%     sort_cond = 'word_accuracy';
%     sort_cond = 'seq_accuracy';

%% make sorted version of resp table
%%%% find and plot the electrodes which are best tuned for a given parameter

nelcs = length(rowlist);

% close all
hfig = figure('WindowState','maximized');

if ~plot_brains_on_row2
    for ielc = 1:nelcs
        thisrow = rowlist(ielc); 
        subplot(nplotrows,nelcs/nplotrows,ielc);
        srt_row = thisrow;
        plot_resp_timecourse
    
        if ~isempty(ylimits)
            ylim(ylimits)
        end
        if ~isempty(xlimits)
            xlim(xlimits)
        end

    
    end
elseif plot_brains_on_row2
    for ielc = 1:nelcs
        thisrow = rowlist(ielc);
        subplot(2,nelcs,ielc)
        srt_row = thisrow;
        plot_resp_timecourse
    
        if ~isempty(ylimits)
            ylim(ylimits)
        end
        if ~isempty(xlimits)
            xlim(xlimits)
        end

        subplot(2, nelcs, nelcs+ielc)
        plot_sorted_resp_mni_on_ctx

    end    
end
 