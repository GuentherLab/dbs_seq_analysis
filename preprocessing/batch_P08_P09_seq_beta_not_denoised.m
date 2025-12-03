%%% run processing steps required to get trialwise high gamma responses from raw fieldtrip data...
%%% .... from all DBSSEQ subs not-vibration-denoised data

clear

% op.art_crit = 'E'; op.resp_signal = 'hg'; 
op.art_crit = 'F'; op.resp_signal = 'beta'; 

% op.rereference_method = 'none'; % monopolar.... for subcortical/DBS
% op.rereference_method = 'CTAR'; % common trimmed averaged
op.rereference_method = 'CMR'; % common median... bml_rereference supports this but doesn't list it at the top of the function

op.time_buffer_before_epoch_trial_start = 1; % time buffer in sec before visual onset; gets unsed in redfine_trial

op.denoised = 0; 

sublist ={...
     'DM1005';...
     'DM1007';...
     'DM1008';...
     'DM1024';...
     'DM1025';...
     'DM1037';...
     };

setpaths_dbs_seq()

nsubs = length(sublist);
for isub = 1:nsubs
    thissub = sublist{isub}
    op.sub = thissub;

    close all force

    P08A09_detect_artifact_not_denoised(op)
    P09_redefine_trial_common_avg_ref_not_denoised(op)
    P09_compute_wavpow_trials_not_denoised(op)
end
