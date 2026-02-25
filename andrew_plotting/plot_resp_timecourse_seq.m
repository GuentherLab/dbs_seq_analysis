%%% wrapper for plot_resp_timecourse.m specific to the DBS-SEQ project 
 % load resp_all_subjects and run sort_top_tuned first 

% close all

 %% params 
 
condval_inds_to_plot = []; % plot all vals
% condval_inds_to_plot = [1:6];

vardefault('sort_cond',[]);
%     sort_cond = 'learn_con';
    % sort_cond = 'is_nat';
%     sort_cond = 'word';
    % sort_cond = 'vow';
%     sort_cond = 'word_accuracy';
%     sort_cond = 'seq_accuracy';

plot_go_trials_only = 1; % exclude STOP trials from plotting

vardefault('newfig',1);
vardefault('smooth_timecourses', 1);
vardefault('smooth_method','gaussian');
vardefault('smooth_windowsize',10);
vardefault('ylimits', []); % use defaults
vardefault('xlimits',[]);

%%%%% trial table varname for times used for time-locking responses
vardefault('time_align_var','t_prod_on'); % default to speech onset

%%%% trial times to plot 
% the fixed timepoint will be exact (x=0); for other times, we take the avg relative to the fixed point
    % trial-table-varname, line color, text label, L/R side
times_to_plot = {...    
    't_vis_syl_on', [0 0 1],        {'vis','on'},       'L';... 
    't_aud_syl_on', [0.6 0.4 0.1],  {'aud','on'},       'L';...
    't_aud_syl_off',[0.6 0.4 0.1],  {'aud','off'},      'R';...
    't_aud_go_on',  [0 1 0],        {'GO','beep'}       'L';...
    't_prod_on',    [0.5 0.5 0.5],  {'speech','start'}, 'L';...
    't_prod_off',   [0.5 0.5 0.5],  {'speech','end'},    'R';...
    };


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


%%%%%% end params
%%
times_to_plot = table(times_to_plot(:,1), times_to_plot(:,2), times_to_plot(:,3), times_to_plot(:,4), 'VariableNames', {'varname','color','plot_label','line_side'}); 

if exist('subs','var')
    subind = string(subs.subject) == srt.sub(srt_row);
    trials_tmp = subs.trials{subind}; % temporary copy of trials table
else % if full subtable not available, try using trials table that has already been loaded
    trials_tmp = trials; 
end
trials_tmp.align_time = trials_tmp{:,time_align_var}; 

channame = srt.chan{srt_row}; 
op.sub = srt.sub{srt_row}; 
% srt_row = strcmp(srt.chan,channame) & strcmp(srt.sub,op.sub);
if plot_go_trials_only % exclude stop trials
    go_trial_inds = ~trials_tmp.is_stoptrial;
    trials_tmp = trials_tmp(go_trial_inds,:);
    timecourses_unaligned = srt.timecourse{srt_row}(go_trial_inds); 
elseif ~plot_go_trials_only % include both stop and go trials
    timecourses_unaligned = srt.timecourse{srt_row};
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

    if string(srt.type{srt_row})=="ECOG"
        htitle = title([op.sub, '_', srt.chan{srt_row}, '_area-', srt.HCPMMP1_label_1{srt_row}], 'Interpreter','none');
    else
        htitle = title([op.sub, '_', srt.chan{srt_row}, '_area-', srt.DISTAL_label_1{srt_row}], 'Interpreter','none');
    end




 
%     hyline = yline(0, 'LineWidth',yline_zero_width, 'Color',yline_zero_color, 'LineStyle',yline_zero_style);
    
f=get(gca,'Children');

if ~isempty(sort_cond)
    hleg = legend(flipud(f(end-nvals_to_plot+1:end)),resp_grpd.condval{condval_inds_to_plot});
end
