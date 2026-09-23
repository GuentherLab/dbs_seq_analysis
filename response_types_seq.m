% compute eletrode responses during specific trial epochs
% look for electrodes with different responses to different conditions

% clear

function [resp, trials, op_out] = response_types_seq(op)

%% analysis parameters

% for defining nonwarped trial timecourse durations, use this much time before/after visual onset/offset
%%% this only affects how much data on each side gets saved for the purposes of plotting
field_default('op','trial_time_buffer',[1, 2.5]); % use 2 sec because subjects in DAF often keeep speaking for a while after visual offset

% consider electrodes responsive if they have above-baseline responses during one response epoch at this level
field_default('op','responsivity_alpha',0.05); % uncorrected
% field_default('op','responsivity_alpha',0.05 / 2^[3-1]); % bonf correction for 3 tests


%% Defining paths, loading parameters
setpaths_dbs_seq();
field_default('op','resp_signal','hg'); 
field_default('op','baseline_method','subtract_then_divide'); % options: 'divide_then_subtract','subtract'
field_default('op','max_timecourse_base_ratio',50); % in each trial, if ratio of timecourse avg to baseline is higher than this, exclude the trial

SESSION = 'intraop';
TASK = 'smsl'; 
PATH_DER_SUB = [PATH_DER filesep 'sub-' op.sub];  
PATH_PREPROC = [PATH_DER_SUB filesep 'preproc'];
PATH_ANNOT = [PATH_DER_SUB filesep 'annot'];
PATH_FIELDTRIP = [PATH_DER_SUB filesep 'fieldtrip']; % fieldtrip data, not fieldtrip code
PATH_ELECTRODES = [PATH_ANNOT filesep 'sub-' op.sub '_electrodes.tsv']; 

PATH_SRC_SUB = [PATH_SRC filesep 'sub-' op.sub];  
PATH_SRC_SESS = [PATH_SRC_SUB filesep 'ses-' SESSION]; 
PATH_AUDIO = [PATH_SRC_SESS filesep 'audio']; 
PATH_TASK = [PATH_SRC_SESS filesep 'task']; 


%% load data 
load([PATH_FIELDTRIP, filesep, 'sub-', op.sub, '_ses-', SESSION, '_task-', TASK,...
    '_ft-', op.resp_signal, '.mat'],'D_wavpow')

% % trial timing info
trials_file_beh = [PATH_ANNOT, filesep, 'sub-' op.sub, '_ses-', SESSION, '_task-',TASK,'_annot-produced-syllables.tsv'];
trials = bml_annot_read_tsv(trials_file_beh);
trials_with_stim_timing = bml_annot_read_tsv([PATH_ANNOT, filesep, 'sub-', op.sub, '_ses-', SESSION, '_task-',...
    TASK, '_annot-trials.tsv']);

stim_info = load_seq_stim_info(PATH_STIM_INFO_TABLE); % list of phonemes for all stim

%% get responses in predefined epochs

%%% set up the config table for determining how to epoch ephys responses for this project
% NB: strongly recommended to not include any expected gaps between epochs, and have dur_fix('trial') equal to the sum of the durations of the other epochs
...... or else subsequent time labels on trial plots will likely be wrong
% all response values except 'base' are baseline-normalized by dividing by that trial's baseline average... 'base' records the absolute value of the baseline
% 
%%%% for baseline window in dbsseq, we measure from aud onset, 
......     even though the intended target for baseline is slightly before vis onset, because some subjects (DM1047) are missing some vis onset timing market
......     and we know that audio onset very reliably comes 1sec after visual onest
%%% baseline should end at least a few 100ms before visual stim onset in order to not include anticipatory activity in baseline
epochs = table({'prebase';'base';'postbase';'visual_stim';'vis_audio_stim';'delay';'prep';'speech';'postprod'},'VariableNames',{'epoch'});
epochs.Properties.RowNames = epochs.epoch;
epochs.onset = cell(height(epochs),1);
epochs.offset = cell(height(epochs),1);
epochs.dur_fix = nan(height(epochs),1); 
epochs.dur_fix('prebase') = 0.6;
    epochs.onset{'prebase'} = {'t_aud_syl_on',-2};          % pre-base buffer
    epochs.offset{'prebase'} = {'t_aud_syl_on',-1.5};
epochs.dur_fix('base') = 0.4;
    epochs.onset{'base'} = {'t_aud_syl_on',-1.5};          % 'base' = average during pre-visual-stim baseline
    epochs.offset{'base'} = {'t_aud_syl_on',-1.1};
epochs.dur_fix('postbase') = 0.1;
    epochs.onset{'postbase'} = {'t_aud_syl_on',-1.1};          % spacer between baseline and vis stim on
    epochs.offset{'postbase'} = {'t_aud_syl_on',-1};
