% compute eletrode responses during specific trial epochs
% look for electrodes with different responses to different conditions

% clear

%% analysis parameters
%%%% for baseline window, use the period from -base_win_sec(1) to -base_win_sec(2) before stim onset
%%% baseline should end at least a few 100ms before stim onset in order to not include anticipatory activity in baseline
base_win_sec = [1, 0.3]; 
stim_window_extend_end = 0.3; % for responses during stimulus, add this long in seconds to the analyzed 'stimulus period' after actual stim offset

% for responses during speech, start the analyzed 'speech period' this early in seconds to capture pre-sound muscle activation; also end prep period this early
speech_window_extend_start = 0.15;  
trial_end_post_speech_win = 0.6; % end the trial this long after speech offset in seconds

use_vibration_denoised_data = 0; 

responsivity_alpha = 0.05; % consider electrodes responsive if they have above-baseline responses during one response epoch at this level

%% Defining paths, loading parameters
setpaths_dbs_seq()
vardefault('SUBJECT','DM1007');
vardefault('resp_signal','hg'); 
vardefault('ARTIFACT_CRIT','E'); 
vardefault('rereference_method','CTAR');
SESSION = 'intraop';
TASK = 'smsl'; 

%%% CRITERIA E parameter valus
PATH_DER = [PATH_DATA filesep 'derivatives'];
PATH_DER_SUB = [PATH_DER filesep 'sub-' SUBJECT];  
PATH_PREPROC = [PATH_DER_SUB filesep 'preproc'];
PATH_ANNOT = [PATH_DER_SUB filesep 'annot'];
PATH_FIELDTRIP = [PATH_DER_SUB filesep 'fieldtrip'];
PATH_AEC = [PATH_DER_SUB filesep 'aec']; 
PATH_SCORING = [PATH_DER_SUB filesep 'analysis' filesep 'task-', TASK, '_scoring'];
PATH_ANALYSIS = [PATH_DER_SUB filesep 'analysis'];
PATH_TRIAL_AUDIO = [PATH_ANALYSIS filesep 'task-', TASK, '_trial-audio'];
PATH_TRIAL_AUDIO_INTRAOP_GO = [PATH_TRIAL_AUDIO filesep 'ses-', SESSION, '_go-trials'];
PATH_TRIAL_AUDIO_INTRAOP_STOP = [PATH_TRIAL_AUDIO filesep 'ses-', SESSION, '_stop-trials']; 

PATH_SRC = [PATH_DATA filesep 'sourcedata'];
PATH_SRC_SUB = [PATH_SRC filesep 'sub-' SUBJECT];  
PATH_SRC_SESS = [PATH_SRC_SUB filesep 'ses-' SESSION]; 
PATH_AUDIO = [PATH_SRC_SESS filesep 'audio']; 
PATHS_TASK = strcat(PATH_SRC_SUB,filesep,{'ses-training';'ses-preop';'ses-intraop'},filesep,'task');



%% load data 
% cd(PATH_FIELDTRIP)

if use_vibration_denoised_data
    denoise_str = '_denoised';
elseif ~use_vibration_denoised_data
    denoise_str = '_not-denoised';
end

if ~exist('D_wavpow','var') % if fieldtrip object not yet loaded
    load([PATH_FIELDTRIP, filesep, 'sub-', SUBJECT, '_ses-', SESSION, '_task-', TASK, '_ft-', resp_signal, '-trial_ar-',ARTIFACT_CRIT, '_ref-',rereference_method, denoise_str, '.mat'])
%     D_wavpow = D_hg; % comment in for highgamma.... temporary fix
end

% % trial timing and electrode info
trials = bml_annot_read_tsv([PATH_ANNOT, filesep, 'sub-' SUBJECT, '_ses-', SESSION, '_task-' TASK, '_annot-produced-syllables.tsv']);
trials_with_stim_timing = bml_annot_read_tsv([PATH_ANNOT, filesep, 'sub-', SUBJECT, '_ses-', SESSION, '_task-', TASK, '_annot-trials.tsv']);
elc_info = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_electrodes.tsv';]); 
    elc_info = renamevars(elc_info,'name','chan');

