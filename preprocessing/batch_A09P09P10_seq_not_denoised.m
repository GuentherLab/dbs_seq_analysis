%%% run processing steps required to get trialwise high gamma responses from raw fieldtrip data...
%%% .... from all DBSSEQ subs not-vibration-denoised data

clear
set(0,'DefaultFigureWindowStyle','docked')
% set(0,'DefaultFigureWindowStyle','normal')

%% params
% op.art_crit = 'E'; op.resp_signal = 'hg';
op.art_crit = 'F'; op.resp_signal = 'beta';

op.denoised = 0; % do not use vibration-denoised data

% op.rereference_method = 'none';
op.rereference_method = 'CTAR';

op.out_freq = 100; % freq of wavpow output files

sublist ={...
     'DM1005';...
     'DM1007';...
     'DM1008';...
     'DM1024';...
     'DM1025';...
     'DM1037';...
     };

nsubs = length(sublist);
for isub = 1:nsubs
    op.sub = sublist{isub};

  fprintf('\n* Preprocessing subject %s...',op.sub)

    close all force

%     P08A09_detect_artifact_not_denoised(op)

    P09_redefine_trial_reref(op)
%     P09_redefine_trial_common_avg_ref_not_denoised(op)
    

    P10_wavpow_from_rereferenced(op);
%     P09_compute_wavpow_trials_not_denoised(op)
%     P09_compute_high_gamma_trials_not_denoised(op) %%% check that this produces identical outputs as P09_compute_wavpow_trials_not_denoised.m, then replace it with wavpow version
end
 