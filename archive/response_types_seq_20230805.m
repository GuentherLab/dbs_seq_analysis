% look for electrodes with different responses to different conditions
%
% updated by AM 2023/6/25


% Loading packages
ft_defaults
bml_defaults
format long

clear

%% Defining paths, loading parameters
SUBJECT='DM1007';
SESSION = 'intraop';
TASK = 'smsl'; 

%%% CRITERIA E parameter valus
ARTIFACT_CRIT = 'E'; % % use multi-frequency-averaged high gamma

PATH_DATASET = 'Y:\DBS';
PATH_DER = [PATH_DATASET filesep 'derivatives'];
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

PATH_SRC = [PATH_DATASET filesep 'sourcedata'];
PATH_SRC_SUB = [PATH_SRC filesep 'sub-' SUBJECT];  
PATH_SRC_SESS = [PATH_SRC_SUB filesep 'ses-' SESSION]; 
PATH_AUDIO = [PATH_SRC_SESS filesep 'audio']; 
PATHS_TASK = strcat(PATH_SRC_SUB,filesep,{'ses-training';'ses-preop';'ses-intraop'},filesep,'task');

PATH_GROUP_ANALYSES = 'Y:\DBS\groupanalyses\task-smsl';
PATH_GROUP_ANALYSES_GOTRIALS = [PATH_GROUP_ANALYSES filesep 'gotrials']; 
PATH_ART_PROTOCOL = [PATH_GROUP_ANALYSES filesep 'A09_artifact_criteria_E'];
savefile = [PATH_GROUP_ANALYSES_GOTRIALS, filesep, SUBJECT '_responses'];

use_vibration_denoised_data = 0; 



% analysis parameters
%%%% for baseline window, use the period from -base_win_sec(1) to -base_win_sec(2) before stim onset
%%% baseline should end at least a few 100ms before stim onset in order to not include anticipatory activity in baseline
base_win_sec = [1, 0.3]; 
post_speech_win_sec = 0.5; % 

%% load data 
cd(PATH_FIELDTRIP)

if use_vibration_denoised_data
    denoise_str = '_denoised';
elseif ~use_vibration_denoised_data
    denoise_str = '';
end

if ~exist('D_hg','var') % if fieldtrip object not yet loaded
    load([PATH_FIELDTRIP, filesep, 'sub-', SUBJECT, '_ses-', SESSION, '_task-', TASK, '_ft-hg-trial-criteria-', ARTIFACT_CRIT, denoise_str, '.mat'])
end

% trial timing and electrode info
% load([PATH_TRIAL_AUDIO, filesep, 'sub-' SUBJECT, '_ses-', SESSION, '_task-' TASK, '_annot-produced-syllables'], 'trials')
trials = bml_annot_read_tsv([PATH_ANNOT, filesep, 'sub-', SUBJECT, '_ses-', SESSION, '_task-', TASK, '_annot-produced-syllables.tsv']);
trials_with_stim_timing = bml_annot_read_tsv([PATH_ANNOT, filesep, 'sub-', SUBJECT, '_ses-', SESSION, '_task-', TASK, '_annot-trials.tsv']);
elc_info = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_electrodes.tsv';]); 
    elc_info = renamevars(elc_info,'name','chan');

%% get responses in predefined epochs
% 'base' = average durng pre-stim baseline
% all response values except 'base' are baseline-normalized by dividing by that trial's baseline average
ntrials = height(trials);
nchans = length(D_hg.label);
nans_ch = nan(nchans,1); 
nans_tr = nan(ntrials,1); 
cel_tr = cell(ntrials,1); 

% info about our trial timing analysis window
trials = renamevars(trials,{'starts','ends','duration'}, {'t_prod_on','t_prod_off','dur_prod'}); % speech prod timing does not mark our trial boundaries
trials.t_stim_syl_on = trials_with_stim_timing.audio_onset;
trials.t_stim_syl_off = trials_with_stim_timing.audio_offset;
trials.t_stim_gobeep_on = trials_with_stim_timing.audio_go_onset;
trials.t_stim_gobeep_off = trials_with_stim_timing.audio_go_offset;
trials.starts = trials.t_stim_syl_on - base_win_sec(1); % trial starts at beginning of baseline window
trials.ends = trials.t_prod_off + post_speech_win_sec; % trial ends at fixed time after voice offset
trials.duration = trials.ends - trials.starts; 


% table containing responses during epochs for each chan
cel = repmat({nans_tr},nchans,1); % 1 value per trial per chan
resp = table(   D_hg.label, cel,   repmat({cel_tr},nchans,1),  cel,    cel,    cel,    nans_ch,  ....
  'VariableNames', {'chan', 'base', 'timecourse',             'stim', 'prep', 'prod', 'p_prep' }); 