epochs.dur_fix('visual_stim') = 1;                      % vis-stim-only; next epoch is both vis and aud
    epochs.onset{'visual_stim'} = {'t_aud_syl_on',-1}; 
    epochs.offset{'visual_stim'} = {'t_aud_syl_on',0}; 
epochs.dur_fix('vis_audio_stim') = 0.38; %%% times when both visual and auditory stim are on; actual aud stim file length is 380ms
    epochs.onset{'vis_audio_stim'} =  't_aud_syl_on'; 
    epochs.offset{'vis_audio_stim'} = 't_aud_syl_off';
epochs.dur_fix('delay') = 0.8; % approx time between audio stim offset and go beep onset; has +-250ms jitter
    epochs.onset{'delay'} = 't_aud_syl_off'; 
    epochs.offset{'delay'} = 't_aud_go_on'; 
epochs.dur_fix('prep') = 0.7; % estimated reaction time - between go-on and speech osnet
    epochs.onset{'prep'} = 't_aud_go_on'; 
    epochs.offset{'prep'} = 't_prod_on'; 
epochs.dur_fix('speech') = 0.5; % approx avg speech duration... stim audio target = 380ms
    epochs.onset{'speech'} = 't_prod_on'; 
    epochs.offset{'speech'} = 't_prod_off'; 
    epochs.early_overlap_allowed('speech') = true; % we allow the speech epoch to consume preceding epochs; we don't have enough trials to throw out early response trials
epochs.dur_fix('postprod') = 2;             % post speech epoch - look for beta rebound here
    epochs.onset{'postprod'} = {'t_prod_off',0}; 
    epochs.offset{'postprod'} = {'t_prod_off',2}; 
    
op.epochs = epochs; 


% 'base' = average durng pre-visual-stim baseline
% all response values except 'base' are baseline-normalized by dividing by that trial's baseline average... 'base' records the absolute value of the baseline
ntrials = height(trials);
nchans = length(D_wavpow.label);
nans_tr = nan(ntrials,1); 
cel_tr = cell(ntrials,1); 

% info about our trial timing analysis window
trials = renamevars(trials,{'starts','ends','duration'}, {'t_prod_on','t_prod_off','dur_prod'}); % make it clear that these times demarcate speech production window
trials.id = [];
trials.t_vis_syl_on = trials_with_stim_timing.visual_onset; % these are nan for half of trials in DM1047
trials.t_aud_syl_on = trials_with_stim_timing.audio_onset;
trials.t_aud_syl_off = trials_with_stim_timing.audio_offset;
trials.t_aud_go_on = trials_with_stim_timing.audio_go_onset;
trials.t_aud_go_off = trials_with_stim_timing.audio_go_offset;
trials.starts = trials.t_aud_syl_on - epochs.dur_fix('base'); % trial starts at beginning of baseline window - before vis onset, which comes 1sec earlier than audio stim in dbsseeq 
trials.ends = trials.t_prod_off + epochs.dur_fix('postprod'); % trial ends at fixed time after voice offset
trials.duration = trials.ends - trials.starts; 
trials.cons = cell(ntrials,3); 
trials.vow = cel_tr; 

% don't bother analyzing stop trials, even though we could theoretically analyze the pre-go-beep portion of the trial
.... it makes epoch logical parsing more confusing to only part of certain trials and the entirety of other trials
op.trials_to_analyze = ~trials.is_stoptrial; 
op.electrodes_file = PATH_ELECTRODES; % provide electrodes file to append info to resp table
[resp, trials] = get_epoched_responses(D_wavpow,trials,op);


% get phonemes on each trial
%%%% trials.times{itrial} use global time coordinates
%%%% ....... start at a fixed baseline window before stim onset
%%%% ....... end at a fixed time buffer after speech offset
for itrial = 1:ntrials % itrial is absolute index across sessions; does not equal "trial_id" from loaded tables
    

    % list individual phonemesresp.vis_audio_stim{ichan}
    trials.cons(itrial,:) = stim_info.consonant(strcmp(trials.word{itrial},stim_info.orthography),:);
    trials.vow(itrial) = stim_info.vowel(strcmp(trials.word{itrial},stim_info.orthography),:);    
    trials.ons_clust{itrial} = strrep(join(trials.cons(1,1:2)),' ',''); 
    trials.rime{itrial} = strcat(trials.vow{itrial},trials.cons{itrial,3}); 

end
trials(:,{'audio_go_offset'}) = []; % renamed/redundant

