%%% wrapper for plot_resp_timecourse.m specific to the DBS-SEQ project 
 % load resp_all_subjects (including variables resp, subs, and op) and run sort_top_tuned first 

close all

 %% params 
% srt_row = 34;

vardefault('smooth_timecourses',1); 
    vardefault('smooth_windowsize',20); 
%      vardefault('smooth_method', 'movmean'; 
     vardefault('smooth_method','gaussian');
show_error_bars = 0; 
vardefault('newfig',1); 

condval_inds_to_plot = []; % plot all vals
% condval_inds_to_plot = [1:6];

vardefault('plotop',struct);
field_default('plotop','x_ax_hardlims',[]); % widest allowable x limits

field_default('plotop','y_ax_hardlims',[]); % widest allowable y limits

field_default('plotop','linewidth',2); 


% sort_cond = ''; 
%     sort_cond = 'learn_con';
    sort_cond = 'is_nat';
%     sort_cond = 'word';
%     sort_cond = 'vow';
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

cmapname = 'jet'; 

%%


%% set up trials table for alignment
channame = srt.chan{srt_row};
op.sub = srt.sub{srt_row};

subrow = find(subs.subject == string(op.sub));
trials_tmp = subs.trials{subrow}; 
trials_tmp.align_time = trials_tmp{:,time_align_var}; 
trials_tmp.is_nat = cell(height(trials_tmp),1);
    trials_tmp.is_nat(strcmp(trials_tmp.learn_con,'nat')) = {'native'};
    trials_tmp.is_nat(~strcmp(trials_tmp.learn_con,'nat')) = {'nonnative'};

resprow = strcmp(resp.chan,channame) & strcmp(resp.sub,op.sub);
if isempty(sort_cond)
    trial_conds = ones(ntrials,1); 
elseif ~isempty(sort_cond)
    trial_conds = trials_tmp{:,sort_cond}; 
end
timecourses_unaligned = [table(trial_conds, resp.timecourse{resprow}, 'VariableNames', {'cond','timecourse'}), trials_tmp] ; 
    clear trial_conds trials_tmp

if plot_go_trials_only % exclude stop trials
    go_trial_inds = ~timecourses_unaligned.is_stoptrial;
    timecourses_unaligned = timecourses_unaligned(go_trial_inds,:);
end






 %% sort trials by condition, get average responses + error, plot
 plot_resp_timecourse()

%%

% times relative to produced syllable 
timecourses_unaligned.stim_syl_on_adj = timecourses_unaligned.t_stim_syl_on - timecourses_unaligned.t_prod_on ; 
timecourses_unaligned.stim_syl_off_adj = timecourses_unaligned.t_stim_syl_off - timecourses_unaligned.t_prod_on ; 
timecourses_unaligned.stim_gobeep_on_adj = timecourses_unaligned.t_stim_gobeep_on - timecourses_unaligned.t_prod_on ; 
timecourses_unaligned.stim_gobeep_off_adj = timecourses_unaligned.t_stim_gobeep_off - timecourses_unaligned.t_prod_on ; 
timecourses_unaligned.t_prod_on_adj = timecourses_unaligned.t_prod_on - timecourses_unaligned.t_prod_on(:,1) ; 
timecourses_unaligned.t_prod_off_adj = timecourses_unaligned.t_prod_off - timecourses_unaligned.t_prod_on(:,1) ; 


    if string(resp.type{resprow})=="ECOG"
        htitle = title([thissub, '_', resp.chan{resprow}, '_area-', resp.HCPMMP1_label_1{resprow}], 'Interpreter','none');
    else
        htitle = title([thissub, '_', resp.chan{resprow}, '_area-', resp.DISTAL_label_1{resprow}], 'Interpreter','none');
    end

    % stim syllable onsets
    h_stim_syl_on = xline(xline_fn(timecourses_unaligned.stim_syl_on_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style, 'HandleVisibility','off');


%     stim offset
    h_stim_gobeep_off = xline(mean(timecourses_unaligned.stim_gobeep_off_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_gobeep_off, 'LineStyle',xline_style, 'HandleVisibility','off');

   
% % %     % produced syllable onset
    h_t_prod_on = xline(0, 'LineWidth',xline_width, 'Color',xline_color_prod_on, 'LineStyle',xline_style, 'HandleVisibility','off'); 

   % % %     % produced syllable offset 
    h_stim_prod_off = xline(mean(timecourses_unaligned.t_prod_off_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_off, 'LineStyle',xline_style, 'HandleVisibility','off');


 
%     hyline = yline(0, 'LineWidth',yline_zero_width, 'Color',yline_zero_color, 'LineStyle',yline_zero_style);
    

