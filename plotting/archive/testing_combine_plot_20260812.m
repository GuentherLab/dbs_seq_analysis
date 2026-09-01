 
% resp_not_rspv = resp(~resp.rspv,:);
% resp_rspv = resp(resp.rspv,:);


 %%%% average timecourses of electrodes and plot

  %%% load resp_all_subjects first
% setpaths_dbs_seq()
% load([PATH_RESULTS, filesep, 'resp_all_subjects_hg_ref-CMR.mat'])

% close all

op.newfig = 1; 



op.analyze_responsive_elcs_only = 0; 
op.analyze_tuned_elcs_only = 1;

op.smooth_windowsize = 45; 

%% trial condition for grouping trials

%     op.sort_cond = ''; % plot all trials averaged as a single timecourse without sorting
    op.sort_cond = 'learn_con';
%     op.sort_cond = 'is_nat';
%     op.sort_cond = 'word';
%     op.sort_cond = {'cons',1}; 
%     op.sort_cond = {'cons',2}; 
%     op.sort_cond = {'cons',3}; 
%     op.sort_cond = 'vow';
%     op.sort_cond = 'word_accuracy';
%     op.sort_cond = 'seq_accuracy';


%% parameter for filtering out which electrodes to plot

% op.tuning_param = 'p_min_stim_prep_prod'; % general task responsivity
% op.tuning_param = 'p_stim';
% op.tuning_param = 'p_prep';
% op.tuning_param = 'p_prod';

% op.tuning_param = 'p_min_learn'; 
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






%% trial table varname for times used for time-locking responses
% op.time_align_var = 't_vis_syl_on'; % audio stim cue on
% op.time_align_var = 't_aud_go_on'; % go beep
op.time_align_var = 't_prod_on'; % speech onset


op.leg_pos_adjust = 0.1;

[cond_elc_rgn_not_rspv, align_stats_rgn_not_rspv, resp_grpd_rgn_not_rspv, cfg_rgn_not_rspv] = combine_plot_electrode_timecourses(resp_not_rspv,subs,op);