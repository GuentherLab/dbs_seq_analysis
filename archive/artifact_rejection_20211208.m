 %% Defining artifact rejection parameters
 % adapted from script used in P08 - artifact rejection
 %%% https://docs.google.com/document/d/1r_PL1FTFOze0D0_zFDB0uZEUnCSjSx_nOulWEuj91EA/edit
CRITERIA = 'A';

HIGH_PASS_FILTER = 'yes'; %should a high pass filter be applied
HIGH_PASS_FILTER_FREQ = 1; %cutoff frequency of high pass filter

ECOG_ENVELOPE_BIN_SIZE_SECONDS = 1; %envelope bin size in seconds

ECOG_THRESHOLD_STD_FACTORS = [2, 3]; %factors to determine detection thresholds 
ECOG_CONSOLIDATION_TIME_TOLERANCE = 3; %min time allowed between adjacent artifacts
ELECTRODE_COVERAGE_THRESHOLD = 0.5; %max allowed fraction of time with artifacts
CONNECTOR_THRESHOLD = [4, 8]; %detection threshold for faulty electrodes in connector

%loading packages 
ft_defaults
bml_defaults
format long

%defining paths
SUBJECT='DM1005'; %used for development/debugging
SESSION = 'intraop'; 
TASK = 'smsl'; 
PATH_DATA = 'Y:\DBS';
PATH_DER = [PATH_DATA filesep 'derivatives'];
PATH_DER_SUBJECT = [PATH_DER filesep 'sub-' SUBJECT];
PATH_ANNOT = [PATH_DER_SUBJECT filesep 'annot'];
PATH_FIELDTRIP = [PATH_DER_SUBJECT filesep 'fieldtrip']; 
PATH_PROTOCOL = 'C:\Users\amsmeier\Documents\MATLAB';

session= bml_annot_read_tsv([PATH_ANNOT, filesep, 'sub-',SUBJECT, '_sessions.tsv']);
electrode = bml_annot_read_tsv([PATH_ANNOT, filesep, 'sub-',SUBJECT, '_electrodes.tsv']);
% if doing manual rejection 
% artifact_manual = bml_annot_read(['annot/' SUBJECT '_artifact_manual.txt']);


load([PATH_FIELDTRIP, filesep, 'sub-', SUBJECT, '_ses-', SESSION, '_task-', TASK, '_ft-raw.mat'])
nTrials = numel(D.trial);


%% 

%mask the NaN values you have with the value of 0 
cfg=[];
cfg.value = 0;
cfg.remask_nan = true;
D_mask = bml_mask(cfg,D);

%high pass filtering
cfg=[];
cfg.hpfilter=HIGH_PASS_FILTER;	 % setting a high pass filter
cfg.hpfreq=HIGH_PASS_FILTER_FREQ; % 1Hz cutoff frequency	
cfg.hpfilttype='but';    		 % using butterworth filter
cfg.hpfiltord=5;         		 % of order 5
cfg.hpfiltdir='twopass'; 		 % two passes not to introduce time shift
cfg.channel={'ecog_*','macro_*','micro_*','dbs_*'}; %include channels to filter
D_hpf = ft_preprocessing(cfg,D_mask);

%%
% Calculate absolute value envelope at 1Hz (1s bins)
cfg=[];
cfg.freq=ECOG_ENVELOPE_BIN_SIZE_SECONDS;
D_hpf_env = bml_envelope_binabs(cfg,D_hpf);

% Defining artifacts for ECoG channels. We will do one channel type at a time. 
% 
% Select the ECoG channels
% If different strips were used, consider doing this independently for each strip type.
% For instance the signal obtained from a 63 contact 'high density' strip is different than...
% ...the one obtained from a 4-contacts strip (which has bigger electrodes).
cfg=[];
cfg.channel = 'ecog_*';
D_hpf_ecog = ft_selectdata(cfg,D_hpf);

% % % If using manual artifact identification, mask these artifacts before proceeding
% cfg=[];
% cfg.annot = artifact_manual;
% cfg.value = nan;
% cfg.label_colname = 'label';
% D_hpf_ecog = bml_mask(cfg,D_hpf_ecog); % %masking manually identified artifacts

% Visually inspect the signal. 
% Don't close this figure as we will compare it with the result after artifact rejection. 
cfg=[];
cfg.viewmode = 'vertical';
cfg.blocksize = 30;
cfg.ylim = 'maxmin';
cfg.continuous = 'yes';
% ft_databrowser(cfg,D_hpf_ecog);

rereferencing() % do common average referencing