% extract epoch-related responses
%%%% trials.times{itrial} use global time coordinates
%%%% ....... start at a fixed baseline window before stim onset
%%%% ....... end at a fixed time buffer after speech offset
for itrial = 1:ntrials % itrial is absolute index across sessions; does not equal "trial_id" from loaded tables
    iblock = trials.block_id(itrial); 
    trial_id_in_block = trials.trial_id(itrial); % block-relative trial number
    % get indices within the trial-specific set of timepoints of D_hg.time{itrial} that match our specified trial window
    match_time_inds = D_hg.time{itrial} > trials.starts(itrial) & D_hg.time{itrial} < trials.ends(itrial); 
    trials.times{itrial} = D_hg.time{itrial}(match_time_inds); % times in this redefined trial window... still using global time coordinates
    % get trial-relative baseline time indices; window time-locked to first stim onset
    base_inds = D_hg.time{itrial} > trials.starts(itrial) & D_hg.time{itrial} < [trials.t_stim_syl_on(itrial) - base_win_sec(2)]; 

    % baseline activity and timecourse
    for ichan = 1:nchans
        % use mean rather than nanmean, so that trials which had artifacts marked with NaNs will be excluded
        resp.base{ichan}(itrial) = mean( D_hg.trial{itrial}(ichan, base_inds), 'includenan' ); % mean HG during baseline
        % get baseline-normalized trial timecourse
       resp.timecourse{ichan}{itrial} =  D_hg.trial{itrial}(ichan, match_time_inds) - resp.base{ichan}(itrial); 
    end
    
    % preparatory response
    %%%% prep period inds: after stim ends and before syllable prod onset
    prep_inds = D_hg.time{itrial} > trials.t_stim_syl_off(itrial) & D_hg.time{itrial} < trials.t_prod_on(itrial); 
    for ichan = 1:nchans
        resp.prep{ichan}(itrial) = mean( D_hg.trial{itrial}(ichan, prep_inds) ) / resp.base{ichan}(itrial);
    end

    % response during speech production
    prod_inds = D_hg.time{itrial} > trials.t_prod_on(itrial) & D_hg.time{itrial} < trials.t_prod_off(itrial);     
    for ichan = 1:nchans
        resp.prod{ichan}(itrial) = mean( D_hg.trial{itrial}(ichan, prod_inds) ) / resp.base{ichan}(itrial);
    end    
end
trials(:,{'audio_go_offset'}) = []; % renamed/redundant

% rename stim/learning condition variable, rearrange table
trials.learn_con = cell(ntrials,1);
trials.learn_con(find(trials.stim_condition==1)) = {'nn_learn'};
trials.learn_con(find(trials.stim_condition==2)) = {'nn_nov'};
trials.learn_con(find(trials.stim_condition==3)) = {'nat'};
trials = removevars(trials,{'id','stim_condition','run_id'});
trials = movevars(trials,{'trial_id','learn_con','word_accuracy','seq_accuracy','block_id','rime_error'},'Before',1);

%% test for response types 
for ichan = 1:nchans
    good_trials = ~isnan(resp.base{ichan}); % non-artifactual trials for this channel
    good_gotrials = good_trials & ~trials.is_stoptrial;
    is_native_trial = strcmp(trials.learn_con,'nat');
    if nnz(good_trials) == 0; continue; end % skip stats analysis if channel had no good trials
    
    % above-baseline response during the prep period
    [~, resp.p_prep(ichan)] = ttest(resp.prep{ichan}(good_trials), ones(size(resp.prep{ichan}(good_trials)))); 

    % above-baseline response during the production period (go trials only)
    [~, resp.p_prod(ichan)] = ttest(resp.prod{ichan}(good_gotrials), ones(size(resp.prep{ichan}(good_gotrials)))); 

     % preferential response for learning condition(s)
    resp.p_learn(ichan) = anova1(resp.prod{ichan}(good_gotrials),trials.learn_con(good_gotrials),'off');
    resp.p_learn_prep(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.learn_con(good_gotrials),'off');

    % preference for native vs nonnative
     resp.p_nat_v_nn(ichan) = anova1(resp.prod{ichan}(good_gotrials),is_native_trial(good_gotrials),'off');
     resp.p_nat_v_nn_prep(ichan) = anova1(resp.prep{ichan}(good_gotrials),is_native_trial(good_gotrials),'off');


     % preferential response for specific stim
    resp.p_stim_id(ichan) = anova1(resp.prod{ichan}(good_gotrials),trials.word(good_gotrials),'off');
    resp.p_stim_id_prep(ichan) = anova1(resp.prep{ichan}(good_gotrials),trials.word(good_gotrials),'off');


end
    
%% cleanup and save
% eliminate the entries in elc_info which do not match the time in which this experiment took place
electrodes_outside_this_session = elc_info.starts > D_hg.time{1}(1) | elc_info.ends < D_hg.time{end}(end);
elc_info = elc_info(~electrodes_outside_this_session,:);

% add the following variables to the electrodes response table... use 'electrode' as key variable
info_vars_to_copy = {'chan','type','native_x','native_y','native_z',...
    'mni_x','mni_y','mni_z',...
	'DISTAL_label_1','DISTAL_weight_1','DISTAL_label_2','DISTAL_weight_2','DISTAL_label_3','DISTAL_weight_3',...
    'HCPMMP1_label_1','HCPMMP1_weight_1','HCPMMP1_label_2','HCPMMP1_weight_2'};
resp = join(resp, elc_info(:,info_vars_to_copy)); % add elc_info to resp
resp.sub = repmat(SUBJECT, nchans, 1);

save(savefile, 'trials', 'resp')