%% get responses in predefined epochs
% 'base' = average durng pre-stim baseline
% all response values except 'base' are baseline-normalized by dividing by that trial's baseline average
ntrials = height(trials);
nchans = length(D_wavpow.label);
nans_ch = nan(nchans,1); 
nans_tr = nan(ntrials,1); 
cel_tr = cell(ntrials,1); 

% info about our trial timing analysis window
trials = renamevars(trials,{'starts','ends','duration'}, {'t_prod_on','t_prod_off','dur_prod'}); % make it clear that these times demarcate speech production window
trials.id = [];
trials.t_stim_syl_on = trials_with_stim_timing.audio_onset;
trials.t_stim_syl_off = trials_with_stim_timing.audio_offset;
trials.t_stim_gobeep_on = trials_with_stim_timing.audio_go_onset;
trials.t_stim_gobeep_off = trials_with_stim_timing.audio_go_offset;
trials.starts = trials.t_stim_syl_on - base_win_sec(1); % trial starts at beginning of baseline window
trials.ends = trials.t_prod_off + trial_end_post_speech_win; % trial ends at fixed time after voice offset
trials.duration = trials.ends - trials.starts; 


% table containing responses during epochs for each chan
cel = repmat({nans_tr},nchans,1); % 1 value per trial per chan
resp = table(   D_wavpow.label, cel,   repmat({cel_tr},nchans,1),  cel,    cel,    cel,    nans_ch,  ....
  'VariableNames', {'chan', 'base', 'timecourse',             'stim', 'prep', 'prod', 'p_prep' }); 

% extract epoch-related responses
%%%% trials.times{itrial} use global time coordinates
%%%% ....... start at a fixed baseline window before stim onset
%%%% ....... end at a fixed time buffer after speech offset
for itrial = 1:ntrials % itrial is absolute index across sessions; does not equal "trial_id" from loaded tables
    iblock = trials.block_id(itrial); 
    trial_id_in_block = trials.trial_id(itrial); % block-relative trial number
    
    % get indices within the trial-specific set of timepoints of D_wavpow.time{itrial} that match our specified trial window
    match_time_inds = D_wavpow.time{itrial} > trials.starts(itrial) & D_wavpow.time{itrial} < trials.ends(itrial); 
    trials.times{itrial} = D_wavpow.time{itrial}(match_time_inds); % times in this redefined trial window... still using global time coordinates

    % get trial-relative baseline time indices; window time-locked to first stim onset
    base_inds = D_wavpow.time{itrial} > trials.starts(itrial) & D_wavpow.time{itrial} < [trials.t_stim_syl_on(itrial) - base_win_sec(2)]; 
    stim_inds = D_wavpow.time{itrial} > trials.t_stim_syl_on(itrial) & D_wavpow.time{itrial} < trials.t_stim_syl_off(itrial) + stim_window_extend_end; 
    prep_inds = D_wavpow.time{itrial} > trials.t_stim_syl_off(itrial) & D_wavpow.time{itrial} < [trials.t_prod_on(itrial) - speech_window_extend_start]; 
    prod_inds = D_wavpow.time{itrial} > [trials.t_prod_on(itrial) - speech_window_extend_start]   &   D_wavpow.time{itrial} < trials.t_prod_off(itrial);     

    for ichan = 1:nchans
        % baseline activity and timecourse
        % use mean rather than nanmean, so that trials which had artifacts marked with NaNs will be excluded
        resp.base{ichan}(itrial) = mean( D_wavpow.trial{itrial}(ichan, base_inds), 'includenan' ); % mean wavpow during baseline
    
        % get baseline-normalized trial timecourse
       resp.timecourse{ichan}{itrial} =  D_wavpow.trial{itrial}(ichan, match_time_inds) - resp.base{ichan}(itrial); 

        % response during stim presentation (not go beep)
        resp.stim{ichan}(itrial) = mean( D_wavpow.trial{itrial}(ichan, stim_inds) ) - resp.base{ichan}(itrial);

        % preparatory response
        %%%% prep period inds = after stim ends and before syllable prod onset
        resp.prep{ichan}(itrial) = mean( D_wavpow.trial{itrial}(ichan, prep_inds) ) - resp.base{ichan}(itrial);

        % response during speech production
        resp.prod{ichan}(itrial) = mean( D_wavpow.trial{itrial}(ichan, prod_inds) ) - resp.base{ichan}(itrial);
    end    