cfg=[];
cfg.channel = 'ecog_*';
D_hpf_ref_ecog = ft_selectdata(cfg,D_hpf_ref); % ecog only, high pass filtered and rereferenced channels

% Calculate absolute value envelope at 1Hz (1s bins)
cfg=[];
cfg.freq=1;
D_hpf_ecog_env = bml_envelope_binabs(cfg,D_hpf_ref_ecog);

% calculate the log10 transform (envelopes tend to have a log normal distributions)
D_hpf_ecog_env_log10 = bml_apply(@(x) log10(x),D_hpf_ecog_env);

% % calculate robust statistics of the distribution of absolute values statistics and... 
% % Define threshold based on the distributions. Check if these values are correct after plotting the histograms (next step). 
% % The THRESHOLD matrix contains upper and lower threshold values for each trial. The time segment during which the envelope is higher than the lower threshold will be defined as an artifact, if during that time window the signal goes higher than the upper threshold for at least one time point. 
THRESHOLD = nan(nTrials,2);
for i=1:nTrials
  v = reshape(D_hpf_ecog_env_log10.trial{i},1,[]);
  m = nanmedian(v);
  std = bml_robust_std(v);
  THRESHOLD(i,:) = m + ECOG_THRESHOLD_STD_FACTORS.*std;
end


% Plot histograms of absolute values for all channels and sessions. Create a figures/ directory within Sync/, and save the figure for future reference
%plotting histogram to asses threshold levels
f=figure();
for i=1:nTrials
  subplot(ceil(nTrials/2),2,i)
  hold on;
  h=histogram(D_hpf_ecog_env_log10.trial{i},linspace(0,5,61),...
'FaceAlpha',0.1,'EdgeAlpha',1);
  maxBinCount = max(h.BinCounts);
  plot([THRESHOLD(i,1),THRESHOLD(i,1)],[0,maxBinCount .* 1.1]);
  plot([THRESHOLD(i,2),THRESHOLD(i,2)],[0,maxBinCount .* 1.1]);
  title(['session ' num2str(i)]);
  ylabel('n bins')
    xlabel('log10 amplitude')
end
% saveas(f,['figures/' SUBJECT '_P08_ar_' CRITERIA '_hpf_ecog_env_log10_hist.png'])

% % % Detect segments of time for each channel above the threshold, per session
artifact_ecog_1 = table();
for i=1:nTrials
  cfg=[];
  cfg.threshold = THRESHOLD(i,:);
  cfg.trials = i;
  artifact_ecog_1 = bml_annot_rowbind(artifact_ecog_1,...
 bml_annot_detect(cfg,D_hpf_ecog_env_log10));

end

% This step returns an annotation table with the time intervals during which artifacts were detected. 
% Consolidate the artifact annotation table. The signal between two nearby segments with detected artifacts is probably affected. Consolidating the artifacts if the time gap between them is less than 3 seconds. 

cfg=[];
cfg.criterion = @(x) (x.starts(end) - max(x.ends(1:(end-1))) < ECOG_CONSOLIDATION_TIME_TOLERANCE);
cfg.groupby = 'label';
artifact_ecog_2 = bml_annot_consolidate(cfg,artifact_ecog_1);


% Optional. Extend each artifact time interval by 1 second to the right. This is to minimize the effect of the slow return to baseline level. (Not really necessary for high-pass filtered data) 
%artifact_ecog_3 = bml_annot_extend(artifact_ecog_2,0,1);
artifact_ecog_3 = artifact_ecog_2; %renaming for consistency

% Make a raster plot of the artifacts annotations. Redefine thresholds if necessary.
% First we will transform the annotation table to a FieldTrip raw object, and then we'll make a raster plot of that object. 
cfg=[];
cfg.template = D_hpf_ecog_env_log10;  	% ft_raw object to use as template
cfg.label_colname='label';   		% what variable of the table to use as label 
artifact_ecog_3_raw = bml_annot2raw(cfg,artifact_ecog_3);

f=figure();
bml_plot_raster(artifact_ecog_3_raw)
ylabel('electrode')
xlabel('time bin')

% Visually inspect data after masking off artifact segments

cfg=[];
cfg.label_colname = 'label';	% column of annot with label specification
cfg.annot = artifact_ecog_3;  	% annotation table to use for mask
cfg.value = NaN;                 % value to use for mask
D_hpf_ecog_mask = bml_mask(cfg, D_hpf_ecog);

cfg=[];
cfg.viewmode = 'vertical';
cfg.blocksize = 30;
cfg.ylim = 'maxmin';
cfg.continuous = 'yes';
ft_databrowser(cfg,D_hpf_ecog_mask);
