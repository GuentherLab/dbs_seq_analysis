%%% run processing steps required to get trialwise high gamma responses from raw fieldtrip data...
%%% .... from all DBSSEQ subs not-vibration-denoised data

% clear

% op.art_crit = 'E'; op.resp_signal = 'hg'; 

% op.rereference_method = 'none';
% op.rereference_method = 'CTAR';

sublist ={...
     'DM1005';...
     'DM1007';...
     'DM1008';...
     'DM1024';...
     'DM1025';...
     'DM1037';...
     };

addpath('C:\Users\amsmeier\ieeg_ft_funcs_am')
addpath('C:\Users\amsmeier\ieeg_ft_funcs_am\util')

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
 