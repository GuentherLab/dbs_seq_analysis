
%%%% do coherence analysis for subjects in dbsseq and compile pairs into a single table
% you must run batch_response_types_seq first to generate the subs table and resp.rspv


op.resp_vars_to_copy = table(    % most important is rsvp … maybe also p prod learn prep stim, p prod prep stim, p syl stim prep prod

op.sort_cond = 'learn_con'; op.sort_cond_vals = {'nat','nn_train','nn_nov'}; 
% op.sort_cond = 'is_nat';  op.sort_cond_vals = [0 1]; % need to re-add the creation of this trials table variable in response_types_seq
% op.sort_cond = 'word'; op.sort_cond_vals = {}; 
% op.sort_cond = 'vow'; op.sort_cond_vals = {}; 
% op.sort_cond = 'word_accuracy'; op.sort_cond_vals = [0 1]; 
% op.sort_cond = 'seq_accuracy'; op.sort_cond_vals = [0 1]; 


% for each sub, need to make paths.fieldtrip_file = paths.fieldtrip_ref..... paths.trials = paths.trials_beh
.... paths.artifact = paths.artifact_manual..
    ...... also need to pick which resp file we're using - probably beta, to have more inclusive resp.rspv



event = {'t_aud_syl_on';'t_aud_go_on';'t_prod_on'}; 
    sync_events = table(event,nan(size(event)),nan(size(event)),'VariableNames',{'event','start','end'},'RowNames',event);
sync_events{'t_aud_syl_on','start'} = -1.5; % vis stim on starts 1sec before audio stim; baseline include 0.5s before vis stim on
    sync_events{'t_aud_syl_on','end'} = 4; % end of trial, including time for beta baseline rebound
sync_events{'t_aud_go_on','start'} = -3; % start about at baseline start
    sync_events{'t_aud_go_on','end'} = 3; % end of trial, including time for beta baseline rebound
sync_events{'t_prod_on','start'} = -3.5; % start about at baseline start
    sync_events{'t_prod_on','end'} = 2.5; % end of trial, including time for beta baseline rebound

for isub = 1:nsubs
    % load trials table

    % get rid of stop trials and unusable trials


    cfg = op; 
    cfg.sub = subs.sub{isub}; 
    cfg.sync_events = sync_events
    coh = ephys_coherence(D_file, trials_file, electrodes_file, cfg) 

end