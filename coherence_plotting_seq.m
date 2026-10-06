 %%% plot coherence averaged over region pairs for dbs-seq project

 % setpaths_dbs_seq(); load([PATH_RESULTS, filesep, 'coh_all_subjects_0to150hz.mat']) % may be massive size file
% close all


 %% params

op.min_responsive_elcs = 1; % 0,1,2..... looks for coh.rspv - same meaning as in original resp table
op.min_tuned_elcs = 0; % 0,1,2

% op.tuning_param = 'p_stim';
% op.tuning_param = 'p_prep';
% op.tuning_param = 'p_prod';

% op.tuning_param = 'p_stim_learn';
% op.tuning_param = 'p_prep_learn';
% op.tuning_param = 'p_prod_learn';

% op.tuning_param = 'p_stim_nn_v_nat';
% op.tuning_param = 'p_prep_nn_v_nat'; 
% op.tuning_param = 'p_prod_nn_v_nat';

% op.tuning_param = 'p_stim_novel_vs_trained';
% op.tuning_param = 'p_prep_novel_vs_trained';
% op.tuning_param = 'p_prod_novel_vs_trained';

% op.tuning_param = 'p_stim_novel_vs_nat';
% op.tuning_param = 'p_prep_novel_vs_nat';
% op.tuning_param = 'p_prod_novel_vs_nat';

% op.tuning_param = 'p_stim_syl';
% op.tuning_param = 'p_prep_syl';
op.tuning_param = 'p_prod_syl';

% op.tuning_param = 'p_min_stim_prep_prod'; 
% op.tuning_param = 'p_min_learn';  

%%%%%%%%%%%% select trial sort cond values.... 'sort_cond' is only meant for reference here, as this param was already specified by the analysis function
op.sort_cond = 'learn_con'; op.sort_cond_vals = {'nat','nn_train','nn_nov'}; 
% op.sort_cond = 'is_nat';  op.sort_cond_vals = [0 1]; %
% op.sort_cond = 'word'; op.sort_cond_vals = {}; 
% op.sort_cond = 'vow'; op.sort_cond_vals = {}; 
% op.sort_cond = 'word_accuracy'; op.sort_cond_vals = [0 1]; 
% op.sort_cond = 'seq_accuracy'; op.sort_cond_vals = [0 1]; 

%%%%%%%%% select sync event - we are not timewarping for coherence
% op.sync_event = 't_aud_syl_on'; 
% op.sync_event = 't_aud_go_on'; 
op.sync_event = 't_prod_on'; 

% this param specifies regions which both pair members must be included in (not just 1 pair mmber)
% op.regions_to_analyze = {}; % plot all regions
% op.regions_to_analyze = {'IFG/IFS','STN'}; 
op.regions_to_analyze = {'IFG/IFS','STN','Thal','GP'}; 

op.tuning_alpha = 0.05; 
%%%%% determines how we visaulize the frequency bands in time-coh plots, taking one of these vals:
% op.yscale_mode = 'linear'; % rectangles representing coh at particular time/freq have their heights proportional to the spacing between neighboring freqs - so that xtick value spacing represents actual freq spacing
op.yscale_mode = 'equal'; %  rectangles all have identical height; this means that if the freq distribution specified in ephys_coherence.m was e.g. logspaced, the y axis will effectively also be logspaced

%%% select method for normalizing coherence so we can average acros electrode pairs
% … if zscore_base is selected, then you  must also include op.zscore_base_window - a 2-value vector specifying the baseline window
% ……… base window is relative to zero time point within trials, so e.g. [-2 0] would mean, if sync time is speech onset, that base starts 2sec before speech and ends right at speech
%
% op.norm_method = 'none'; 
op.norm_method = 'zscore_atanh'; % recommended
% op.norm_method = 'zscore_base'; op.zscore_base_window = [-3.5 -2]; % must customize base window depending on the sync time you're plotting.... -3.5 -3 from speech onset covers ~baseline pre-stim

% op.freq_range = []; % plot all saved freqs
op.freq_range = [3 150]; % only plot freqs in this range (hz) 

%%%%% which formats to plot the data
op.show_heatmap = 1; 
op.show_canon_timecourses = 0;


%%%%%%%%%%%% timecourse-specific params %%%%%%%%%%%
op.smooth_timecourse_method = 'mean';
% op.smooth_timecourse_method = 'median';

% op.smooth_timecourse_width_sec = 0; % width of moving average window for smooth; set to 0 for no smoothing
op.smooth_timecourse_width_sec = 0.7; % width of moving average window for smooth; set to 0 for no smoothing

op.canon_bands = {...
%     'Delta',[0.5 4],...
    'Theta', [4 8],... 
%     'Alpha', [8 12],...
    'Beta', [12 30],...
%     'Low_Gamma', [30 70],...
    'High_Gamma', [70 150],...
    };
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% run plotting func
close all
op_out = coherence_plotting(coh,op); 