% rename stim/learning condition variable, get syllable parts, rearrange table
trials.learn_con = cell(ntrials,1);
trials.learn_con(find(trials.stim_condition==1)) = {'nn_train'};
trials.learn_con(find(trials.stim_condition==2)) = {'nn_nov'};
trials.learn_con(find(trials.stim_condition==3)) = {'nat'};
trials = removevars(trials,{'stim_condition','run_id'});
trials = movevars(trials,{'trial_id','learn_con','word_accuracy','seq_accuracy','block_id','rime_error','word','cons','vow','ons_clust','rime'},'Before',1);

%% test for response types 
resp.bad_elc = cellfun(@(x)all(isnan(x)),resp.base);
for ichan = 1:nchans


                        % setup for tuning analysis
    good_trials = resp.good_trial{ichan}; 
    good_gotrials = good_trials & ~trials.is_stoptrial;
    zeros_vec = zeros(nnz(good_trials),1); 
    zeros_vec_gotrials = zeros(nnz(good_gotrials),1); 
    is_novel_trial = strcmp(trials.learn_con,'nn_nov');
    is_trained_trial = strcmp(trials.learn_con,'nn_train');
    is_native_trial = strcmp(trials.learn_con,'nat');

    if nnz(good_gotrials) > 1 % only do stats analysis if channel had >0 good go trials
         stim_resp_novel = resp.vis_audio_stim{ichan}(good_gotrials & is_novel_trial);
         stim_resp_trained = resp.vis_audio_stim{ichan}(good_gotrials & is_trained_trial);
         stim_resp_nonnative = [stim_resp_novel; stim_resp_trained]; 
         stim_resp_nat = resp.vis_audio_stim{ichan}(good_gotrials & is_native_trial);

         prep_resp_novel = resp.prep{ichan}(good_gotrials & is_novel_trial);
         prep_resp_trained = resp.prep{ichan}(good_gotrials & is_trained_trial);
         prep_resp_nonnative = [prep_resp_novel; prep_resp_trained]; 
         prep_resp_nat = resp.prep{ichan}(good_gotrials & is_native_trial);

         prod_resp_novel = resp.speech{ichan}(good_gotrials & is_novel_trial);
         prod_resp_trained = resp.speech{ichan}(good_gotrials & is_trained_trial);
         prod_resp_nonnative = [prod_resp_novel; prod_resp_trained]; 
         prod_resp_nat = resp.speech{ichan}(good_gotrials & is_native_trial);
        
        % above/below-baseline response during the stim period
        [~, resp.p_stim(ichan)] = ttest2(resp.vis_audio_stim{ichan}(good_gotrials), zeros_vec_gotrials); 

        % above/below-baseline response during the prep period
        [~, resp.p_prep(ichan)] = ttest2(resp.prep{ichan}(good_gotrials), zeros_vec); 
    
        % above/below-baseline response during the production period
        [~, resp.p_prod(ichan)] = ttest2(resp.speech{ichan}(good_gotrials), zeros_vec); 

        % test for general task responsivity
        %%%% one way to make this metric more stringent would be: run anova on mean response in 4 periods: baseline, stim, prep, speech
        resp.p_min_stim_prep_prod(ichan) = min([resp.p_stim(ichan), resp.p_prep(ichan), resp.p_prod(ichan)]);
        resp.rspv(ichan) = resp.p_min_stim_prep_prod(ichan) < op.responsivity_alpha; 

         % preferential response for learning condition(s)
        resp.p_stim_learn(ichan) = anova1(resp.vis_audio_stim{ichan}(good_gotrials),trials.learn_con(good_gotrials),'off');
        resp.p_prep_learn(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.learn_con(good_gotrials),'off');
        resp.p_prod_learn(ichan) = anova1(resp.speech{ichan}(good_gotrials),trials.learn_con(good_gotrials),'off');
    
        % preference for native vs nonnative
         resp.p_stim_nn_v_nat(ichan) = anova1(resp.vis_audio_stim{ichan}(good_gotrials),is_native_trial(good_gotrials),'off');
            resp.sign_stim_nn_minus_nat(ichan) = sign( nanmean(stim_resp_nonnative) - nanmean(stim_resp_nat) ); 
        resp.p_prep_nn_v_nat(ichan) = anova1(resp.prep{ichan}(good_gotrials),is_native_trial(good_gotrials),'off');
            resp.sign_prep_nn_minus_nat(ichan) = sign( nanmean(prep_resp_nonnative) - nanmean(prep_resp_nat) ); 
        resp.p_prod_nn_v_nat(ichan) = anova1(resp.speech{ichan}(good_gotrials),is_native_trial(good_gotrials),'off');
            resp.sign_prod_nn_minus_nat(ichan) = sign( nanmean(prod_resp_nonnative) - nanmean(prod_resp_nat) ); 

         % preference for novel nonnative vs. trained nonnative (effect of training occurring only during Training phase... no natives)
         [~, resp.p_stim_novel_vs_trained(ichan)] = ttest2( stim_resp_novel, stim_resp_trained );      
            resp.sign_stim_novel_minus_trained(ichan) = sign( nanmean(stim_resp_novel) - nanmean(stim_resp_trained) ); 
         [~, resp.p_prep_novel_vs_trained(ichan)] = ttest2( prep_resp_novel, prep_resp_trained );      
            resp.sign_prep_novel_minus_trained(ichan) = sign( nanmean(prep_resp_novel) - nanmean(prep_resp_trained) ); 
         [~, resp.p_prod_novel_vs_trained(ichan)] = ttest2( prod_resp_novel, prod_resp_trained );      
            resp.sign_prod_novel_minus_trained(ichan) = sign( nanmean(prod_resp_novel) - nanmean(prod_resp_trained) ); 

         % preference for native vs nonnative novel (most well-leared vs. least well-learned)
         [~, resp.p_stim_novel_vs_nat(ichan)] = ttest2( stim_resp_novel, stim_resp_nat );      
            resp.sign_stim_novel_minus_nat(ichan) = sign( nanmean(stim_resp_novel) - nanmean(stim_resp_nat) ); 
         [~, resp.p_prep_novel_vs_nat(ichan)] = ttest2( prep_resp_novel, prep_resp_nat );      
            resp.sign_prep_novel_minus_nat(ichan) = sign( nanmean(prep_resp_novel) - nanmean(prep_resp_nat) ); 
         [~, resp.p_prod_novel_vs_nat(ichan)] = ttest2( prod_resp_novel, prod_resp_nat );      
            resp.sign_prod_novel_minus_nat(ichan) = sign( nanmean(prod_resp_novel) - nanmean(prod_resp_nat) ); 
    
         % preferential response for specific stim/phonemes
        resp.p_stim_syl(ichan) = anova1(resp.vis_audio_stim{ichan}(good_trials),trials.word(good_trials),'off'); % include stop trials
        resp.p_prep_syl(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.word(good_gotrials),'off');
        resp.p_prod_syl(ichan) = anova1(resp.speech{ichan}(good_gotrials),trials.word(good_gotrials),'off');

        resp.p_stim_rime(ichan) = anova1(resp.vis_audio_stim{ichan}(good_trials),trials.rime(good_trials),'off'); % include stop trials
        resp.p_prep_rime(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.rime(good_gotrials),'off'); 
        resp.p_prod_rime(ichan) = anova1(resp.speech{ichan}(good_gotrials),trials.rime(good_gotrials),'off');

        resp.p_stim_vow(ichan) = anova1(resp.vis_audio_stim{ichan}(good_trials),trials.vow(good_trials),'off'); % include stop trials
        resp.p_prep_vow(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.vow(good_gotrials),'off'); 
        resp.p_prod_vow(ichan) = anova1(resp.speech{ichan}(good_gotrials),trials.vow(good_gotrials),'off');

       for iphon = 1:3
           resp.p_stim_cons(ichan,iphon) = anova1(resp.vis_audio_stim{ichan}(good_trials),trials.cons(good_trials,iphon),'off'); 
            resp.p_prep_cons(ichan,iphon) = anova1(resp.prep{ichan}(good_gotrials),trials.cons(good_gotrials,iphon),'off'); 
            resp.p_prod_cons(ichan,iphon) = anova1(resp.speech{ichan}(good_gotrials),trials.cons(good_gotrials,iphon),'off'); 
       end     
    end
