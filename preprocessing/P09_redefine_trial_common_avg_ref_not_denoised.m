%%% do offline rereferencing of raw [HPF and line-noise filtered] signal after applying artifact masks
%%% ... the function P08A09_detect_artifact_not_denoised must have been run first
% protocol P09 for Pitt data; not yet assigned a protocol number for MGH data
%
% Rohan D. 2026 version

function P09_redefine_trial_common_avg_ref_not_denoised(op)

% Loading packages
ft_defaults
bml_defaults
format long

%% Defining paths, loading artifact parameters
vardefault('op',struct); % initialize options if not present
field_default('op','sub','DM1005')
field_default('op','art_crit','G'); % 'E' = 70-250hz high gamma; 'F' = beta; 'G' = new Rohan method
field_default('op','do_high_pass_filter','yes'); % should a high pass filter be applied
    field_default('op','high_pass_filter_freq',1); %cutoff frequency of high pass filter, if one is to be used
field_default('op','rereference_method','CTAR'); 
field_default('op','out_freq',100); % downsample rate in hz for high gamma traces
field_default('op','time_buffer_before_epoch_trial_start',0); %%% add this much time to the beginning of each trial in epoch.starts

% use the following trial duration if one is not specified in the trials annot table
%%% ..... probably not specified due to a missing keypress at the end of a session
% if not the last trial, use default_iti for trial spacing
field_default('op','default_trialdur_max_if_empty',15);  % sec
field_default('op','default_iti_if_empty',0.5); % sec

set_project_specific_variables(); % set paths etc. based on data collection site, load timing and electrode data

% filenamename that we will save rereferenced data into
ft_savename = [FT_FILE_PREFIX 'raw-filt-trial_ar-', op.art_crit, '_ref-',op.rereference_method,'_not-denoised.mat']; 

% handle missing trial durations
for itrial = 1:height(epoch)
    if isnan(epoch.duration(itrial))
        if ~[itrial == height(epoch)]
            epoch.ends(itrial)= min([epoch.starts(itrial) + op.default_trialdur_max_if_empty, epoch.ends(itrial+1) - op.default_iti_if_empty]);
        elseif itrial == height(epoch) % last trial
            epoch.ends(itrial)= epoch.starts(itrial) + op.default_trialdur_max_if_empty;
        end
        epoch.duration(itrial) = epoch.ends(itrial) - epoch.starts(itrial); 
    end
end

% % % Load FieldTrip raw data
load(FT_RAW_FILENAME,'D','loaded_epoch');

% % % Adjusting length of sessions for notch filter to work
D_annot = bml_raw2annot(D);
Fl=[60 120 180 240 300 360 420 480];
D_annot.nSamples2 = round(floor(D_annot.nSamples .* Fl(1)./D_annot.Fs) .* D_annot.Fs./Fl(1));
D_annot.nSamples2 = round(floor(D_annot.nSamples2 .* Fl(1)./D_annot.Fs) .* D_annot.Fs./Fl(1));
D_annot.nSamples2 = D_annot.nSamples2(:,1);
% D_annot.nSamples2 = 938640; % hardcoded edit for DM1037
D_annot.ends = D_annot.starts + D_annot.nSamples2 ./ D_annot.Fs;

cfg=[];
cfg.epoch=D_annot;
D1= bml_redefinetrial(cfg,D);


% % % Selecting electrodes and remasking with zeros instead of NaNs

% % % Some of FieldTrip's functions don't work with NaNs, so we are going to temporarily replace NaNs with zeros to avoid issues. 

cfg=[];
cfg.channel={'ecog_*','macro_*','micro_*','dbs_*'};
% % %         cfg.trials = logical([1 1 1 1 0]);
D_sel = ft_selectdata(cfg,D1);

cfg=[];
cfg.remask_nan = true;
cfg.value = 0;
D_sel = bml_mask(cfg, D_sel);

% ORIGINAL SIGNAL
spike_dur = 0.1; %100ms
og_sig = cat(2,D_sel.trial{:});                             % og_sig contains an electrodes*timepoints matrix of "original values"

