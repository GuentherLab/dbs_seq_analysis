%%%% plot all individual elcs meeting certain critera (e.g. tuning, region, subject)
  %%% load resp_all_subjects first
% 

% setpaths_dbs_seq(); load([PATH_RESULTS, filesep, 'resp_all_subjects_beta.mat'])
% setpaths_dbs_seq(); load([PATH_RESULTS, filesep, 'resp_all_subjects_hg.mat'])
% close all

 %% params

op.newfig = 1; 

op.analyze_responsive_elcs_only = 1;
op.analyze_tuned_elcs_only = 0;

% op.tuning_param = 'p_stim';
% op.tuning_param = 'p_prep';
% op.tuning_param = 'p_prod';

% op.tuning_param = 'p_stim_learn';
% op.tuning_param = 'p_prep_learn';
op.tuning_param = 'p_prod_learn';

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
% op.tuning_param = 'p_prod_syl';

% op.tuning_param = 'p_stim_rime';
% op.tuning_param = 'p_prep_rime';
% op.tuning_param = 'p_prod_rime';

% op.tuning_param = {'p_stim_cons',1};
% op.tuning_param = {'p_prep_cons',1};
% op.tuning_param = {'p_prod_cons',1};

% op.tuning_param = {'p_stim_cons',2};
% op.tuning_param = {'p_prep_cons',2};
% op.tuning_param = {'p_prod_cons',2};

% op.tuning_param = {'p_stim_cons',3};
% op.tuning_param = {'p_prep_cons',3};
% op.tuning_param = {'p_prod_cons',3};

% op.tuning_param = 'p_stim_vow';
% op.tuning_param = 'p_prep_vow';
% op.tuning_param = 'p_prod_vow';

% op.tuning_param = 'p_min_stim_prep_prod'; 
% op.tuning_param = 'p_min_learn';  


op.sort_cond = 'learn_con'; op.sort_cond_vals = {'nat','nn_train','nn_nov'}; 
% op.sort_cond = 'is_nat';  op.sort_cond_vals = [0 1]; % need to re-add the creation of this trials table variable in response_types_seq
% op.sort_cond = 'word'; op.sort_cond_vals = {}; 
% op.sort_cond = 'vow'; op.sort_cond_vals = {}; 
% op.sort_cond = 'word_accuracy'; op.sort_cond_vals = [0 1]; 
% op.sort_cond = 'seq_accuracy'; op.sort_cond_vals = [0 1]; 

%% Which epochs to label with text annotations?
% If empty: label all epochs
% If cell array: label only specified epochs
%%%%%%%% dbs-seq epochs = 'prebase','base','postbase','visual_stim','vis_aud_stim','delay','prep','speech','postprod'

op.epochs_to_label = {'visual_stim','vis_audio_stim','speech'};  % Only show labels for these epochs
% op.epochs_to_label = {};  % label all epochs



%% figure options
op.plotrows = 3;
op.plotcolumns = 5; 
op.screen_order = [2 3 1]; 

%% selection regions, subjects
op.regions_to_plot = {}; % plot all regions
% op.regions_to_plot  = {'SMC','IFG/IFS','Thal'};
op.regions_to_plot  = {'Thal'};

op.subjects_to_plot = {}; % plot all subjects
% op.subjects_to_plot = {'DM1005'}: 


%% Epoch visualization options
op.epoch_colors = parula(height(op.epochs));  % or 'viridis', 'turbo', 'hsv', etc.
op.epoch_alpha = 0.12;
op.epoch_label_height = 0.92;
op.epoch_label_fontsize = 8;

%% ============ CALL MAIN FUNCTION ============
[electrode_plot_data, align_stats_elc, resp_grpd_elc, cfg_elc, fig_handles, ax_handles] = ...
    plot_electrode_timecourses(resp, subs, op);



