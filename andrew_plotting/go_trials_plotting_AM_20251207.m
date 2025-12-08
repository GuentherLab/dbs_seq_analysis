load('Y:\DBS\derivatives\sub-DM1037\fieldtrip\sub-DM1037_ses-intraop_task-smsl_ft-raw-filt-trial_ar-E_ref-none_not-denoised.mat')

% Ensure FieldTrip is in your path and ft_defaults has been run.
ft_defaults;

%% STEP 0: Define input data variable used in your workspace
% Based on your screenshot, your data structure is named 'D_trial_ref'
data_input = D_trial_ref;

%% STEP 1: Select specific channel data
% It is more efficient to select only the channel you need first.
cfg = [];
cfg.channel = 'dbs_L1'; % Specify the exact label name
data_dbs = ft_preprocessing(cfg, data_input);


%% STEP 2 (Optimized): Time-Frequency Analysis
% We need to define specific time points to speed up calculation.

% 1. Find start and end times of your data (assuming all trials cover roughly same periods)
startTime = data_dbs.time{1}(1);
endTime   = data_dbs.time{1}(end);

cfg = [];
cfg.method     = 'mtmconvol';
cfg.taper      = 'hanning';
cfg.output     = 'pow';
cfg.keeptrials = 'yes';

% Frequencies: 2Hz to 200Hz in steps of 2Hz
cfg.foi        = 2:2:200;     

% Time Window: 500ms window length
cfg.t_ftimwin  = ones(length(cfg.foi),1) .* 0.5; 

% --- THE FIX ---
% Time of Interest (toi): Instead of relying on defaults, we explicitly
% define a vector from start to end, stepping every 50ms (0.05s).
% This significantly reduces the number of calculations compared to doing it
% at every sample point (which would be stepping every 0.001s).
cfg.toi        = startTime : 0.05 : endTime;

fprintf('Calculating TFR for %d trials. This should now be much faster...\n', length(data_dbs.trial));
TFR_trials = ft_freqanalysis(cfg, data_dbs);
disp('Calculation finished.');

%% STEP 3: Average across trials
% Now we take the TFR structure containing all 144 trials and average them.
cfg = [];
cfg.trials     = 'all';
cfg.keeptrials = 'no'; % Collapse the trial dimension by averaging
TFR_avg = ft_freqdescriptives(cfg, TFR_trials);


%% STEP 4: Plotting
% Use FieldTrip's built-in plotter for time-frequency representations.
cfg = [];
cfg.parameter    = 'powspctrm'; % Plot the power spectrum field
cfg.ylim         = [0 200];     % Ensure Y-axis covers the requested range
cfg.colormap     = 'jet';       % (Optional) Set colormap, e.g., 'parula', 'hot'
cfg.enable_colorbar = 'yes';
cfg.interactive  = 'yes';       % Allows zooming in the plot

figure;
ft_singleplotTFR(cfg, TFR_avg);

% Add clear labels
title('Trial-Average Spectrogram: dbs_L1');
xlabel('Time (s)');
ylabel('Frequency (Hz)');