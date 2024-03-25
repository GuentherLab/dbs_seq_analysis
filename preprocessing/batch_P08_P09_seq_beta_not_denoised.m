%%% run processing steps required to get trialwise high gamma responses from raw fieldtrip data...
%%% .... from all DBSSEQ subs not-vibration-denoised data

clear

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
    op.art_crit = 'F'; 
    op.resp_signal = 'beta'; 

    close all force

    P08A09_detect_artifact_not_denoised(op)
    P09_redefine_trial_common_avg_ref_not_denoised(op)
    P09_compute_wavpow_trials_not_denoised(op)
end
