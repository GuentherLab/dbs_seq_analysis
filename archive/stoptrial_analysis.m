% get responses from each electrode on each stop trial 
plot_rowcol = [2 4]; 
pre_post_buz_window = [2 2]; 

% copy info from annot_trials if necessary
if all(~strcmp(trials_stop.Properties.VariableNames, 'audio_stop_onset')) % trials_stop is missing data
    [~, stoptrial_rows] = intersect(annot_trials.id, trials_stop.trial_id);
    annot_stoptrials = annot_trials(stoptrial_rows, :);
    annot_stoptrials.audio_stop_onset = cellfun(@str2num,annot_stoptrials.audio_stop_onset);
    annot_stoptrials.audio_stop_offset = cellfun(@str2num,annot_stoptrials.audio_stop_offset);
    trials_stop = [trials_stop, annot_stoptrials(:,{'audio_stop_onset', 'audio_stop_offset'})];
end

n_stop_trials = height(trials_stop);
n_dbs_elcs = height(el_dbs); % number of DBS electrodes to analyze
trials_stop.resp_stim = cell(n_stop_trials, n_dbs_elcs); % high gamma responses aligned to visual stim
trials_stop.resp_buz = cell(n_stop_trials, n_dbs_elcs); % high gamma responses aligned to STOP buzzer
trials_stop.buz_post_vis_go = trials_stop.audio_stop_onset - trials_stop.visual_onset; 

% get recorded time between GO cue onset and STOP buzzer onset
trials_stop.buz_post_vis_go = trials_stop.audio_stop_onset - trials_stop.visual_onset; 
 

 for itrial = 1:n_stop_trials
     trialstart_stim = trials_stop.visual_onset(itrial);
     trialstop_stim = trials_stop.keypress_time(itrial); 
     timepoints_thistrial_stim = find(D_hg_dbs.time{1} > trialstart_stim & D_hg_dbs.time{1} < trialstop_stim); 
     trialstart_buz = trials_stop.audio_stop_onset(itrial) - pre_post_buz_window(1); 
     trialstop_buz = trials_stop.audio_stop_onset(itrial) + pre_post_buz_window(2);      
     timepoints_thistrial_buz = find(D_hg_dbs.time{1} > trialstart_buz & D_hg_dbs.time{1} < trialstop_buz); 
     for ichan = 1:n_dbs_elcs
        trials_stop.resp_stim{itrial,ichan} = D_hg_dbs.trial{1}(ichan, timepoints_thistrial_stim);
        trials_stop.resp_buz{itrial,ichan} = D_hg_dbs.trial{1}(ichan, timepoints_thistrial_buz);
     end
 end
 
 %% pad with NaNs to make trials the same length, then get channel mean timecourses
min_trial_length_stimaligned = min(cellfun(@length, trials_stop.resp_stim(:,1)));
max_trial_length_stimaligned = max(cellfun(@length, trials_stop.resp_stim(:,1)));
 for itrial = 1:n_stop_trials
     thistrial_length = length(trials_stop.resp_stim{itrial,1}); 
     pad_nans = NaN(1, max_trial_length_stimaligned - thistrial_length); 
     for ichan = 1:n_dbs_elcs
        trials_stop.resp_stim{itrial,ichan} = [trials_stop.resp_stim{itrial,ichan}, pad_nans];
        trials_stop.resp_buz{itrial,ichan} = [trials_stop.resp_stim{itrial,ichan}, pad_nans];
     end
 end

% channel means
chanmean_stim = NaN(n_dbs_elcs, max_trial_length_stimaligned); 
 for ichan = 1:n_dbs_elcs
    chanmean_stim(ichan,:) = mean(cell2mat(trials_stop.resp_stim(:,ichan)), 1); 
 end

  not_completed_trials = ~[trials_stop.stop_response==3];
chanmean_buz = NaN(n_dbs_elcs, length(trials_stop.resp_buz{1,1})); 
chanmean_buz_not_completed = NaN(n_dbs_elcs, length(trials_stop.resp_buz{1,1}));
 for ichan = 1:n_dbs_elcs
    chanmean_buz(ichan,:) = mean(cell2mat(trials_stop.resp_buz(:,ichan)), 1); 
 end
  for ichan = 1:n_dbs_elcs
    chanmean_buz_not_completed(ichan,:) = mean(cell2mat(trials_stop.resp_buz(not_completed_trials,ichan)), 1); 
 end

 %% plotting stim-aligned
 close all
 figure
 for ichan = 1:n_dbs_elcs
     subplot(plot_rowcol(1), plot_rowcol(2), ichan)
     plot(chanmean_stim(ichan,1:min_trial_length_stimaligned))
 end
 
 %% plotting buzzer-aligned
 xvals = linspace(-2,2,80); 

%   close all
 figure
 for ichan = 1:n_dbs_elcs
     subplot(plot_rowcol(1), plot_rowcol(2), ichan)
     
%      plot(xvals,chanmean_buz(ichan,:))
%     sgtitle(['all trials (', num2str(nnz(not_completed_trials)), ' trials)'])

     plot(xvals, chanmean_buz_not_completed(ichan,:))
    sgtitle(['not completed trials (', num2str(size(chanmean_buz,1)), ' trials)'])

     xline(0)
     title([el_dbs.name{ichan}, '___', el_dbs.DISTAL_label_1{ichan}])
     xlabel('time post-buzzer (sec)')
     ylabel('high gamma power envelope')
 end