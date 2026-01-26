 %%%% code to run at the end of multifreq_avg_power
% plot out each frequency that was extracted



channname = 'dbs_L4';
 [~,chind] = find(strcmp(D_eltype.label,channame));

sub = 'DM1037';


trials = bml_annot_read_tsv(['Y:\DBS\derivatives\sub-', sub, '\annot\', ...
    'sub-', sub, '_ses-intraop_task-smsl_annot-produced-syllables.tsv' ]); 

%% plot unaligned timecourses
%  freqind = 1; % freq index
% 
% % trialinds = 1:ntrials; 
% trialinds = 1:1;
% 
% ntrials = length(D_eltype.trial) ; 
% 
%  close all
%  hfig = figure; 
%  hold on
%  for itrial = trialinds
%     hplot(itrial) = plot(D_multifreq_eltype{freqind}.trial{itrial}(chind,:));
%  end
%  hold off

%  trialdurs_sec = cellfun(@length,D_multifreq_eltype{freqind}.trial) ./ D_multifreq_eltype{freqind}.fsample;

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

newfig = 0;
vardefault('smooth_timecourses', 1);
vardefault('smooth_method','gaussian');
vardefault('smooth_windowsize',10);
vardefault('ylimits', []); % use defaults

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
% time_align_var = 'sp_on'; % speech onset
%     xlimits = [-2.2 0.5]; 
time_align_var = 'audio_go_offset'; % speech onset
    xlimits = [-1.5 3.5]; 

    %%

for freqind = 1:nfreqs
    subplot(nfreqs, 1, nfreqs-freqind+1)
    trials_tmp = trials; % temporary copy of trials table
    trials_tmp.times = D_multifreq_eltype{freqind}.time';
    trials_tmp.align_time = trials_tmp{:,time_align_var};
    
    timecourses_chan = cellfun(@(x)x(chind,:),D_multifreq_eltype{freqind}.trial,'UniformOutput',false);
    
    if plot_go_trials_only % exclude stop trials
        go_trial_inds = ~trials_tmp.is_stoptrial;
        trials_tmp = trials_tmp(go_trial_inds,:);
        timecourses_unaligned = timecourses_chan(go_trial_inds); 
    elseif ~plot_go_trials_only % include both stop and go trials
        timecourses_unaligned = timecourses_chan;
    end
    
    % trials_tmp.is_nat = cell(height(trials_tmp),1);
    %     trials_tmp.is_nat(strcmp(trials_tmp.learn_con,'nat')) = {'native'};
    %     trials_tmp.is_nat(~strcmp(trials_tmp.learn_con,'nat')) = {'nonnative'};
    
    if isempty(sort_cond) % plot all trials in a single trace
        trial_conds = ones(height(trials_tmp),1); 
    elseif ~isempty(sort_cond)
        trial_conds = trials_tmp{:,sort_cond}; 
    end
    
    
     %% sort trials by condition, get average responses + error, plot
     hold on
     plot_resp_timecourse()
     title([num2str(wav_freqs(freqind)), ' Hz'])
     xlabel('time (sec)')
     ylabel('power')
end

sgtitle(['sub ', sub, '... chan ', channname, '... aligned to ', time_align_var])
