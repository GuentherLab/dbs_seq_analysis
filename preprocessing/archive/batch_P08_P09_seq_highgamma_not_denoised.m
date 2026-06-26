%%% run processing steps required to get trialwise high gamma responses from raw fieldtrip data...
%%% .... from all DBSSEQ subs not-vibration-denoised data

clear

op.art_crit = 'E'; op.resp_signal = 'hg'; 

% op.rereference_method = 'CTAR'; % none, CMR, CMR_SVD, CMR_reg, CMR_SVD_c2
op.rereference_method = 'CMR_SVD_c2'; % common median... bml_rereference supports this but doesn't list it at the top of the function
% op.rereference_group = ''; % 'strip', 'connector'

op.time_buffer_before_epoch_trial_start = 1; % time buffer in sec before visual onset; gets unsed in redfine_trial

op.denoised = 0; 

sublist ={...
     'DM1005';...
     'DM1007';...
     'DM1008';...
     'DM1024';...
     'DM1025';...
     'DM1037';...
     'DM1044';...
     'DM1045';... % NB: reference switched mid-run
       'DM1046';...
       'DM1047';...
     'DM1048';...
     'DM1049';...
%      'DM1050';... % poor behavior and ecog localization - don't include
     'DM1051';...
     'DM1052';...
     'DM1054';...
     };

% sublist = {...
%     'DM1007';};


if exist('/Users/rohandeshpande/Documents/School/Research/Code/ieeg_ft_funcs_am-main','dir') 
    addpath('/Users/rohandeshpande/Documents/School/Research/Code/ieeg_ft_funcs_am-main') 
    addpath('/Users/rohandeshpande/Documents/School/Research/Code/ieeg_ft_funcs_am-main/util') 
    addpath(genpath('/Users/rohandeshpande/Documents/School/Research/Code/bml-master')) % added by rohan
    addpath('/Users/rohandeshpande/Documents/School/Research/Code/fieldtrip-master')
    addpath(genpath('/Users/rohandeshpande/Documents/School/Research/Code/dbs_seq_analysis-main'))
else % if not RD's local machine, use default paths
    setpaths_dbs_seq();
end

nsubs = length(sublist);
for isub = 1:nsubs
    thissub = sublist{isub}
    op.sub = thissub;

    close all force

    P08A09_detect_artifact_not_denoised(op)
    P09_redefine_trial_common_avg_ref_not_denoised(op)
    
    P09_compute_wavpow_trials_not_denoised(op)
%     P09_compute_high_gamma_trials_not_denoised(op) %%% check that this produces identical outputs as P09_compute_wavpow_trials_not_denoised.m, then replace it with wavpow version
end