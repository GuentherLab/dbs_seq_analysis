% get high gamma timecourses for each trial, using high gamma definition from artifact criterion E
% 
% run this script after common average rereferencing has been performed
%
% AM 

function compute_high_gamma_trials(SUBJECT,ft_file,artifact,fieldtrip_savename)

% Loading packages
ft_defaults
bml_defaults
format long

%% Defining paths, loading parameters
SUBJECT='DM1008';
SESSION = 'intraop';
TASK = 'smsl'; 
ARTIFACT_CRIT = 'E'; 
SAMPLE_RATE = 100; % downsample rate in hz for high gamma traces

PATH_DATASET = 'Y:\DBS';
PATH_DER = [PATH_DATASET filesep 'derivatives'];
PATH_DER_SUB = [PATH_DER filesep 'sub-' SUBJECT];  
PATH_PREPROC = [PATH_DER_SUB filesep 'preproc'];
PATH_ANNOT = [PATH_DER_SUB filesep 'annot'];
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

PATH_ART_PROTOCOL = 'Y:\DBS\groupanalyses\task-smsl\A09_artifact_criteria_E';

fieldtrip_savename = ['fieldtrip/' 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_ft-hg-trial-criteria-E.mat'];

cd(PATH_DER_SUB)

% load timing and electrode data
artifact = bml_annot_read_tsv(['annot/' 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_artifact-criteria-' ARTIFACT_CRIT '.tsv']);
art_param = readtable([PATH_ART_PROTOCOL, filesep, 'artifact_', ARTIFACT_CRIT , '_params.tsv'],'FileType','text'); % artifact-finding parameters
trials = bml_annot_read_tsv(['annot/' 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_annot-trials.tsv']);
electrodes = bml_annot_read_tsv(['annot/' 'sub-' SUBJECT '_electrodes.tsv']);
channels = bml_annot_read_tsv(['annot/sub-' SUBJECT '_ses-' SESSION '_channels.tsv']); %%%% for connector info
[~, ch_ind] = intersect(channels.name, electrodes.name,'stable');
electrodes = join(electrodes,channels(ch_ind,{'name','connector'}) ,'keys','name'); %%% add connector info


% % % Load FieldTrip raw data - artifact-masked and rereferenced
ft_file = ['fieldtrip/' 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_ft-raw-filt-trial-ar-ref.mat'];
load(ft_file);
ntrials_raw = numel(D_trial_ref.trial);

%remasking nans with zeros
cfg=[];
cfg.value=0;
cfg.remask_nan=true;
D_trial_ref=bml_mask(cfg,D_trial_ref);
 
%% 
% use artifact-detection parameters to re-compute high gamma
n_eltypes = height(art_param);
for i_eltype = 1:n_eltypes % handle each electrode type 
% compute log-spaced frequencies between wav_freq_min and wav_freq_max

  fprintf('doing %s %s \n',SUBJECT,art_param.name{i_eltype});
  
  el_type = strip(art_param.electrode_type{i_eltype});
  wav_width = art_param.wav_width(i_eltype);
  env_mult_factor =  art_param.env_mult_factor(i_eltype);
  pname = strip(art_param.name{i_eltype});

  % run each electrode type individually, in case different parameters were used during artifact detection
  cfg=[];
  cfg.channel = [el_type,'_*'];
  D_trial_ref_eltype = ft_selectdata(cfg,D_trial_ref); 
  
    nfreqs = art_param.n_wav_freqs(i_eltype); 
    nchannels = length(D_trial_ref_eltype.label);
    wav_freqs = round(logspace(log10(art_param.wav_freq_min(i_eltype)),log10(art_param.wav_freq_max(i_eltype)),nfreqs));
    D_multifreq_eltype = cell(nfreqs,1);
    
    normed_pow = cell(1,ntrials_raw); 
    med_pow = NaN(nchannels,ntrials_raw,nfreqs);
    for ifreq = 1:nfreqs
      %calculating absolute value envelope
      cfg=[];
      cfg.out_freq = SAMPLE_RATE;
      cfg.wav_freq = wav_freqs(ifreq);
      cfg.wav_width = wav_width;
      cmd  = 'D_multifreq_eltype{ifreq} = bml_envelope_wavpow(cfg,D_trial_ref_eltype);';
        evalc(cmd); % use evalc to suppress console output
      
      
      D_multifreq_eltype{ifreq}.med_pow_per_block = NaN(nchannels, ntrials_raw); % initialize
      for iblock = 1:ntrials_raw % for each block, normalize by median power
        % rows are channels, so take the median across columns (power at timepoints for each channel)
          D_multifreq_eltype{ifreq}.med_pow_per_block(:,iblock) = median(D_multifreq_eltype{ifreq}.trial{iblock},2);
          % normalize power by median values within each channel for this block
          %%% normed_pow will be filled with all normed powers across blocks and frequencies; we will average across the 3rd dimension (frequency)
          normed_pow{iblock}(:,:,ifreq) = D_multifreq_eltype{ifreq}.trial{iblock} ./ D_multifreq_eltype{ifreq}.med_pow_per_block(:,iblock);
      end
      med_pow(:,:,ifreq) = D_multifreq_eltype{ifreq}.med_pow_per_block; % median powers per block/channel in this freq
    end
    
    D_hg_eltype{i_eltype} = struct; % initialize; averaged high gamma
        D_hg_eltype{i_eltype}.hdr = D_multifreq_eltype{1}.hdr;
        D_hg_eltype{i_eltype}.trial = D_multifreq_eltype{1}.trial;
        D_hg_eltype{i_eltype}.trial = cell(1,ntrials_raw); % to be filled
        D_hg_eltype{i_eltype}.time = D_multifreq_eltype{1}.time;
        D_hg_eltype{i_eltype}.label = D_multifreq_eltype{1}.label;
   
    % get averaged high gamma
    med_pow_mean = mean(med_pow,3); % channel/block median powers, averaged across frequencies of interest
    for iblock = 1:ntrials_raw
        D_hg_eltype{i_eltype}.trial{iblock} = mean(normed_pow{iblock},3);
        
% % % % % % % % % % % % %         % multiply the [channel/block]-specific median powers back, to differentiate between absolute power values of channels
% % % % % % % % % % % % %         D_hg_eltype{i_eltype}.trial{iblock} = D_hg_eltype.trial{iblock} .* med_pow_mean(:,iblock); 
    end
    clear D_multifreq_eltype normed_pow
end

% combine electrode types
cfg = [];
D_hg = ft_appenddata(cfg, D_hg_eltype{:});

save(fieldtrip_savename, 'D_hg','-v7.3');






