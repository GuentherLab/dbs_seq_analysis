 %%%% plot the timecourse and SD of an electrode's response
 % load preprocessed trialwise data and run resp_types.m first
 %
 % align all trialwise responses to speech onset
 %
 
%% params

vardefault('sort_by_trial_cond',0);
vardefault('sort_cond','learn_con');

% srt_row = 9;
channame = srt.chan{srt_row};
thissub = srt.sub{srt_row};

resprow = strcmp(resp.chan,channame) & strcmp(resp.sub,thissub);
 
% set(0,'DefaultFigureWindowStyle','docked')
set(0,'DefaultFigureWindowStyle','normal')

plot_mean_timecourse = 1; 
plot_raster = 0; 

xline_color_stim_syl_on = [0.6 0.4 0.1];
xline_color_stim_gobeep_on = [0.0 1 0.0];
xline_color_stim_gobeep_off = [0.0 1 0.0];
xline_color_prod_on = [0.5 0.5 0.5];
xline_color_prod_off = [0.5 0.5 0.5];
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
 % align responses to first syl onset

subind = string(subs.subject)==thissub; 

 trials_tmp = subs.trials{subind}; % temporary copy of trials table

if plot_go_trials_only % exclude stop trials
    go_trial_inds = ~trials_tmp.is_stoptrial;
    trials_tmp = trials_tmp(go_trial_inds,:);
    timecourses_unaligned = resp.timecourse{resprow}(go_trial_inds); 
elseif ~plot_go_trials_only % include both stop and go trials
    timecourses_unaligned = resp.timecourse{resprow};
end
trials_tmp = trials_tmp(~cellfun(@isempty, timecourses_unaligned),:);
timecourses_unaligned = timecourses_unaligned(~cellfun(@isempty, timecourses_unaligned));

ntrials = height(trials_tmp);
 nans_tr = nan(ntrials,1); 

 trials_tmp = [trials_tmp, table(nans_tr,              nans_tr,...
     'VariableNames',     {'tpoints_pre_onset', 'tpoints_post_onset'})];
 
 samp_period = 1e-5 * round(1e5 * diff(trials_tmp.times{1}(1:2))); % sampling interval
 
 %%% find trial lengths pre- and post-onset
    %%%% trials.times{itrial} use global time coordinates
    %%%% ....... start at a fixed baseline window before stim onset
    %%%% ....... end at a fixed time buffer after speech offset
for itrial = 1:ntrials
    % n timepoints before or at speech onset [time from beginning of pre-stim baseline to speech onset]
    trials_tmp.tpoints_pre_onset(itrial) = nnz(trials_tmp.times{itrial} <= trials_tmp.t_prod_on(itrial,1)); 
    % n timepoints after speech onset [time from voice onset to end of post-speech time buffer]
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
   pre_inds = 1+pre_cut:trials_tmp.tpoints_pre_onset(itrial); % inds from timecourses_unaligned... if pre_cut > 0, some timepoints from this trial will not be used
   resp_align.resp(itrial, pre_pad+1 : n_tpoints_pre_fixed) = timecourses_unaligned{itrial}(pre_inds); % fill in pre-onset data... fill in electrode responses starting after the padding epoch

   post_pad = max([0, n_tpoints_post_fixed - trials_tmp.tpoints_post_onset(itrial)]);
   post_cut = max([0, -n_tpoints_post_fixed + trials_tmp.tpoints_post_onset(itrial)]); 
   post_inds = trials_tmp.tpoints_pre_onset(itrial) +  [1 : trials_tmp.tpoints_post_onset(itrial)-post_cut]; % inds from timecourses_unaligned
   resp_align.resp(itrial, n_tpoints_pre_fixed+1:end-post_pad) = timecourses_unaligned{itrial}(post_inds); % fill in post-onset data
   
   trials_tmp.trial_onset_adjust(itrial) = samp_period * [pre_pad - pre_cut]; % number of timepoints to add to time landmarks
end
resp_align.mean = mean(resp_align.resp,'omitnan'); % mean response timecourse
resp_align.std = std(resp_align.resp, 'omitnan'); % stdev of response timecourses
resp_align.std_lims = [resp_align.mean + resp_align.std; resp_align.mean - resp_align.std]; 
resp_align.n_nonnan_trials = sum(~isnan(resp_align.resp)); % number of usable trials for this aligned timepoint
resp_align.sem = resp_align.std ./ sqrt(resp_align.n_nonnan_trials);
resp_align.sem_lims = [resp_align.mean + resp_align.sem; resp_align.mean - resp_align.sem]; 

% times relative to produced syllable 
trials_tmp.stim_syl_on_adj = trials_tmp.t_stim_syl_on - trials_tmp.t_prod_on ; 
trials_tmp.stim_syl_off_adj = trials_tmp.t_stim_syl_off - trials_tmp.t_prod_on ; 
trials_tmp.stim_gobeep_on_adj = trials_tmp.t_stim_gobeep_on - trials_tmp.t_prod_on ; 
trials_tmp.stim_gobeep_off_adj = trials_tmp.t_stim_gobeep_off - trials_tmp.t_prod_on ; 
trials_tmp.t_prod_on_adj = trials_tmp.t_prod_on - trials_tmp.t_prod_on(:,1) ; 
trials_tmp.t_prod_off_adj = trials_tmp.t_prod_off - trials_tmp.t_prod_on(:,1) ; 


