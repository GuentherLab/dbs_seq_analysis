% Detect artifacts, create an artifact annotation table

% function P09_detect_artifact_criteria_E(SUBJECT, param)

%% load packages
ft_defaults
bml_defaults
format long

%% Defining paths, loading parameters
SUBJECT='DM1006';
SESSION = 'intraop';
TASK = 'smsl'; 

%%% choose an artifact criterion version
ARTIFACT_CRIT = 'E'; % 70-250hz high gamma; identifier for the criteria implemented in this script
% ARTIFACT_CRIT = 'F'; % beta ; identifier for the criteria implemented in this script
% ARTIFACT_CRIT = 'G'; %identifier for the criteria implemented in this script



HIGH_PASS_FILTER = 'yes'; %should a high pass filter be applied
HIGH_PASS_FILTER_FREQ = 1; %cutoff frequency of high pass filter
do_bsfilter = 'yes'; 
line_noise_harm_freqs=[60 120 180 240]; % for notch filters for 60hz harmonics
SAMPLE_RATE = 100; % downsample rate in hz for high gamma traces

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

PATH_ART_PROTOCOL = ['Y:\DBS\groupanalyses\task-smsl\A09_artifact_criteria_', ARTIFACT_CRIT];


PATH_FIGURES = [PATH_ART_PROTOCOL filesep 'figures']; 

cd(PATH_DER_SUB)

