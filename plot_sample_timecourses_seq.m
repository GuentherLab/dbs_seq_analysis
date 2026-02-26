%%%% plot timecourses of example electrodes highly tuned for a given parameter
% run sort_top_tuned_seq first to create srt table

% load('Y:\DBS\groupanalyses\task-smsl\gotrials\resp_all_subjects_hg_ref-CMR.mat')
% sort_top_tuned_seq(); 
close all

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
% rowlist = [837:845];
% rowlist = [847:852];

% rowlist = [91:96]; 

% rowlist = [127:132];
% rowlist = 269:274;
% rowlist = 263:268;
% rowlist = 269:274;


ylimits = []; % use defaults
% ylimits = [-1 2]; 

xlimits = []; % use defaults
% xlimits = [-2.2 0.5]; 


nplotrows = 3; 

op.plot_go_trials_only = 1; % exclude STOP trials from plotting

% op.sort_cond = []; % plot all trials averaged as a single timecourse without sorting
    op.sort_cond = 'learn_con';
%     op.sort_cond = 'is_nat';
%     op.sort_cond = 'word';
    % op.sort_cond = 'vow';
%     op.sort_cond = 'word_accuracy';
%     op.sort_cond = 'seq_accuracy';

op.condval_inds_to_plot = []; % plot all conditions

%%%%% trial table varname for times used for time-locking responses
% op.time_align_var = 't_prod_on'; % speech onset
op.time_align_var = 't_aud_go_on'; % go beep
% op.time_align_var = 't_vis_syl_on'; % audio stim cue on



op.smooth_timecourses = 1; 
    % op.smooth_method = 'movmean';
    op.smooth_method = 'gaussian';
    op.smooth_windowsize = 30; 

op.leg_pos_adjust = 0.21; % move legend position to the left this much... 0.21 looks good when using 2 columns
op.trace_width = 1; 
op.newfig = 0;
op.plot_raster = 0; 

%%%%%%%%%% if using the options below, make sure all elcs are from same sub or trial times will be incorrect
 % srt = resp_hg_ctar; subind = 1; channame = srt.chan{rowlist(1)}; thissub = srt.sub{rowlist(1)}; % use this option to plot from the non-sorted resp table
 % srt = resp_hg_noref; subind = 1; channame = srt.chan{rowlist(1)}; thissub = srt.sub{rowlist(1)}; % use this option to plot from the non-sorted resp table
 % srt = resp_beta_noref; subind = 1; channame = srt.chan{rowlist(1)}; thissub = srt.sub{rowlist(1)}; % use this option to plot from the non-sorted resp table

%%
nelcs = length(rowlist);

% close all
hfig = figure('WindowState','maximized','Color','w'); box off

for ielc = 1:nelcs
    srt_row_ind = rowlist(ielc) 
    srt_tbl_row = srt(srt_row_ind,:); 

    subind = find(string(subs.sub) == srt_tbl_row.sub{1});
    trials_tmp = subs.trials{subind}; % temporary copy of trials table

    subplot(nplotrows,ceil(nelcs/nplotrows),ielc);
     plot_resp_timecourse_seq(srt_tbl_row,trials_tmp,op); 

    if ~isempty(ylimits)
        ylim(ylimits)
    end
    if ~isempty(xlimits)
        xlim(xlimits)
    end

end

 