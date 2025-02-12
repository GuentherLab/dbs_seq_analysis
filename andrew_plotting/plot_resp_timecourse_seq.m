%%% wrapper for plot_resp_timecourse.m specific to the DBS-SEQ project 
 % load resp_all_subjects and run sort_top_tuned first 

% close all

 %% params 
 
condval_inds_to_plot = []; % plot all vals
% condval_inds_to_plot = [1:6];


%     sort_cond = 'learn_con';
    % sort_cond = 'is_nat';
%     sort_cond = 'word';
    % sort_cond = 'vow';
%     sort_cond = 'word_accuracy';
%     sort_cond = 'seq_accuracy';

plot_go_trials_only = 1; % exclude STOP trials from plotting

xline_color_stim_syl_on = [0.6 0.4 0.1];
xline_color_stim_gobeep_on = [0.0 1 0.0];
xline_color_stim_gobeep_off = [0.0 1 0.0];
xline_color_prod_on = [0.5 0.5 0.5];
xline_color_prod_off = [0.5 0.5 0.5];
xline_style = '--';
xline_width = 0.25; 

%%%%% method for finding time landmarks from trial times
xline_fn = @mean; 
% xline_fn = @median;

yline_zero_width = 0.25; 
yline_zero_color = [0.8 0.8 0.8]; 
yline_zero_style = '-';

%%%% how to find the time length that trials will be cut/padded to be
trial_time_adj_method = 'median_plus_sd'; % median plus stdev
% trial_time_adj_method = 'median';
% trial_time_adj_method = 'max';

%%%%% trial table varname for times used for time-locking responses
time_align_var = 't_prod_on'; % speech onset

%%

subind = string(subs.subject) == srt.sub(srtrow);
trials_tmp = subs.trials{subind}; % temporary copy of trials table
trials_tmp.align_time = trials_tmp{:,time_align_var}; 

channame = srt.chan{srtrow}; 
% srtrow = strcmp(srt.chan,channame) & strcmp(srt.sub,thissub);
if plot_go_trials_only % exclude stop trials
    go_trial_inds = ~trials_tmp.is_stoptrial;
    trials_tmp = trials_tmp(go_trial_inds,:);
    timecourses_unaligned = srt.timecourse{srt_row}(go_trial_inds); 
elseif ~plot_go_trials_only % include both stop and go trials
    timecourses_unaligned = srt.timecourse{srtrow};
end

trials_tmp.is_nat = cell(height(trials_tmp),1);
    trials_tmp.is_nat(strcmp(trials_tmp.learn_con,'nat')) = {'native'};
    trials_tmp.is_nat(~strcmp(trials_tmp.learn_con,'nat')) = {'nonnative'};

if isempty(sort_cond) % plot all trials in a single trace
    trial_conds = ones(height(trials_tmp),1); 
elseif ~isempty(sort_cond)
    trial_conds = trials_tmp{:,sort_cond}; 
end


 %% sort trials by condition, get average responses + error, plot
 plot_resp_timecourse()

%%

% times relative to produced syllable 
trials_tmp.stim_syl_on_adj = trials_tmp.t_stim_syl_on - trials_tmp.t_prod_on ; 
trials_tmp.stim_syl_off_adj = trials_tmp.t_stim_syl_off - trials_tmp.t_prod_on ; 
trials_tmp.stim_gobeep_on_adj = trials_tmp.t_stim_gobeep_on - trials_tmp.t_prod_on ; 
trials_tmp.stim_gobeep_off_adj = trials_tmp.t_stim_gobeep_off - trials_tmp.t_prod_on ; 
trials_tmp.t_prod_on_adj = trials_tmp.t_prod_on - trials_tmp.t_prod_on(:,1) ; 
trials_tmp.t_prod_off_adj = trials_tmp.t_prod_off - trials_tmp.t_prod_on(:,1) ; 


    if string(srt.type{srtrow})=="ECOG"
        htitle = title([thissub, '_', srt.chan{srtrow}, '_area-', srt.HCPMMP1_label_1{srtrow}], 'Interpreter','none');
    else
        htitle = title([thissub, '_', srt.chan{srtrow}, '_area-', srt.DISTAL_label_1{srtrow}], 'Interpreter','none');
    end

    % stim syllable onsets
    h_stim_syl_on = xline(xline_fn(trials_tmp.stim_syl_on_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style);


%     stim offset
    h_stim_gobeep_off = xline(mean(trials_tmp.stim_gobeep_off_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_gobeep_off, 'LineStyle',xline_style);

   
% % %     % produced syllable onset
    h_t_prod_on = xline(0, 'LineWidth',xline_width, 'Color',xline_color_prod_on, 'LineStyle',xline_style); 

   % % %     % produced syllable offset 
    h_stim_prod_off = xline(mean(trials_tmp.t_prod_off_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_off, 'LineStyle',xline_style);


 
%     hyline = yline(0, 'LineWidth',yline_zero_width, 'Color',yline_zero_color, 'LineStyle',yline_zero_style);
    

