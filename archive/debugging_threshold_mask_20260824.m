

%% control channel without large artifact from same subject
channame = 'ecog_L226'; 

%% chan with large artifact

channame = 'ecog_L232'; 


%%

load('Y:\DBS\derivatives\sub-DM1008\fieldtrip\sub-DM1008_ses-intraop_task-smsl_ft-beta_no-thresh-mask.mat')
load('Y:\DBS\derivatives\sub-DM1008\fieldtrip\sub-DM1008_ses-intraop_task-smsl_ft-beta.mat')


%% plotting

ichan = find(strcmp(D_wavpow_no_thresh_mask.label,channame))

% close all
figure
subplot(2,1,1)
plot(D_wavpow_no_thresh_mask.time{1},D_wavpow_no_thresh_mask.trial{1}(ichan,:)); title([channame, ' - no thresh mask']); xlabel('sec gtc'); ylabel('beta power')
subplot(2,1,2)
plot(D_wavpow.time{1},D_wavpow.trial{1}(ichan,:)); title([channame, ' - with thresh mask']); xlabel('sec gtc'); ylabel('beta power')