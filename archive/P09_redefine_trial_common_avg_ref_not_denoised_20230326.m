% Loading packages
ft_defaults
bml_defaults
format long

%% Defining paths, loading parameters
SUBJECT='DM1008';
SESSION = 'intraop';
TASK = 'smsl'; 

%%% CRITERIA E parameter valus
ARTIFACT_CRIT = 'E'; % % use multi-frequency-averaged high gamma
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

PATH_ART_PROTOCOL = 'Y:\DBS\groupanalyses\task-smsl\A09_artifact_criteria_E';
PATH_FIGURES = [PATH_ART_PROTOCOL filesep 'figures']; 

cd(PATH_DER_SUB)

% load timing and electrode data
artifact = bml_annot_read_tsv(['annot/' 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_artifact-criteria-' ARTIFACT_CRIT '.tsv']);
epoch = bml_annot_read_tsv(['annot/' 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_annot-trials.tsv']);
electrodes = bml_annot_read_tsv(['annot/' 'sub-' SUBJECT '_electrodes.tsv']);
channels = bml_annot_read_tsv(['annot/sub-' SUBJECT '_ses-' SESSION '_channels.tsv']); %%%% for connector info
    channels.name = strrep(channels.name,'_Ll','_Lm'); % change name to match naming convention in electrodes table
[~, ch_ind] = intersect(channels.name, electrodes.name,'stable');
electrodes = join(electrodes,channels(ch_ind,{'name','connector'}) ,'keys','name'); %%% add connector info

% % % Load FieldTrip raw data
load([PATH_FIELDTRIP filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_ft-raw.mat'],'D','loaded_epoch');

% % % Adjusting length of sessions for notch filter to work
D_annot = bml_raw2annot(D);
Fl=[60 120 180 240 300 360 420 480];
D_annot.nSamples2 = round(floor(D_annot.nSamples .* Fl(1)./D_annot.Fs) .* D_annot.Fs./Fl(1));
D_annot.nSamples2 = round(floor(D_annot.nSamples2 .* Fl(1)./D_annot.Fs) .* D_annot.Fs./Fl(1));
D_annot.nSamples2 = D_annot.nSamples2(:,1);
D_annot.ends = D_annot.starts + D_annot.nSamples2 ./ D_annot.Fs;

cfg=[];
cfg.epoch=D_annot;
D1= bml_redefinetrial(cfg,D);


% % % Selecting electrodes and remasking with zeros instead of NaNs

% % % Some of FieldTrip's functions don't work with NaNs, so we are going to temporary replace NaNs with zeros to avoid issues. 

cfg=[];
cfg.channel={'ecog_*','macro_*','micro_*','dbs_*'};
% % %         cfg.trials = logical([1 1 1 1 0]);
D_sel = ft_selectdata(cfg,D1);

cfg=[];
cfg.remask_nan = true;
cfg.value = 0;
D_sel = bml_mask(cfg, D_sel);

% % % Applying high pass filter and line noise removal filter

cfg=[];
cfg.hpfilter='yes';
cfg.hpfreq=1;
cfg.hpfilttype='but';
cfg.hpfiltord=5;
cfg.hpfiltdir='twopass';
cfg.dftfilter='yes';
%%%% this interpolation option is causing an error with 3012, artifact criterion E
% cfg.dftreplace='neighbour';  %using spectrum interpolation method Mewett et al 2004
cfg.dftfreq           = [60 120 180 240 300 360 420 480];
cfg.dftbandwidth      = [ 1   1   1   1   1   1   1   1];
cfg.dftneighbourwidth = [ 2   2   2   2   2   2   2   2];
D_sel_filt = ft_preprocessing(cfg,D_sel);

% % % Redefining trials
% for dbs-seq/smsl, we will use experimenter keypress for trial start/end times
%%%%% this means no trial overlap, but generally a large time buffer before cue onset and after speech offset
cfg = [];
cfg.epoch = epoch;
D_sel_filt_trial = bml_redefinetrial(cfg,D_sel_filt);


% % % Masking artifacts with NaNs for re-referencing

%masking artifacts and empty_electrodes with NaNs
cfg=[];
cfg.annot=artifact;
cfg.label_colname = 'label';
cfg.complete_trial = true; %masks entire trials
cfg.value=NaN;
D_sel_filt_trial_mask = bml_mask(cfg,D_sel_filt_trial);

% % % Common trimmed average reference per connector groups

el_ecog = electrodes(electrodes.type=="ECOG",:);

cfg=[];
cfg.label = el_ecog.name;
cfg.group = el_ecog.connector;
cfg.method = 'CTAR'; %using trimmed average referencing
cfg.percent = 50; %percentage of 'extreme' channels in group to trim 
D_sel_filt_trial_mask_ref = bml_rereference(cfg,D_sel_filt_trial_mask);


% % % Adding unfiltered channels

%% Adding unfiltered channels
cfg =[];
cfg.channel = setdiff(D.label, D_sel_filt_trial_mask_ref.label);
D_unfilt = ft_selectdata(cfg,D);

cfg = [];
cfg.epoch = epoch;
D_unfilt_trial = bml_redefinetrial(cfg,D_unfilt);

%%% for Triplet task, AM got rid of combining unfilt and filt_trial_mask_ref because the time fields do not match
% % % % % % % % % % cfg=[];
% % % % % % % % % % cfg.appenddim = 'chan';
% % % % % % % % % % D_trial_ref = ft_appenddata(cfg,D_sel_filt_trial_mask_ref, D_unfilt_trial);
D_trial_ref = D_sel_filt_trial_mask_ref; 

% % % Saving referenced data

bml_annot_write(epoch,['annot/' SUBJECT '_trial_epoch.txt']);
save([PATH_FIELDTRIP filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_ft-raw-filt-trial-ar-ref.mat'],'D_trial_ref','-v7.3');

% % % Quality check - visually inspect the data

cfg=[];
cfg.viewmode = 'vertical';
cfg.blocksize = 8;
cfg.ylim = 'maxmin';
cfg.continuous = 'no';
ft_databrowser(cfg,D_trial_ref);

% % % Quality check - create crosscorrelation matrix
% % % remask with zeros to calculate crosscorrelation

cfg=[];
cfg.remask_nan = true;
cfg.value = 0;
% % % % D_trial_ref_mask0 = bml_mask(cfg,D_trial_ref);
D_trial_ref_mask0 = bml_mask(cfg,D_sel_filt_trial_mask_ref);


% % % do timelock analysis for the raw, high pass filtered (hpf) and rereferenced (ref) versions of the data


cfg=[];
cfg.covariance = 'yes';
cfg.vartrllength = 2;
cfg.trials = 1; %selecting only first trial to assess crosscorrelation
TL_sel=ft_timelockanalysis(cfg,D_sel);

cfg=[];
cfg.covariance = 'yes';
cfg.vartrllength = 2;
cfg.trials = 1; %selecting only first trial to assess crosscorrelation
TL_sel_filt=ft_timelockanalysis(cfg,D_sel_filt);

cfg=[];
cfg.covariance = 'yes';
cfg.vartrllength = 2;
cfg.trials = 1; %selecting only first trial to assess crosscorrelation
TL_ref_mask0=ft_timelockanalysis(cfg,D_trial_ref_mask0);


% % % Plot crosscorrelation matrix for raw, hpf and car objects

f=figure('Position',[0 0 1500 300]);
subplot(1,3,1)
image(corrcov(TL_sel.cov),'CDataMapping','scaled')
caxis([-1 1])
title('raw')
colorbar()

subplot(1,3,2)
image(corrcov(TL_sel_filt.cov),'CDataMapping','scaled')
caxis([-1 1])
title('hpf')
colorbar()

subplot(1,3,3)
image(corrcov(TL_ref_mask0.cov),'CDataMapping','scaled')
caxis([-1 1])
title('ref')
colorbar()

saveas(f,[PATH_FIGURES filesep 'sub-' SUBJECT '_P09_raw_filt_ref_xcorr_T1.png'])
