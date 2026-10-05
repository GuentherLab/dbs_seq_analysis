
%%%% do coherence analysis for subjects in dbsseq and compile pairs into a single table
% you must run batch_response_types_seq first to generate the subs table (covers all subs) and resp.rspv (specific to each sub)

 % most important is rsvp … maybe also p prod learn prep stim, p prod prep stim, p syl stim prep prod
op.resp_vars_to_copy = {'rspv','bad_elc','p_min_stim_prep_prod',...
    'p_stim','p_prep','p_prod', ...
    'p_stim_learn','p_prep_learn','p_prod_learn',...
    'p_stim_syl','p_prep_syl','p_prod_syl'}; 

op.sort_cond = 'learn_con'; op.sort_cond_vals = {'nat','nn_train','nn_nov'}; 
% op.sort_cond = 'is_nat';  op.sort_cond_vals = [0 1]; % need to re-add the creation of this trials table variable in response_types_seq
% op.sort_cond = 'word'; op.sort_cond_vals = {}; 
% op.sort_cond = 'vow'; op.sort_cond_vals = {}; 
% op.sort_cond = 'word_accuracy'; op.sort_cond_vals = [0 1]; 
% op.sort_cond = 'seq_accuracy'; op.sort_cond_vals = [0 1]; 


% % % % % % analyze coherence at these freq bands
% op.freqs = [20, 100]; 
% op.freqs = [100]; 
% op.freqs = round(logspace(log10(70), log10(150), 6)); 
op.freqs = round(logspace(log10(1), log10(150), 50),1); 

% analyze coherence between these regions
op.regions_to_analyze = {'IFG/IFS','STN','Thal','GP'}; 

% % % % event = {'t_aud_syl_on';'t_aud_go_on';'t_prod_on'}; 
% % % %     sync_events = table(event,nan(size(event)),nan(size(event)),'VariableNames',{'event','start','end'},'RowNames',event); clear event
% % % % sync_events{'t_aud_syl_on','start'} = -1.5; % vis stim on starts 1sec before audio stim; baseline include 0.5s before vis stim on
% % % %     sync_events{'t_aud_syl_on','end'} = 4; % end of trial, including time for beta baseline rebound
% % % % sync_events{'t_aud_go_on','start'} = -3; % start about at baseline start
% % % %     sync_events{'t_aud_go_on','end'} = 3; % end of trial, including time for beta baseline rebound
% % % % sync_events{'t_prod_on','start'} = -3.5; % start about at baseline start
% % % %     sync_events{'t_prod_on','end'} = 2.5; % end of trial, including time for beta baseline rebound

event = {'t_prod_on'}; 
    sync_events = table(event,nan(size(event)),nan(size(event)),'VariableNames',{'event','start','end'},'RowNames',event); clear event
sync_events{'t_prod_on','start'} = -3.5; % start about at baseline start
    sync_events{'t_prod_on','end'} = 2.5; % end of trial, including time for beta baseline rebound


op.fieldtrip_var_name = 'D_ref'; % variable name of the fieldtrip struct variable `

op.coh_measure = 'mag_sq'; % 'mag_sq' (magnitude square) or 'imag' (imaginary part)
op.buffer_window_sec = 1; % 1 sec buffer around windows to avoid edge artifacts during time-frequency decomposition

 op.show_progress = 1; % if true, do commandline output when proceeding to new subject with/ subject name

%% create subs table with necessary paths

setpaths_dbs_seq(); 
subs_processed_file = fullfile(PATH_RESULTS, 'resp_all_subjects_hg.mat'); 
op.savefile = fullfile(PATH_RESULTS, 'coh_all_subjects.mat'); 
op.sync_events = sync_events; 

load(subs_processed_file, 'subs'); % may take a few seconds because this file also contains large resp table which we are not loading


nsubs= height(subs);
for isub = 1:nsubs
    subs.paths{isub}.fieldtrip = subs.paths{isub}.fieldtrip_ref; % specify which fieldtrip file to use for coherence analysis
    subs.paths{isub}.artifact = subs.paths{isub}.artifact_manual; % specify which artifact file to use for coherence analysis
%     subs.paths{isub}.trials = subs.paths{isub}.trials_beh;  % specify which trials file to use for coherence analysis
end

% subs = subs(1,:);

%%


coh = ephys_coherence(subs, op) 