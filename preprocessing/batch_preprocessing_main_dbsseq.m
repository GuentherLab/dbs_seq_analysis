%%% run processing steps required to get trialwise high gamma and beta responses from raw fieldtrip data...
%%% .... from all DBSSEQ subs - not-vibration-denoised data
%
% requirements for all subjects before running this batch script:
%   -preprocessing steps through A08 (raw fieldtrip) and B06 (ecog localizations) 
%   -processing step A18 - behavioral annotations - syllable timing, accuracy, and stop responses
%   -manual artifacts file saved - use annotate_manual_ephys_artifacts.m
%   -repos on path: bml, ieeg_ft_funcs_am

clear


op.resp_signal = 'hg'; 
% op.resp_signal = 'beta'; 

op.art_crit = 'G'; 

% op.rereference_method = 'none';
% op.rereference_method = 'CTAR';
op.rereference_method = 'CMR'; % common median... bml_rereference supports this but doesn't list it at the top of the function


op.time_buffer_before_epoch_trial_start = 1; % time buffer in sec before visual onset; gets unsed in redefine_trial

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
% % %      'DM1050';... % poor behavior and ecog localization - don't use
     'DM1051';...
     'DM1052';...
     'DM1054';...
     };

setpaths_dbs_seq()

nsubs = length(sublist);
for isub = 1:nsubs
    thissub = sublist{isub}
    op.sub = thissub;


    close all force

    % apply manual artifact mask, run cleaning script, highpass filter, notch filter
    clean_mask_hpf_notch_filter(op)

% % % % % % %     P09_redefine_trial_common_avg_ref_not_denoised(op)
    
% % % % % % % %     P09_compute_wavpow_trials_not_denoised(op)
end
 