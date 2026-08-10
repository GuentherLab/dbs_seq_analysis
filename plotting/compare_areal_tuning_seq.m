 %%%% check whether there is a nonrandom distribution of significantly tuned electrodes across areas
  %%% load resp_all_subjects first
% setpaths_dbs_seq()

% load([PATH_RESULTS, filesep, 'resp_all_subjects.mat'])
% 
% close all

 %% params

op.newfig = 1; 



op.separate_individual_subs = 1; 
op.analyze_responsive_elcs_only = 1;

% op.param = 'p_stim';
% op.param = 'p_prep';
% op.param = 'p_prod';


% op.param = 'p_stim_learn';
% op.param = 'p_prep_learn';
% op.param = 'p_prod_learn';

% op.param = 'p_stim_nn_v_nat';
% op.param = 'p_prep_nn_v_nat';
% op.param = 'p_prod_nn_v_nat';

% op.param = 'p_stim_novel_vs_trained';
% op.param = 'p_prep_novel_vs_trained';
% op.param = 'p_prod_novel_vs_trained';

% op.param = 'p_stim_novel_vs_nat';
% op.param = 'p_prep_novel_vs_nat';
% op.param = 'p_prod_novel_vs_nat';

% op.param = 'p_stim_syl';
% op.param = 'p_prep_syl';
% op.param = 'p_prod_syl';

% op.param = 'p_stim_rime';
% op.param = 'p_prep_rime';
% op.param = 'p_prod_rime';

% op.param = {'p_stim_cons',1};
% op.param = {'p_prep_cons',1};
op.param = {'p_prod_cons',1};

% op.param = {'p_stim_cons',2};
% op.param = {'p_prep_cons',2};
% op.param = {'p_prod_cons',2};

% op.param = {'p_stim_cons',3};
% op.param = {'p_prep_cons',3};
% op.param = {'p_prod_cons',3};

% op.param = 'p_stim_vow';
% op.param = 'p_prep_vow';
% op.param = 'p_prod_vow';

% op.alpha = 0.01; 
op.alpha = 0.05; 


% op.param = 'p_min_stim_prep_prod'; op.alpha = 1 - (1-0.05)^3; % general task responsivity..... 3 tests 
% op.param = 'p_min_learn';  op.alpha = 1 - (1-0.05)^3; % 3 tests 

op.bar_face_color = [0.5 0.5 0.5]; 

[subs_areastats, areastats_all_subs] = compare_areal_tuning(resp,op); % in ieeg_funcs_am

%%
% % roi = 'SMC';
% % roi = 'vPMC';
% % roi = 'STG';
% roi = 'MFG'; 
% % roi = 'IFG/IFS';
% % roi = 'all'; 
% 
% 
% 
% subs_areastats.(['prop_sgn_',roi]) = cellfun(@(x)x{roi,'prop_sgn'},subs_areastats.areastats); 
% figure; scatter(subs_beh.acc_mean,subs_areastats.(['prop_sgn_',roi])); ylabel(['prop_elc_sgn_',roi,'____',op.param]); xlabel('acc_mean')
% [r p] = corrcoef(subs_beh.acc_mean,subs_areastats.(['prop_sgn_',roi]),'Rows', 'complete')



