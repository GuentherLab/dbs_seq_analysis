 %%%% code to run at the end of multifreq_avg_power
% plot out each frequency that was extracted



 [~,chind] = find(strcmp(D_eltype.label,'dbs_L1'));

sub = 'DM1037';
 freqind = 1; % freq index

ntrials = length(D_eltype.trial) ; 

% trialinds = 1:ntrials; 
trialinds = 1:1;

 trialdurs_sec = cellfun(@length,D_multifreq_eltype{freqind}.trial) ./ D_multifreq_eltype{freqind}.fsample;

trials = bml_annot_read_tsv(['Y:\DBS\derivatives\sub-DM', sub, '\annot\', ...
    'sub-DM', sub, '_ses-intraop_task-smsl_annot-produced-syllables.tsv' ]); 

%% plot unaligned timecourses
%  close all
%  hfig = figure; 
%  hold on
%  for itrial = trialinds
%     hplot(itrial) = plot(D_multifreq_eltype{freqind}.trial{itrial}(chind,:));
%  end
%  hold off

%% plot aligned timecourses

condval_inds_to_plot = []; % plot all vals
% condval_inds_to_plot = [1:6];

vardefault('sort_cond',[])
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
vardefault('xlimits',[-2.2 0.5]);

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
time_align_var = 'sp_on'; % speech onset

%%

trials_tmp = trials; % temporary copy of trials table
trials_tmp.times = plot(D_multifreq_eltype{freqind}.
trials_tmp.align_time = trials_tmp{:,time_align_var};

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