%% plotting
xtime = 0.5 + [linspace(-n_tpoints_pre_fixed, -1, n_tpoints_pre_fixed), linspace(0, n_tpoints_post_fixed-1, n_tpoints_post_fixed)];
xtime = samp_period * xtime; 


if plot_mean_timecourse 
% close all
    %     fig = figure; 
   
trials_tmp.is_nat = cell(ntrials,1);
    trials_tmp.is_nat(strcmp(trials_tmp.learn_con,'nat')) = {'native'};
    trials_tmp.is_nat(~strcmp(trials_tmp.learn_con,'nat')) = {'nonnative'};

if sort_by_trial_cond
    unq_conds = unique(trials_tmp{:,sort_cond});
    if isnumeric(unq_conds)
        unq_conds = unq_conds(~isnan(unq_conds));
        unq_conds = cellstr(num2str(unq_conds));
        trialconds  = strtrim(cellstr(num2str(trials_tmp{:,sort_cond})));
    else
        trialconds = trials_tmp{:,sort_cond}; 
    end
    nconds = length(unq_conds);

    % plot error bars
    %%% plotting error bars separately from means makes it simpler to create legend
    for icond = 1:nconds
        thiscond = unq_conds{icond};
        resp_rows_match = strcmp(trialconds, thiscond);
        this_cond_resp = resp_align.resp(resp_rows_match,:); % aligned trial timecourses for trials that match this condition label
        this_cond_mean = nanmean(this_cond_resp);
         this_cond_std = std(this_cond_resp, 'omitnan'); % stdev of response timecourses
        this_cond_n_nonnan_trials = sum(~isnan(this_cond_resp)); % number of usable trials for this aligned timepoint
        this_cond_sem = this_cond_std ./ sqrt(this_cond_n_nonnan_trials);
        this_cond_sem_lims = [this_cond_mean - this_cond_sem; this_cond_mean + this_cond_sem]; 
        plotinds = this_cond_n_nonnan_trials > 0; % timepoints with computable error bars

        if nnz(plotinds) > 0
            hfill = fill([xtime(plotinds), fliplr(xtime(plotinds))], [this_cond_sem_lims(1,plotinds), fliplr(this_cond_sem_lims(2,plotinds))], [0.8 0.8 0.8]); % standard error
            hfill.LineStyle = 'none'; % no border
    
            hfill.EdgeColor = [0.8 0.8 0.8]; 
       end
       hold on
    end


    % plot means
    for icond = 1:nconds
        thiscond = unq_conds{icond};
        resp_rows_match = strcmp(trialconds, thiscond);
        this_cond_resp = resp_align.resp(resp_rows_match,:); % aligned trial timecourses for trials that match this condition label
        this_cond_mean = nanmean(this_cond_resp);
        hplot(icond) = plot(xtime, this_cond_mean);
    end

    legend_strs = [repmat({''},nconds,1); unq_conds]; % empty entries match error bars

else


    hold off
    hfill = fill([xtime, fliplr(xtime)], [resp_align.sem_lims(1,:), fliplr(resp_align.sem_lims(2,:))], [0.8 0.8 0.8]); % standard error
%         hfill.LineStyle = 'none'; % no border
        hfill.EdgeColor = [0.8 0.8 0.8]; 
    hold on 
    hplot = plot(xtime, nanmean(resp_align.resp));
        hplot.LineWidth = 1;

    legend_strs = {''}; 
end

    if string(resp.type{resprow})=="ECOG"
        htitle = title([thissub, '_', resp.chan{resprow}, '_area-', resp.HCPMMP1_label_1{resprow}], 'Interpreter','none');
    else
        htitle = title([thissub, '_', resp.chan{resprow}, '_area-', resp.DISTAL_label_1{resprow}], 'Interpreter','none');
    end

    % stim syllable onsets
    h_stim_syl_on = xline(xline_fn(trials_tmp.stim_syl_on_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_syl_on, 'LineStyle',xline_style);


%     stim offset
    h_stim_gobeep_off = xline(mean(trials_tmp.stim_gobeep_off_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_stim_gobeep_off, 'LineStyle',xline_style);

   
% % %     % produced syllable onset
    h_t_prod_on = xline(0, 'LineWidth',xline_width, 'Color',xline_color_prod_on, 'LineStyle',xline_style); 

   % % %     % produced syllable offset 
    h_stim_prod_off = xline(mean(trials_tmp.t_prod_off_adj,'omitnan'), 'LineWidth',xline_width, 'Color',xline_color_prod_off, 'LineStyle',xline_style);


 
%     hyline = yline(0, 'LineWidth',yline_zero_width, 'Color',yline_zero_color, 'LineStyle',yline_zero_style);
    
    xlabel('Time (sec)')
%     ylabel('HG power (normed)')
    ylabel('normed power')

    set(gcf,'Color',[1 1 1])

    hleg = legend(legend_strs{:},'Interpreter','none');
    hold off

end

box off

if plot_raster
    imagesc(resp_align.resp)
%     xlabel('Time (sec)')
    ylabel('Trial')


end