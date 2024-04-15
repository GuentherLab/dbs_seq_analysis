 
condval_inds_to_plot = []; % plot all vals
% condval_inds_to_plot = [1:6];

%     sort_cond = 'learn_con';
%     sort_cond = 'is_nat';
%     sort_cond = 'word';
    sort_cond = 'vow';
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

%%

 trials_tmp = subs.trials{subind}; % temporary copy of trials table

if plot_go_trials_only % exclude stop trials
    go_trial_inds = ~trials_tmp.is_stoptrial;
    trials_tmp = trials_tmp(go_trial_inds,:);
    timecourses_unaligned = resp.timecourse{resprow}(go_trial_inds); 
elseif ~plot_go_trials_only % include both stop and go trials
    timecourses_unaligned = resp.timecourse{resprow};
end
trials_tmp = trials_tmp(~cellfun(@isempty, timecourses_unaligned),:);
timecourses_unaligned = timecourses_unaligned(~cellfun(@isempty, timecourses_unaligned));

trials_tmp.is_nat = cell(ntrials,1);
    trials_tmp.is_nat(strcmp(trials_tmp.learn_con,'nat')) = {'native'};
    trials_tmp.is_nat(~strcmp(trials_tmp.learn_con,'nat')) = {'nonnative'};


trial_conds = trials_tmp{:,sort_cond}; 

%%
plot_resp_timecourse()

%%

% times relative to produced syllable 
trials_tmp.stim_syl_on_adj = trials_tmp.t_stim_syl_on - trials_tmp.t_prod_on ; 
trials_tmp.stim_syl_off_adj = trials_tmp.t_stim_syl_off - trials_tmp.t_prod_on ; 
trials_tmp.stim_gobeep_on_adj = trials_tmp.t_stim_gobeep_on - trials_tmp.t_prod_on ; 
trials_tmp.stim_gobeep_off_adj = trials_tmp.t_stim_gobeep_off - trials_tmp.t_prod_on ; 
trials_tmp.t_prod_on_adj = trials_tmp.t_prod_on - trials_tmp.t_prod_on(:,1) ; 
trials_tmp.t_prod_off_adj = trials_tmp.t_prod_off - trials_tmp.t_prod_on(:,1) ; 


    if string(resp.type{resprow})=="ECOG"
        htitle = title([thissub, '_', resp.chan{resprow}, '_area-', resp.HCPMMP1_label_1{resprow}], 'Interpreter','none');
    else
        htitle = title([thissub, '_', resp.chan{resprow}, '_area-', resp.DISTAL_label_1{resprow}], 'Interpreter','none');
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
    