artifact_annot_path = ['annot/' 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_artifact-criteria-' ARTIFACT_CRIT '.tsv'];

session= bml_annot_read_tsv(['annot/sub-' SUBJECT '_sessions.tsv']);
electrodes = bml_annot_read_tsv(['annot/sub-' SUBJECT '_electrodes.tsv']);
channels = bml_annot_read_tsv(['annot/sub-' SUBJECT '_ses-' SESSION '_channels.tsv']); %%%% for connector info
    channels.name = strrep(channels.name,'_Ll','_Lm'); % change name to match naming convention in electrodes table
[~, ch_ind] = intersect(channels.name, electrodes.name,'stable');
electrodes = join(electrodes,channels(ch_ind,{'name','connector'}) ,'keys','name'); %%% add connector info


%% Loading FieldTrip data 
load([PATH_FIELDTRIP filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_ft-raw.mat'],'D','loaded_epoch');
nTrials = numel(D.trial);

%remasking nans with zeros
cfg=[];
cfg.value=0;
cfg.remask_nan=true;
D=bml_mask(cfg,D);

% % % % % % % % % % % % %% working in protocol folder
% % % % % % % % % % % % cd(PATH_PROTOCOL)

%% loading electrode type band table
if ~exist('el_band','var')
  param = readtable([PATH_ART_PROTOCOL, filesep, 'artifact_', ARTIFACT_CRIT , '_params.tsv'],'FileType','text');
  param_default = param(param.subject == "default",:);
  param_subject = param(strcmp(param.subject,SUBJECT),:);
  if ~isempty(param_subject)
    param = bml_annot_rowbind(param_default(~ismember(param_default.name,param_subject.name),:),param_subject);
  end
end

%% Applying High Pass Filter
cfg=[];
cfg.hpfilter=HIGH_PASS_FILTER;
cfg.hpfreq=HIGH_PASS_FILTER_FREQ;
cfg.hpfilttype='but';
cfg.hpfiltord=5;
cfg.hpfiltdir='twopass';
cfg.bsfilter=do_bsfilter;
cfg.bsfreq= [line_noise_harm_freqs-1; line_noise_harm_freqs+1]'; % notch filters for 60hz harmonics
cfg.channel={'ecog_*','macro_*','micro_*','dbs_*'};
D_hpf = ft_preprocessing(cfg,D);

%% Artifact rejection - ECoG channels 
% iterating over bands and electrode types
artifact = table();
hfig = figure();
for idx = 1:height(param)
  
  fprintf('doing %s %s \n',SUBJECT,param.name{idx});
  el_type = strip(param.electrode_type{idx});
    wav_width = param.wav_width(idx);
  env_mult_factor =  param.env_mult_factor(idx);
  pname = strip(param.name{idx});
  
  ENVELOPE_BIN_SIZE_SECONDS = param.env_bin_size(idx); %envelope bin size in seconds
  THRESHOLD_STD_FACTORS = [param.th_factor_std_low(idx), param.th_factor_std_high(idx)]; %factors to determine detection thresholds 
  THRESHOLD_FIX = [param.th_fix_min(idx), param.th_fix_max(idx)]; %fix thresholds to filter data before applying robust estimates
  CONSOLIDATION_TIME_TOLERANCE = param.th_consolidation(idx); %min time allowed between consecutive artifacts
  ELECTRODE_COVERAGE_THRESHOLD = param.th_frac_coverage(idx); %max allowed fraction of time with artifacts
  CONNECTOR_THRESHOLD = [param.th_conn_low(idx), param.th_conn_high(idx)]; %detection threshold for number of electrodes in a connector  
  
  %selecting channels for artifact rejection
  cfg=[];
  cfg.channel = [el_type,'_*'];
  D_hpf_eltype = ft_selectdata(cfg,D_hpf);

  if isempty(D_hpf_eltype.label)
    %channel type not available
    continue
  end

% compute log-spaced frequencies between wav_freq_min and wav_freq_max
    nfreqs = param.n_wav_freqs(idx); 
    wav_freqs = round(logspace(log10(param.wav_freq_min(idx)),log10(param.wav_freq_max(idx)),nfreqs));
    D_multifreq_eltype = cell(nfreqs,1);
    
    normed_pow = cell(1,nTrials); 
    for ifreq = 1:nfreqs
      %calculating absolute value envelope at 1Hz (1s chunks)
      cfg=[];
      cfg.out_freq = 100;
      cfg.wav_freq = wav_freqs(ifreq);
      cfg.wav_width = wav_width;
      D_multifreq_eltype{ifreq} = bml_envelope_wavpow(cfg,D_hpf_eltype);
      
      nchannels = length(D_multifreq_eltype{ifreq}.label);
      D_multifreq_eltype{ifreq}.med_pow_per_block = NaN(nchannels, nTrials); % initialize
      for iblock = 1:nTrials % for each block, normalize by median power
        % rows are channels, so take the median across columns (power at timepoints for each channel)
          D_multifreq_eltype{ifreq}.med_pow_per_block(:,iblock) = median(D_multifreq_eltype{ifreq}.trial{iblock},2);
          % normalize power by median values within each channel for this block
          %%% normed_pow will be filled with all normed powers across blocks and frequencies; we will average across the 3rd dimension (frequency)
          normed_pow{iblock}(:,:,ifreq) = D_multifreq_eltype{ifreq}.trial{iblock} ./ D_multifreq_eltype{ifreq}.med_pow_per_block(:,iblock);
      end
    end
    
    D_hg_eltype = struct; % averaged high gamma
        D_hg_eltype.hdr = D_multifreq_eltype{1}.hdr;
        D_hg_eltype.trial = D_multifreq_eltype{1}.trial;
        D_hg_eltype.sampleinfo = D_multifreq_eltype{1}.sampleinfo;
        D_hg_eltype.trial = cell(1,nTrials); % to be filled
        D_hg_eltype.time = D_multifreq_eltype{1}.time;
        D_hg_eltype.label = D_multifreq_eltype{1}.label;
    % get averaged high gamma
    for iblock = 1:nTrials
        D_hg_eltype.trial{iblock} = mean(normed_pow{iblock},3);
    end
%     clear D_multifreq_eltype normed_pow

%   cfg=[];
%   cfg.viewmode = 'vertical';
%   cfg.blocksize = 30;
%   cfg.ylim = 'maxmin';
%   cfg.continuous = 'yes';
%   ft_databrowser(cfg,D_hpf_ecog_env);

  cfg=[];
  cfg.freq = 1/ENVELOPE_BIN_SIZE_SECONDS;
  D_hg_eltype_env = bml_envelope_binabs(cfg,D_hg_eltype);

  %calculating log10 transform (envelopes have log normal distributions)
  D_hg_eltype_env_log10 = bml_apply(@(x) env_mult_factor .* log10(x),D_hg_eltype_env);
  
  cfg=[];
  cfg.remask_inf=true;
  cfg.value=NaN;
  D_hg_eltype_env_log10 = bml_mask(cfg,D_hg_eltype_env_log10);
  
  %calculating distribution robust statistics. 
  THRESHOLD = nan(nTrials,2);
  max_v=nan(1,nTrials);
  min_v=nan(1,nTrials);
  for itrial=1:nTrials
    v = reshape(D_hg_eltype_env_log10.trial{itrial},1,[]);
    v1 = v((v>THRESHOLD_FIX(1)) & (v<THRESHOLD_FIX(2)));
    m = median(v1);
    std = bml_robust_std(v1);
    if ~isempty(v1)
      max_v(itrial)=max(v);
      min_v(itrial)=min(v);
      THRESHOLD(itrial,:) = m + THRESHOLD_STD_FACTORS.*std;
    end
  end

  %plotting histogram to assess threshold levels
  if ~isempty(v1)
      clf(hfig); set(hfig,'Position',[0 0 600 600]);
      for itrial=1:nTrials
        subplot(ceil(nTrials/2),2,itrial)
        hold on;
        h=histogram(D_hg_eltype_env_log10.trial{itrial},linspace(min(min_v),max(max_v),61),...
          'FaceAlpha',0.1,'EdgeAlpha',1);
        maxBinCount = max(h.BinCounts);
        plot([THRESHOLD(itrial,1),THRESHOLD(itrial,1)],[0,maxBinCount .* 1.1]);
        plot([THRESHOLD(itrial,2),THRESHOLD(itrial,2)],[0,maxBinCount .* 1.1]);
        %set(gca,'YScale','log')
        title(['session ' num2str(itrial)]);
      end
      %saveas(hfig,[PATH_FIGURES filesep SUBJECT '_' pname '_artifact_env_log10_hist.png'])
  elseif isempty(v1)
      warning(['For electrode type ''', el_type, ''' (sub ', SUBJECT, '), no timepoints found between low threshold (', ...
          num2str(THRESHOLD_FIX(1)), ') and high threshold (', num2str(THRESHOLD_FIX(2)), ')'])
  end

  %detecting segments of time for each channel above threshold
  artifact_eltype_1 = table();
  for itrial=1:nTrials
    cfg=[];
    cfg.threshold = THRESHOLD(itrial,:);
    cfg.trials = itrial;
    artifact_eltype_1 = bml_annot_rowbind(artifact_eltype_1, bml_annot_detect(cfg,D_hg_eltype_env_log10));
  end

  if isempty(artifact_eltype_1)
    continue
  end
  
  %making figure with random snippets of detected artifacts
  cfg=[];
  cfg.n = 1;
  cfg.groupby  = 'label';
  artifact_eltype_1_sample = bml_annot_sample(cfg, artifact_eltype_1);
  artifact_eltype_1_sample = bml_annot_extend(artifact_eltype_1_sample,2,2);

  cfg=[];
  cfg.n = 60;
  artifact_eltype_1_sample = bml_annot_sample(cfg, artifact_eltype_1_sample);
  
  cfg=[];
  cfg.epoch = artifact_eltype_1_sample;
  [D_hpf_eltype_sample, epoch_hpf_eltype_sample] = bml_redefinetrial(cfg,D_hpf_eltype);
 
  D_p = D_hpf_eltype_sample;
  E_p = epoch_hpf_eltype_sample;
  nx=10; ny=floor(numel(D_p.trial)/nx);
  if ny==0
    ny=1; nx=numel(D_p.trial);
  end
  clf(hfig); set(hfig,'Position',[0 0 nx*200 ny*200]);
  for itrial=1:ny
      for j=1:nx
          pidx = (itrial-1)*nx+j;
          l = E_p.label(pidx);
          l_idx = bml_getidx(l,D_p.label);
          subplot(ny,nx,pidx);
          plot(D_p.time{pidx},D_p.trial{pidx}(l_idx,:));
          title(E_p.label(pidx));
      end
  end
  %saveas(hfig,[PATH_FIGURES filesep SUBJECT '_' pname '_artifact_snippets.png'])

  
  %consolidating annotations with CONSOLIDATION_TIME_TOLERANCE margin of overlap
  cfg=[];
  cfg.criterion = @(x) (x.starts(end) - max(x.ends(1:(end-1))) < CONSOLIDATION_TIME_TOLERANCE);
  cfg.groupby = 'label';
  artifact_eltype_2 = bml_annot_consolidate(cfg,artifact_eltype_1);

%   %creating ft_raw from annotations for visualization
%   cfg=[];
%   cfg.template = D_hpf_eltype_env_log10;
%   cfg.annot_label_colname='label';
%   artifact_eltype_3_raw = bml_annot2raw(cfg,artifact_eltype_2);
% 
%   %raster plot of artifacts for session 1
%   f=figure();
%   bml_plot_raster(artifact_eltype_3_raw)

  %check if excluded segments are correct
%   cfg=[];
%   cfg.label_colname = 'label';
%   cfg.annot = artifact_eltype_2;
%   cfg.value = NaN;
%   D_hpf_eltype_mask = bml_mask(cfg, D_hpf_eltype);
% 
%   cfg=[];
%   cfg.viewmode = 'vertical';
%   cfg.blocksize = 30;
%   cfg.ylim = 'maxmin';
%   cfg.continuous = 'yes';
%   ft_databrowser(cfg,D_hpf_eltype_mask);

  %% rejecting faulty channels 

  %decide which artifacts to include. Usually just ECoG artifacts
  %artifact = bml_annot_rowbind(artifact_ecog_3,artifact_macro_3,artifact_dbs_3);
  artifact_1 = artifact_eltype_2;


  cfg = [];
  cfg.groupby = 'label';
  artifact_1_session_cvg = bml_annot_coverage(cfg,artifact_1,session);

  %histogram(artifact_1_session_cvg.coverage,linspace(0,1,51))

  %if a channel in a session has more than COVERAGE_THRESHOLD of the time with
  %artifacts, the entire channel gets rejected for that session

  artifact_1_session_cvg_sel = artifact_1_session_cvg(artifact_1_session_cvg.coverage >= ELECTRODE_COVERAGE_THRESHOLD,:);
  artifact_2 = bml_annot_rowbind(artifact_1,artifact_1_session_cvg_sel);
  cfg=[];
  cfg.groupby = 'label';
  artifact_2 = bml_annot_consolidate(cfg,artifact_2);

%   %creating ft_raw from annotations for visualization
%   cfg=[];
%   cfg.template = D_hpf_env;
%   cfg.annot_label_colname='label';
%   artifact2_raw = bml_annot2raw(cfg,artifact_2);
% 
%   %raster plot of artifacts for session 1
%   f=figure();
%   bml_plot_raster(artifact2_raw)

  %% checking coverage per connector group
  %if several channels of the same connector group have an artifact, reject
  %the entire connector group

  %adding connector information to artifac annotation table
  electrodes.conn_label = strcat({'conn'},num2str(electrodes.connector));
  artifact_2.conn_label = bml_map(artifact_2.label, electrodes.name, electrodes.conn_label);

% 	%calculating absolute value envelope at 1Hz (1s chunks)
%   cfg=[];
%   cfg.freq=ENVELOPE_BIN_SIZE_SECONDS;
%   D_hpf_env = bml_envelope_binabs(cfg,D_hpf);

  %for each connector and bin, count number of faulty channels
  cfg=[];
  cfg.roi = bml_raw2annot(D_hg_eltype_env);
  cfg.annot_label_colname = 'conn_label';
  connector_artifact_2_cvg_raw = bml_annot2raw(cfg,artifact_2);

%   f=figure();
%   cfg.colorbar = true;
%   bml_plot_raster(cfg,connector_artifact_2_cvg_raw)

  %detecting faulty connectors
  cfg=[];
  cfg.threshold = CONNECTOR_THRESHOLD;
  connector_artifact_3 = bml_annot_detect(cfg,connector_artifact_2_cvg_raw);

  if ~isempty(connector_artifact_3)
    %for each period a connector is faulty, create table with all channels
    %corresponding to that connctor
    cfg=[];
    cfg.groupby_x='conn_label'; %grouping variable in electrode table
    cfg.groupby_y='label'; %corresponding grouping variable in connector_artifact_3
    artifact_4=bml_annot_intersect(cfg,electrodes,connector_artifact_3);

    if ~isempty(artifact_4)
      %combining with previously detected artifacts
      artifact_4.label = artifact_4.name;
      artifact_5 = bml_annot_rowbind(artifact_2, artifact_4);
      cfg=[];
      cfg.groupby = 'label';
      artifact_5 = bml_annot_consolidate(cfg,artifact_5);
    else
      artifact_5 = artifact_2;
    end
  else
    artifact_5 = artifact_2;
  end

  %final raster plot for artifacts
  cfg=[];
  cfg.template = D_hg_eltype_env;
  cfg.annot_label_colname = 'label';
  artifact_5_raw = bml_annot2raw(cfg,artifact_5);

  clf(hfig); set(hfig,'Position',[0 0 600 600]);
  cfg.trial_name='session';
  bml_plot_raster(cfg,artifact_5_raw)
  saveas(hfig,[PATH_FIGURES filesep SUBJECT '_' pname '_artifact_mask.png'])

  artifact_5.pname = repmat({pname},height(artifact_5),1);
  
%% saving  artifact annotation table
  artifact = bml_annot_rowbind(artifact,...
    artifact_5(:,{'id','starts','ends','duration','label','conn_label','pname'}));
  
end




%archiving 
if isfile(artifact_annot_path)
  copyfile(artifact_annot_path,...
        [PATH_ANNOT filesep 'archive' filesep SUBJECT '_artifact-criteria-' ARTIFACT_CRIT '_' datestr(now,'yyyymmdd_HHMM') '.tsv'])
end

writetable(artifact,['annot/sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_artifact-criteria-' ARTIFACT_CRIT '.tsv'], 'delimiter','\t', 'FileType','text');