end
trials(:,{'audio_go_offset'}) = []; % renamed/redundant

% rename stim/learning condition variable, get syllable parts, rearrange table
trials.learn_con = cell(ntrials,1);
trials.learn_con(find(trials.stim_condition==1)) = {'nn_train'};
trials.learn_con(find(trials.stim_condition==2)) = {'nn_nov'};
trials.learn_con(find(trials.stim_condition==3)) = {'nat'};
trials = removevars(trials,{'stim_condition','run_id'});
trials.ons_clust = cellfun(@(x)x(1:end-3),trials.word, 'UniformOutput',false);
trials.rime = cellfun(@(x)x(end-1:end),trials.word, 'UniformOutput',false);
trials.vow = cellfun(@(x)x(end-1),trials.word, 'UniformOutput',false);
trials.coda = cellfun(@(x)x(end),trials.word, 'UniformOutput',false);
trials = movevars(trials,{'trial_id','learn_con','word_accuracy','seq_accuracy','block_id','rime_error','word','ons_clust','rime','vow','coda'},'Before',1);

%% test for response types 
for ichan = 1:nchans
    good_trials = ~isnan(resp.base{ichan}); % non-artifactual trials for this channel
    good_gotrials = good_trials & ~trials.is_stoptrial;
    zeros_vec = zeros(nnz(good_trials),1); 
    zeros_vec_gotrials = zeros(nnz(good_gotrials),1); 
    is_novel_trial = strcmp(trials.learn_con,'nn_nov');
    is_trained_trial = strcmp(trials.learn_con,'nn_train');
    is_native_trial = strcmp(trials.learn_con,'nat');
    if nnz(good_gotrials) > 1 % only do stats analysis if channel had >0 good go trials
         prep_resp_novel = resp.prep{ichan}(good_gotrials & is_novel_trial);
         prep_resp_trained = resp.prep{ichan}(good_gotrials & is_trained_trial);
         prep_resp_nonnative = [prep_resp_novel; prep_resp_trained]; 
         prep_resp_nat = resp.prep{ichan}(good_gotrials & is_native_trial);

         prod_resp_novel = resp.prod{ichan}(good_gotrials & is_novel_trial);
         prod_resp_trained = resp.prod{ichan}(good_gotrials & is_trained_trial);
         prod_resp_nonnative = [prod_resp_novel; prod_resp_trained]; 
         prod_resp_nat = resp.prod{ichan}(good_gotrials & is_native_trial);
        
        % above/below-baseline response during the stim period
        [~, resp.p_stim(ichan)] = ttest2(resp.stim{ichan}(good_trials), zeros_vec_gotrials); 

        % above/below-baseline response during the prep period
        [~, resp.p_prep(ichan)] = ttest2(resp.prep{ichan}(good_trials), zeros_vec); 
    
        % above/below-baseline response during the production period
        [~, resp.p_prod(ichan)] = ttest2(resp.prod{ichan}(good_gotrials), zeros_vec); 

        % test for general task responsivity
        %%%% one way to make this metric more stringent would be: run anova on mean response in 4 periods: baseline, stim, prep, speech
        resp.p_min_stim_prep_prod(ichan) = min([resp.p_stim(ichan), resp.p_prep(ichan), resp.p_prod(ichan)]);
        resp.rspv(ichan) = resp.p_min_stim_prep_prod(ichan) < responsivity_alpha; 

         % preferential response for learning condition(s)
        resp.p_prep_learn(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.learn_con(good_gotrials),'off');
        resp.p_prod_learn(ichan) = anova1(resp.prod{ichan}(good_gotrials),trials.learn_con(good_gotrials),'off');
    
        % preference for native vs nonnative
         resp.p_prep_nn_v_nat(ichan) = anova1(resp.prep{ichan}(good_gotrials),is_native_trial(good_gotrials),'off');
            resp.sign_prep_nn_minus_nat(ichan) = sign( nanmean(prep_resp_nonnative) - nanmean(prep_resp_nat) ); 
        resp.p_prod_nn_v_nat(ichan) = anova1(resp.prod{ichan}(good_gotrials),is_native_trial(good_gotrials),'off');
            resp.sign_prod_nn_minus_nat(ichan) = sign( nanmean(prod_resp_nonnative) - nanmean(prod_resp_nat) ); 

         % preference for novel nonnative vs. trained nonnative (effect of training occurring only during Training phase... no natives)
         [~, resp.p_prep_novel_vs_trained(ichan)] = ttest2( prep_resp_novel, prep_resp_trained );      
            resp.sign_prep_novel_minus_trained(ichan) = sign( nanmean(prep_resp_novel) - nanmean(prep_resp_trained) ); 
         [~, resp.p_prod_novel_vs_trained(ichan)] = ttest2( prod_resp_novel, prod_resp_trained );      
            resp.sign_prod_novel_minus_trained(ichan) = sign( nanmean(prod_resp_novel) - nanmean(prod_resp_trained) ); 

         % preference for native vs nonnative novel (most well-leared vs. least well-learned)
         [~, resp.p_prep_novel_vs_nat(ichan)] = ttest2( prep_resp_novel, prep_resp_nat );      
            resp.sign_prep_novel_minus_nat(ichan) = sign( nanmean(prep_resp_novel) - nanmean(prep_resp_nat) ); 
         [~, resp.p_prod_novel_vs_nat(ichan)] = ttest2( prod_resp_novel, prod_resp_nat );      
            resp.sign_prod_novel_minus_nat(ichan) = sign( nanmean(prod_resp_novel) - nanmean(prod_resp_nat) ); 
    
         % preferential response for specific stim
        resp.p_stim_syl(ichan) = anova1(resp.stim{ichan}(good_trials),trials.word(good_trials),'off'); % include stop trials
        resp.p_prep_syl(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.word(good_gotrials),'off');
        resp.p_prod_syl(ichan) = anova1(resp.prod{ichan}(good_gotrials),trials.word(good_gotrials),'off');

        resp.p_stim_rime(ichan) = anova1(resp.stim{ichan}(good_trials),trials.rime(good_trials),'off'); % include stop trials
        resp.p_prep_rime(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.rime(good_gotrials),'off'); 
        resp.p_prod_rime(ichan) = anova1(resp.prod{ichan}(good_gotrials),trials.rime(good_gotrials),'off');

       
    end

    

end
    
%% cleanup
elec_info_overlapping_resptable = elc_info(ismember(elc_info.chan,resp.chan),:); % include only electrodes analyzed for dbsseq

% add the following variables to the electrodes response table... use 'electrode' as key variable
info_vars_to_copy = {'chan','type','native_x','native_y','native_z',...
    'mni_x','mni_y','mni_z',...
	'DISTAL_label_1','DISTAL_weight_1','DISTAL_label_2','DISTAL_weight_2','DISTAL_label_3','DISTAL_weight_3',...
    'HCPMMP1_label_1','HCPMMP1_weight_1','HCPMMP1_label_2','HCPMMP1_weight_2'};
resp = join(resp, elec_info_overlapping_resptable(:,info_vars_to_copy)); % add elc_info to resp
resp.sub = cellstr(repmat(SUBJECT, nchans, 1));
resp = movevars(resp,{'base','timecourse','stim','prep','prod'},'After','HCPMMP1_weight_2');
resp = movevars(resp,{'sub','chan','HCPMMP1_label_1'},'Before',1);
