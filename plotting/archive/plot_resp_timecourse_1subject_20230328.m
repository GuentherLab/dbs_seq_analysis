 %%%% plot the timecourse and SD of an electrode's response
 % load preprocessed trialwise data and run resp_types.m first
 %
 % align all trialwise responses to speech onset of syllable #1
 %
 
%% params

srt_row = 9;
channame = resp.chan{srt_row};
thissub = resp.sub(srt_row,:);
% % % % % % % % % % % % load(['Z:\DBS\Analysis\triplet_analysis_am\',thissub,'_responses']);

% % % % % % % % % % erow = strcmp(resp.chan,channame);

 erow = 9; 
 
% set(0,'DefaultFigureWindowStyle','docked')
set(0,'DefaultFigureWindowStyle','normal')

plot_mean_timecourse = 1; 
plot_raster = 0; 

xline_color_stim_syl_on = [0.3 0.3 0.8];
xline_color_stim_syl_off = [0.8 0.3 0.3];
xline_color_prod_syl_on = [0.7 0.7 0.7];
xline_color_prod_syl_off = [0.3 0.3 0.3];
xline_style = '--';
xline_width = 0.25; 

%%%%% method for finding time landmarks from trial times
xline_fn = @mean; 
% xline_fn = @median;

yline_zero_width = 0.25; 
yline_zero_color = [0.8 0.8 0.8]; 
yline_zero_style = '-';

%%%% how to find the time length that trials will be cut/padded to be
trial_time_adj_method = 'median_plus_sd'; % median plus stdev
% trial_time_adj_method = 'median';
% trial_time_adj_method = 'max';



%% align responses
% load(
ntrials = height(trials);
 % align resp_allonses to first syl onset
 nans_tr = nan(ntrials,1); 
 trials_tmp = trials; % temporary copy of trials table
 trials_tmp = [trials_tmp, table(nans_tr,              nans_tr,...
     'VariableNames',     {'tpoints_pre_onset', 'tpoints_post_onset'})];
 
 samp_period = 1e-5 * round(1e5 * diff(trials.times{1}(1:2))); % sampling interval
 
 %%% find trial lengths pre- and post-onset
    %%%% trials.times{itrial} use global time coordinates
    %%%% ....... start at a fixed baseline window before stim onset
    %%%% ....... end at a fixed time buffer after speech offset
for itrial = 1:ntrials
    % n timepoints before or at voice onset [time from beginning of pre-stim baseline to voice onset]
    trials_tmp.tpoints_pre_onset(itrial) = nnz(trials_tmp.times{itrial} <= trials_tmp.t_prod_on(itrial,1)); 
    % n timepoints after voice onset [time from voice onset to end of post-voice time buffer]
    trials_tmp.tpoints_post_onset(itrial) = nnz(trials_tmp.times{itrial} > trials_tmp.t_prod_on(itrial,1)); 
end
 
% pad or cut each trial to fit a specific size, so that we can align and average trials
switch trial_time_adj_method
    case 'median_plus_sd'
        n_tpoints_pre_fixed = round(median(trials_tmp.tpoints_pre_onset) + std(trials_tmp.tpoints_pre_onset)); 
        n_tpoints_post_fixed = round(median(trials_tmp.tpoints_post_onset) + std(trials_tmp.tpoints_post_onset)); 
    case 'median'
        n_tpoints_pre_fixed = median(trials_tmp.tpoints_pre_onset); 
        n_tpoints_post_fixed = median(trials_tmp.tpoints_post_onset); 
    case 'max'
        n_tpoints_pre_fixed = max(trials_tmp.tpoints_pre_onset); 
        n_tpoints_post_fixed = max(trials_tmp.tpoints_post_onset); 
end
tpoints_tot = n_tpoints_pre_fixed + n_tpoints_post_fixed; 

% nan-pad or cut trial windows so that they are all the same duration
%%% pad and cut values must be non-negative
resp_align = struct; 
resp_align.resp = NaN(ntrials, tpoints_tot); % aligned responses for this electrode; rows = trials, columns = timepoints
for itrial = 1:ntrials
   pre_pad = max([0, n_tpoints_pre_fixed - trials_tmp.tpoints_pre_onset(itrial)]); 
   pre_cut = max([0, -n_tpoints_pre_fixed + trials_tmp.tpoints_pre_onset(itrial)]); 
   % inds from resp.timecourse... if pre_cut > 0, some timepoints from this trial will not be used
   pre_inds = 1+pre_cut:trials_tmp.tpoints_pre_onset(itrial); 
   % fill in pre-onset data... fill in electrode responses starting after the padding epoch
   resp_align.resp(itrial, pre_pad+1 : n_tpoints_pre_fixed) = resp.timecourse{erow}{itrial}(pre_inds); 

   post_pad = max([0, n_tpoints_post_fixed - trials_tmp.tpoints_post_onset(itrial)]);
   post_cut = max([0, -n_tpoints_post_fixed + trials_tmp.tpoints_post_onset(itrial)]); 
   post_inds = trials_tmp.tpoints_pre_onset(itrial) +  [1 : trials_tmp.tpoints_post_onset(itrial)-post_cut]; % inds from resp.timecourse
   resp_align.resp(itrial, n_tpoints_pre_fixed+1:end-post_pad) = resp.timecourse{erow}{itrial}(post_inds); % fill in post-onset data
   
   trials_tmp.trial_onset_adjust(itrial) = samp_period * [pre_pad - pre_cut]; % number of timepoints to add to time landmarks
end
resp_align.mean = mean(resp_align.resp,'omitnan'); % mean response timecourse
resp_align.std = std(resp_align.resp, 'omitnan'); % stdev of response timecourses
resp_align.std_lims = [resp_align.mean + resp_align.std; resp_align.mean - resp_align.std]; 
resp_align.n_nonnan_tpoints = sum(~isnan(resp_align.resp));
resp_align.sem = resp_align.std ./ sqrt(resp_align.n_nonnan_tpoints);
resp_align.sem_lims = [resp_align.mean + resp_align.sem; resp_align.mean - resp_align.sem]; 

% times relative to produced syllable #1 onset
trials_tmp.stim_syl_on_adj = trials_tmp.t_stim_syl_on - trials_tmp.t_prod_on ; 
trials_tmp.stim_syl_off_adj = trials_tmp.t_stim_syl_off - trials_tmp.t_prod_on ; 
trials_tmp.prod_syl_on_adj = trials_tmp.prod_syl_on - trials_tmp.prod_syl_on(:,1) ; 
trials_tmp.prod_syl_off_adj = trials_tmp.prod_syl_off - trials_tmp.prod_syl_on(:,1) ; 


%% plotting
xtime = 0.5 + [linspace(-n_tpoints_pre_fixed, -1, n_tpoints_pre_fixed), linspace(0, n_tpoints_post_fixed-1, n_tpoints_post_fixed)];
xtime = samp_period * xtime; 


if plot_mean_timecourse 
% close all

    %     fig = figure; 
    
    hold off
    hfill = fill([xtime, fliplr(xtime)], [resp_align.sem_lims(1,:), fliplr(resp_align.sem_lims(2,:))], [0.8 0.8 0.8]); % standard error
        hfill.LineStyle = 'none'; % no border
    hold on 
    hplot = plot(xtime, nanmean(resp_align.resp));
        hplot.LineWidth = 1;
    
    htitle = title([thissub, '___', resp.chan{erow}], 'Interpreter','none');
    
% % % % % % % % % % % % % % % % % %     % stim syllable onsets
% % % % % % % % % % % % % % % % % %     hstim_syl_on(1) = xline(xline_fn(trials_tmp.stim_syl_on_adj(:,1),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     hstim_syl_on(2) = xline(xline_fn(trials_tmp.stim_syl_on_adj(:,2),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     hstim_syl_on(3) = xline(xline_fn(trials_tmp.stim_syl_on_adj(:,3),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     
% % % % % % % % % % % % % % % % % %     % stim offset
% % % % % % % % % % % % % % % % % %     hstim_syl_off(3) = xline(mean(trials_tmp.stim_syl_off_adj(:,3),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_off, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     
% % % % % % % % % % % % % % % % % %     % produced syllable onsets
% % % % % % % % % % % % % % % % % %     hprod_syl_on(1) = xline(0, 'LineWidth',xline_width, 'Color',xline_color_prod_syl_on, 'LineStyle',xline_style); 
% % % % % % % % % % % % % % % % % %     hprod_syl_on(2) = xline(xline_fn(trials_tmp.prod_syl_on_adj(:,2),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_on, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     hprod_syl_on(3) = xline(xline_fn(trials_tmp.prod_syl_on_adj(:,3),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_on, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     
% % % % % % % % % % % % % % % % % %     % produced syllable offsets
% % % % % % % % % % % % % % % % % %     hprod_syl_off(2) = xline(xline_fn(trials_tmp.prod_syl_off_adj(:,1),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_off, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     hprod_syl_off(2) = xline(xline_fn(trials_tmp.prod_syl_off_adj(:,2),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_off, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     hprod_syl_off(3) = xline(xline_fn(trials_tmp.prod_syl_off_adj(:,3),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_off, 'LineStyle',xline_style);
% % % % % % % % % % % % % % % % % %     
% % % % % % % % % % % % % % % % % %     hyline = yline(0, 'LineWidth',yline_zero_width, 'Color',yline_zero_color, 'LineStyle',yline_zero_style);
    
    xlabel('Time (sec)')
    ylabel('HG power (normed)')
end

if plot_raster
    imagesc(resp_align.resp)
%     xlabel('Time (sec)')
    ylabel('Trial')

% % % % % % % % %     hold on
% % % % % % % % %         % stim syllable onsets
% % % % % % % % %     hstim_syl(1) = xline(xline_fn(trials_tmp.stim_syl_on_adj(:,1),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style);
% % % % % % % % %     hstim_syl(2) = xline(xline_fn(trials_tmp.stim_syl_on_adj(:,2),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style);
% % % % % % % % %     hstim_syl(3) = xline(xline_fn(trials_tmp.stim_syl_on_adj(:,3),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style);
% % % % % % % % %     
% % % % % % % % %     % stim offset
% % % % % % % % %     hstim_syl(3) = xline(mean(trials_tmp.stim_syl_off_adj(:,3),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_off, 'LineStyle',xline_style);
% % % % % % % % %     
% % % % % % % % %     % produced syllable onsets
% % % % % % % % %     hprod_syl(1) = xline(0, 'LineWidth',xline_width, 'Color',xline_color_prod_syl_on, 'LineStyle',xline_style); 
% % % % % % % % %     hprod_syl(2) = xline(xline_fn(trials_tmp.prod_syl_on_adj(:,2),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_on, 'LineStyle',xline_style);
% % % % % % % % %     hprod_syl(3) = xline(xline_fn(trials_tmp.prod_syl_on_adj(:,3),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_on, 'LineStyle',xline_style);
% % % % % % % % %     
% % % % % % % % %     % produced syllable offsets
% % % % % % % % %     hprod_syl(2) = xline(xline_fn(trials_tmp.prod_syl_off_adj(:,1),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_off, 'LineStyle',xline_style);
% % % % % % % % %     hprod_syl(2) = xline(xline_fn(trials_tmp.prod_syl_off_adj(:,2),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_off, 'LineStyle',xline_style);
% % % % % % % % %     hprod_syl(3) = xline(xline_fn(trials_tmp.prod_syl_off_adj(:,3),'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_syl_off, 'LineStyle',xline_style);

end