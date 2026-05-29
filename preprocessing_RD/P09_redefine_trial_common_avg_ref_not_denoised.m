%%% do offline rereferencing of raw [HPF and line-noise filtered] signal after applying artifact masks
%%% ... the function P08A09_detect_artifact_not_denoised must have been run first
% protocol P09 for Pitt data; not yet assigned a protocol number for MGH data

function P09_redefine_trial_common_avg_ref_not_denoised(op)

% Loading packages
ft_defaults
bml_defaults
format long

%% Defining paths, loading artifact parameters
vardefault('op',struct); % initialize options if not present
field_default('op','sub','DM1005')
field_default('op','art_crit','E'); % 'E' = 70-250hz high gamma; 'F' = beta; 'G' = other Rohan criterion? 
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

% % % Identify initial outliers and exclude
diff_sig = D_sel.trial{:};
diff_sig = diff(diff_sig,1,2);
cs_diff_sig = cumsum(diff_sig, 2, 'omitmissing');
cs_diff_sig = [zeros(size(cs_diff_sig,1),1) cs_diff_sig];

m_sig = median(diff_sig,2,'omitnan');
% std_sig = std(diff_sig,1,2,'omitnan'); % use interquartile range
std_sig = iqr(diff_sig,2);
n_std = 3;

og_sig = D_sel.trial{:};
mask = abs(diff_sig - m_sig) > n_std*std_sig;
% mask = abs(diff_sig - cs_diff_sig) > n_std*std_sig;
mask = mask(:,[1:end, end]) | mask(:,[1, 1:end]) ;
mask_new = mask;

win_size = 500; win_step = 500; thresh = 0.3;
for i_win = 1:(size(mask,2) - win_size)/win_step
    i_win_range = (i_win-1)*win_step+1 : (i_win-1)*win_step+win_size;

    n_outlier = sum(mask(:,i_win_range),2);    
    mask_new(n_outlier/win_size>thresh,i_win_range) = 1;    
end

%%
% switch op.sub
%     case 'DM1005'
%         mask_new(2, 3.5*10^5:8*10^5) = 1;
%     case 'DM1007'
%         mask_new(10, 3.5*10^5:4.5*10^5) = 1;
%         mask_new(85, [1:0.25*10^5 4.25*10^5:6.25*10^5]) = 1;        
%     case 'DM1025'
%         mask_new(74, 1.8*10^5:2*10^5) = 1;
%     case 'DM1037'
%         mask_new(24, 7.6*10^5:7.62*10^5) = 1;
% end
%%
m_sig = median(og_sig,2,'omitnan');
og_sig = og_sig - m_sig;
og_sig(mask_new) = 0;
% og_sig = og_sig + m_sig;
og_sig = og_sig + cs_diff_sig + m_sig;

D_sel.trial{:} = og_sig;
clearvars diff_sig og_sig m_sig std_sig n_std


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
cfg.dftfreq           = [1 60 120 180 240 300 360 420 480];
cfg.dftbandwidth      = [1 1   1   1   1   1   1   1   1];
cfg.dftneighbourwidth = [2 2   2   2   2   2   2   2   2];

if 1
    F = cfg.dftfreq;
    N = D_annot.nSamples2;
    Fs = D_annot.Fs;
    BW = 2; % Bandwith of notch filter in Hz

    newF = F + reshape(find(abs(1/N*Fs*(0:N-1) - F(1))<BW/2)-1,[],1)/N*Fs - F(1);
    newF = reshape(newF,1,[]);
    % newF = [newF cfg.dftfreq(2:end)];
    cfg.dftfreq = newF;
elseif 0
    cfg.dftreplace='neighbour';
    cfg.dftbandwidth      = 0.05 * [ 1   1   1   1   1   1   1   1];
    cfg.dftneighbourwidth = 0.05 * [ 2   2   2   2   2   2   2   2];
end


if 1 % && ~exist(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'],"file")
    D_sel_filt = ft_preprocessing(cfg,D_sel);
    save(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'], 'D_sel_filt')
elseif exist(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_cont.mat'],"file")
    load(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'])
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
    D_sel_filt_trial_mask_ref = bml_rereference(cfg,D_sel_filt_trial_mask);
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
save(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch.mat'],  'D_sel_filt_trial')
save(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' op.sub '_ft_notch_mask.mat'],  'D_sel_filt_trial_mask')
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
