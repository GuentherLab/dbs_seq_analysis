%%%% plot timecourses of example electrodes highly tuned for a given parameter
% run sort_top_tuned_seq first to create srt table

%% params

% rowlist = 1; 
rowlist = 1:6;
% rowlist = 7:12; 
% rowlist = 13:18; 
% rowlist = 19:24; 
% rowlist = 25:30; 
% rowlist = 31:36; 
% rowlist = 22:25;
% rowlist = [2 3 4 6 7 8];
% rowlist = [9 10 12 17 21 22];
% rowlist = [1 7 13 19 25 31];
% rowlist = [ 1 2 3 4 5 8]; 

% rowlist = [91:96]; 

% rowlist = [127:132];
% rowlist = 269:274;
% rowlist = 263:268;
% rowlist = 269:274;

%%%%%%%%%% if using the options below, make sure all elcs are from same sub or trial times will be incorrect
 % srt = resp_hg_ctar; subind = 1; channame = srt.chan{rowlist(1)}; thissub = srt.sub{rowlist(1)}; % use this option to plot from the non-sorted resp table
 % srt = resp_hg_noref; subind = 1; channame = srt.chan{rowlist(1)}; thissub = srt.sub{rowlist(1)}; % use this option to plot from the non-sorted resp table
 % srt = resp_beta_noref; subind = 1; channame = srt.chan{rowlist(1)}; thissub = srt.sub{rowlist(1)}; % use this option to plot from the non-sorted resp table


% % % y_axmax = 1; 

ylimits = []; % use defaults
% ylimits = [-1 2]; 

% xlimits = []; % use defaults
xlimits = [-2.2 0.5]; 


nplotrows = 3; 

% either plot just timecourses, or timecourses plus brains
plot_brains_on_row2 = 0; 

plot_go_trials_only = 1; % exclude STOP trials from plotting

% sort_cond = []; % plot all trials averaged as a single timecourse without sorting
    sort_cond = 'learn_con';
%     sort_cond = 'is_nat';
%     sort_cond = 'word';
    % sort_cond = 'vow';
%     sort_cond = 'word_accuracy';
%     sort_cond = 'seq_accuracy';

newfig = 0;

smooth_timecourses = 1; 
    % smooth_method = 'movmean';
    smooth_method = 'gaussian';
    smooth_windowsize = 10; 

plotops.linewidth = 1; 

%%
nelcs = length(rowlist);

% close all
hfig = figure('WindowState','maximized');

if ~plot_brains_on_row2
    for ielc = 1:nelcs
        srt_row = rowlist(ielc) 
        subplot(nplotrows,nelcs/nplotrows,ielc);

        plot_resp_timecourse_seq
    
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
        plot_resp_timecourse_seq
    
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
 