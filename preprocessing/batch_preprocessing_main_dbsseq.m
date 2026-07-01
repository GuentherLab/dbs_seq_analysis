%%% run processing steps required to get trialwise high gamma and beta responses from raw fieldtrip data...
%%% .... from all DBSSEQ subs - not-vibration-denoised data
%
% requirements for all subjects before running this batch script:
%   -preprocessing steps through A08 (raw fieldtrip) and B06 (ecog localizations) 
%   -processing step A18 - behavioral annotations - syllable timing, accuracy, and stop responses
%   -manual artifacts file saved - use annotate_manual_ephys_artifacts.m
%   -repos on path: bml, ieeg_ft_funcs_am

clear


% % % % % % op.resp_signal = 'hg'; 
% % % % % % % op.resp_signal = 'beta'; 

op.art_crit = 'G'; 

% op.rereference_method = 'none';
% op.rereference_method = 'CTAR';
op.rereference_method = 'CMR'; % common median... bml_rereference supports this but doesn't list it at the top of the function


op.time_buffer_before_epoch_trial_start = 1; % time buffer in sec before visual onset; ?? gets used in redefine_trial ??

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

    % load fieldtrip raw and select ephys channels
    set_project_specific_variables(); % get sub-specific info
    load(FT_RAW_FILENAME, 'D')


% need to add ephys channel selection here


    % apply manual artifact mask, run cleaning script, highpass filter, notch filter

    cfg = []; 
    D_sel_hpf_cleaned = hpf_and_instantaneous_artifact_mask(D,cfg);

    cfg = [];
    [D_sel_notch, cfg_notch] = notch_harmonics_filter(D_sel_hpf_cleaned,cfg);
    save([FT_FILE_PREFIX,'raw-filt_ar-G'],'D_sel_notch','cfg_notch')

    % rereferencing - save output
    % important: set manual artifactual timepoints to nans here, not just zeroes
    % .... so that zeroes don't affect CMR
    % use rereference_ephys here.... either include plotting functions in that or make new plotting function
    %%%% adapt the useful parts of Y:\Documents\Code\ieeg_ft_funcs_am\preprocessing\P09_redefine_trial_common_avg_ref_not_denoised.m
    
    % compute both hg and beta, save outputs
    %%% AM note: edit multifreq_avg_pow to call envelope_wavpow in ieeg_ft/preprocessing instead of bml_envelope_wavpow

    % key thing to look at: what does hg and beta power look like on the edges of artifact windows? 

    % definitely need to re-nan the artifact windows after getting hg and beta


% note - this was a wrapper for multifreq avg wavpow - see if it has anything important
% % % % % % % %     P09_compute_wavpow_trials_not_denoised(op)




end
 