% IDENTIFY POTENTIAL OUTLIERS (as samples where diff_sig > Q3 + n_thr * IQR, or diff_sig < Q1 - n_thr * IQR)
diff_sig = diff(og_sig,1,2);                                % diff_sig contains an electrodes*(timepoints-1) matrix of differences (temporal derivative)
m = 2*round(spike_dur*D_annot.Fs/2) + 1; % force m to be odd
diff_sig_smoothed = convn(diff_sig(:,max(1,min(size(diff_sig,2),1-(m-1)/2:size(diff_sig,2)+(m-1)/2))), hanning(m)', 'valid');

% [iqr_diff,qart_diff] = iqr(diff_sig_smoothed,2);   % iqr_diff: interquartile range of differences (IQR); qart_diff: first and third quartiles (Q1 & Q3) (REQUIRES >=R2024a)
iqr_diff = iqr(diff_sig_smoothed,2);
qart_diff = prctile(diff_sig_smoothed, [25; 75], 2);
iqr_thr = 3;                                                  % threshold to identify outliers


% RECONSTRUCTED SIGNAL
% Apply diff_sig_mask
% diff_sig = max(min(diff_sig, qart_diff(:,2)+n_thr*iqr_diff),qart_diff(:,1)-n_thr*iqr_diff); % crops derivatives beyond minimum/maximum values
diff_sig_mask = diff_sig_smoothed > qart_diff(:,2)+iqr_thr*iqr_diff | diff_sig_smoothed < qart_diff(:,1)-iqr_thr*iqr_diff;
diff_sig(diff_sig_mask) = 0;


% Apply Manual Artifact Mask
% load artifact mask
if exist('/Volumes/Nexus4/DBS/derivatives','dir') % if we're working in RD's local folder
    PATH_DER = '/Volumes/Nexus4/DBS/derivatives'; 
end
t = readtable([PATH_DER, filesep, 'sub-', op.sub, filesep 'annot',filesep, 'sub-',op.sub,'_ses-intraop_task-smsl_artifact-manual.tsv'], "FileType","text",'Delimiter', '\t');

% convert global time to samples
t.starts_idx = zeros(size(t.starts));
t.ends_idx = zeros(size(t.ends));
for i_t = 1:size(t,1)
    [~, t.starts_idx(i_t)] = min(abs(t.starts(i_t) - D_sel.time{1}));
    [~, t.ends_idx(i_t)] = min(abs(t.ends(i_t) - D_sel.time{1}));
end

% for each electrode, set value to zero from starts:end
for i_t = 1:size(t,1)
    diff_sig(strcmp(D_sel.label, t.label(i_t)), t.starts_idx(i_t):t.ends_idx(i_t)) = 0;
end

% apply
og_sig = cumsum([zeros(size(diff_sig,1),1), diff_sig],2);   % reconstructs original signal by cumulative sum (temporal integral)

% 
f_c = 2; % cutoff freq
k = 1/(1 + 2*pi*f_c/D_annot.Fs); % first order IIR
for n=2:size(og_sig,2)    
    og_sig(:,n) = k*og_sig(:,n-1) + k*diff_sig(:,n-1); % HPF
    % og_sig(:,n) = og_sig(:,n-1) + k*(diff_sig(:,n) - og_sig(:,n-1)); % LPF    
end
og_sig = og_sig(:,1:end-1); % AM edit 2026-6-26 - we need to remove a column to match original number of columns

D_sel.trial{:} = og_sig;
% clearvars diff_sig og_sig m_sig std_sig n_std
clearvars og_sig diff_sig diff_sig_mask diff_sig_smoothed iqr_diff qart_diff n_thr t


% % % Applying high pass filter and line noise removal filter
% AM note: this step uses dft filter instead of bandstop filter (like artifact rejection uses).... ask Alan why the difference
cfg=[];
cfg.hpfilter=op.do_high_pass_filter;
    cfg.hpfreq=op.high_pass_filter_freq;
    cfg.hpfreq = 5;
cfg.hpfilttype='but';
cfg.hpfiltord=5;
cfg.hpfiltdir='twopass';
cfg.dftfilter='yes';
%%%% this interpolation option is causing an error with 3012, artifact criterion E
% cfg.dftreplace='neighbour';  %using spectrum interpolation method Mewett et al 2004
cfg.dftfreq           = [60 120 180 240 300 360 420 480];
cfg.dftbandwidth      = [1   1   1   1   1   1   1   1];
cfg.dftneighbourwidth = [2   2   2   2   2   2   2   2];

if 0
    F = cfg.dftfreq;
    N = D_annot.nSamples2;
    Fs = D_annot.Fs;
    BW = 2; % Bandwith of notch filter in Hz

    newF = F + reshape(find(abs(1/N*Fs*(0:N-1) - F(1))<BW/2)-1,[],1)/N*Fs - F(1);
    newF = reshape(newF,1,[]);
    % newF = [newF cfg.dftfreq(2:end)];
    cfg.dftfreq = newF;
elseif 1
    cfg.dftreplace='neighbour';
    cfg.dftbandwidth      = 0.05 * [ 1   1   1   1   1   1   1   1];
    cfg.dftneighbourwidth = 0.05 * [ 2   2   2   2   2   2   2   2];
end


if 1 % && ~exist(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'],"file")
    D_sel_filt = ft_preprocessing(cfg,D_sel);
%     save(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'], 'D_sel_filt')
elseif exist(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_cont.mat'],"file")
%     load(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'])
end

% % % Redefining trials
% for dbs-seq/smsl, we will use experimenter keypress for trial start/end times
%%%%% this means no trial overlap, but generally a large time buffer before cue onset and after speech offset
cfg = [];
cfg.epoch = epoch; 
cfg.epoch.starts = cfg.epoch.starts - op.time_buffer_before_epoch_trial_start; % add time buffer at beginning of trial
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

el_ecog = electrodes(electrodes.type=="ECOG" | electrodes.type=="ecog",:);

if strcmp(op.rereference_method,'none') % no referencing
    D_sel_filt_trial_mask_ref = D_sel_filt_trial_mask;
elseif ~strcmp(op.rereference_method,'none')
    cfg=[];
    cfg.label = el_ecog.name;
    cfg.group = el_ecog.connector;
    % if contains(op.rereference_group,'strip','IgnoreCase',1)
    %     cfg.group = ceil(el_ecog.connector/(max(el_ecog.connector)/2));
    %     % cfg.group = ceil(el_ecog.connector/4);
    %     % cfg.group = ceil((1:length(el_ecog.connector))./63)';
    % end
    cfg.method = op.rereference_method; % 
    cfg.percent = 50; %percentage of 'extreme' channels in group to trim 
    D_sel_filt_trial_mask_ref = bml_rereference_RD(cfg,D_sel_filt_trial_mask);
end


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
% this section used to saved an annot table file called ['annot/' SUBJECT '_trial_epoch.txt'] from epoch variable... AM removed it 2024/02/05 because it appeared unnecessary and confusing
save(ft_savename,'D_trial_ref','-v7.3');

% % % Quality check - visually inspect the data

cfg=[];
cfg.viewmode = 'vertical';
cfg.blocksize = 8;
cfg.ylim = 'maxmin';
cfg.continuous = 'no';
% ft_databrowser(cfg,D_trial_ref);

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
% cfg.trials = 1; %selecting only first trial to assess crosscorrelation
cfg.trials = 'all';
TL_sel=ft_timelockanalysis(cfg,D_sel);

cfg=[];
cfg.covariance = 'yes';
cfg.vartrllength = 2;
% cfg.trials = 1; %selecting only first trial to assess crosscorrelation
cfg.trials = 'all';
TL_sel_filt=ft_timelockanalysis(cfg,D_sel_filt);

cfg=[];
cfg.covariance = 'yes';
cfg.vartrllength = 2;
cfg.trials = 1; %selecting only first trial to assess crosscorrelation
% cfg.trials = 'all';
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

sgtitle(op.sub)

saveas(f,[PATH_FIGURES filesep 'sub-' op.sub '_P09_raw_filt_ref_xcorr_T1_' op.rereference_method '_not_denoised.png'])


% %% Generate and save PSD plots of Pre- and Post- Notch, and Artifact Rejection
if exist('/Users/rohandeshpande/Documents/School/Research/Code/data/ft','dir') % if working in RD local machine
    save(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch.mat'],  'D_sel_filt_trial')
    save(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_mask.mat'],  'D_sel_filt_trial_mask')
else
    save([PATH_FIELDTRIP, filesep, 'sub-',op.sub, '_ses-',SESSION, '_task-',SESSION, '_ft-raw-art-manual-crit-G-filt'],'D_sel_filt_trial')
    save([PATH_FIELDTRIP, filesep, 'sub-',op.sub, '_ses-',SESSION, '_task-',SESSION, '_ft-raw-notch-mask'],'D_sel_filt_trial_mask')
end


% 
% sublist ={...
%      % 'DM1005';...
%      'DM1007';...
%      'DM1008';...
%      'DM1024';...
%      'DM1025';...
%      % 'DM1037';...
%      % 'DM1044';... commented out by rohan
% % % % %      'DM1045;... % need to decide how to handle mid-run refeernce switch
%        % 'DM1046';...
%        % 'DM1047';...
%      % 'DM1048';...
%      % 'DM1049';...
%      };
% 
% for i_sub = 1:numel(sublist)
%     sub = sublist{i_sub}
% 
%     fig = figure;
%     % Pre notch
%     load(['/Volumes/Nexus4/DBS/derivatives/sub-' sub '/fieldtrip/sub-' sub '_ses-intraop_task-smsl_ft-raw.mat'])
%     ecog_idx = contains(D.label,'ecog');
%     t = 0:1/D.fsample:(size(D.trial{1},2)-1)/D.fsample;
%     p_bad = 0;
%     ax1 = subplot(2,1,1); hold on;
%     for i_ecog = 1:size(D.trial{1},1)
%         if ecog_idx(i_ecog)
%             [p,f] = pspectrum(D.trial{1}(i_ecog,:),t);
%             p = pow2db(p);
%             plot(f, p)
%             if min(p) < -100
%                 p_bad = p_bad+1;
%                 % pause()
%             end
%         end
%     end
%     xticks(0:30:480)
%     title('Pre- Notch filter')
%     clearvars D
% 
%     % Post notch
%     load(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' sub '_ft_notch.mat']);
%     ecog_idx = contains(D_sel_filt_trial.label,'ecog');
%     t = 0:1/D_sel_filt_trial.fsample:(size(D_sel_filt_trial.trial{1},2)-1)/D_sel_filt_trial.fsample;
% 
%     ax2 = subplot(2,1,2); hold on;
%     for i_ecog = 1:size(D_sel_filt_trial.trial{1},1)
%         if ecog_idx(i_ecog)
%             pspectrum(D_sel_filt_trial.trial{1}(i_ecog,:),t);        
%         end
%     end
%     xticks(0:30:480)
%     title('Post- Notch filter')
%     clearvars D_sel_filt_trial
% 
%     % % Post artifact mask
%     % load(['/Volumes/Nexus4/DBS/derivatives/sub-' sub '/fieldtrip/sub-' sub '_ses-intraop_task-smsl_ft-hg-trial_ar-E_ref-none_not-denoised.mat']);    
%     % ecog_idx = contains(D_wavpow.label,'ecog');
%     % D = [D_wavpow.trial{:}];
%     % t = 0:1/D_wavpow.fsample:(size(D,2)-1)/D_wavpow.fsample;
%     % 
%     % ax3 = subplot(3,1,3); hold on;
%     % for i_ecog = 1:size(D,1)
%     %     if ecog_idx(i_ecog)
%     %         pspectrum(D(i_ecog,:),t);        
%     %     end
%     % end
%     % xticks(0:30:480)
%     % title('Post- Artifact Mask')
%     % clearvars D_wavpow
% 
%     % fix all axes to be same
%     y1 = ylim(ax1); y2 = ylim(ax2); % y3 = ylim(ax3);
%     ymin = min([y1(1), y2(1)]); % ymin = min([y1(1), y2(1), y3(1)]);
%     ymax = max([y1(2), y2(2)]); % ymax = max([y1(2), y2(2), y3(2)]);
%     ylim(ax1,[ymin ymax]); ylim(ax2,[ymin ymax]); % ylim(ax3,[ymin ymax]);
%     sgtitle(sub)
%     saveas(fig, ['/Users/rohandeshpande/Documents/School/Research/Code/figures' filesep 'sub-' sub '_PSD.png'])
% end