end

resp.p_min_learn = min([resp.p_stim_learn, resp.p_prep_learn, resp.p_prod_learn],[],2);
    
resp.sub = cellstr(repmat(op.sub, nchans, 1));
resp = movevars(resp,{'base','vis_audio_stim','prep','speech'},'After','HCPMMP1_weight_2');
resp = movevars(resp,{'sub','chan','HCPMMP1_label_1'},'Before',1);

% right DBS was not recorded during the SEQ task in these subjects but remained in the channels  table - remove these chans if they're present
resp = resp(~contains(resp.chan,'dbs_R'),:);

% assign region labels
resp = define_brain_regions(resp); 

paths.electrodes = PATH_ELECTRODES;
paths.fieldtrip_ref = [PATH_FIELDTRIP, filesep, 'sub-',op.sub, '_ses-',SESSION, '_task-',TASK, '_ft-raw-filt_ar-',op.art_crit, '_ref.mat']; 
paths.trials_beh = trials_file_beh; 
paths.artifact_manual = [PATH_ANNOT, filesep, 'sub-' op.sub '_ses-' SESSION, '_task-',TASK, '_artifact-manual.tsv']; 
paths.resp = [PATH_RESULTS, filesep, op.sub '_responses_' op.resp_signal];
op.paths = paths; 
op_out = op; 

end


