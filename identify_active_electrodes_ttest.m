% Loading packages
ft_defaults
bml_defaults
format long

%% Defining paths, loading parameters
SUBJECT='DM1005';
SESSION = 'intraop';
TASK = 'smsl'; 

%%% choose an artifact criterion version
ARTIFACT_CRIT = 'E'; %identifier for the criteria implemented in this script
% ARTIFACT_CRIT = 'F'; %identifier for the criteria implemented in this script


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

PATH_ART_PROTOCOL = ['Y:\DBS\groupanalyses\task-smsl\A09_artifact_criteria_' ARTIFACT_CRIT];
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

%%
% Load HG fieldtrip (normalized HG power)
% load([PATH_FIELDTRIP filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_ft-raw-filt-trial-ar-ref-', ARTIFACT_CRIT, '.mat']);
load([PATH_FIELDTRIP filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_ft-raw-filt-trial-ar-ref', '.mat']);
% load([PATH_FIELDTRIP filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_ft-hg-trial-criteria-' ARTIFACT_CRIT '.mat']);

% separate trial data
% trial_data = D_hg.trial;
trial_data = D_trial_ref.trial;

% identify ecog labels
% elec_labels = D_hg.label;
elec_labels = D_trial_ref.label;
ecog_labels = elec_labels(contains(elec_labels, 'ecog', 'IgnoreCase', true));

% separate ecog and dbs electrode trial data
ecog_trial_data = cellfun(@(x) x(contains(elec_labels, 'ecog', 'IgnoreCase', true),:), trial_data, 'UniformOutput', false);
dbs_trial_data = cellfun(@(x) x(contains(elec_labels, 'dbs', 'IgnoreCase', true),:), trial_data, 'UniformOutput', false);

% separate stop trials
is_stoptrial = epoch.is_stoptrial;

%% Identify active electrodes
num_trials = numel(ecog_trial_data);
num_elecs = size(ecog_trial_data{1},1);
max_values = zeros(num_elecs, num_trials);
average_values = zeros(num_elecs, num_trials);
baseline_values = zeros(num_elecs, num_trials);


for i_trial = 1:num_trials
    % Prep trial
    % REMOVE LATER
    % Remove 3ms on each side of a trial
    % Then, exclude trials with values greater than 15 (should be removed by
    % mask in future)
    processed_trial = ecog_trial_data{i_trial}(:,3:end-3);
    
    % Find maximum values along m dimension
    [~, max_index] = max(processed_trial, [], 2, 'omitnan');
    baseline_values(:,i_trial) = mean(processed_trial(:,1:1000),2,'omitnan');
%     max_values(:,i_trial) = max_index;
    
    % Compute averages in a window around the maximum values
   for i_elec = 1:num_elecs
        start_index = max_index(i_elec) - 50;
        end_index = max_index(i_elec) + 49;
        
        if start_index < 1
            start_index = 1;
        end
        
        if end_index > size(processed_trial,2)
            end_index = size(processed_trial,2);
        end
        
        average_values(i_elec, i_trial) = mean(processed_trial(i_elec, start_index:end_index), 'omitnan');
   end
end
   
% t-test to determine if max period is different from baseline
[~, p_values] = ttest(baseline_values, average_values, 'Dim', 2, 'Alpha', 0.05);%, 'Vartype', 'unequal');
    

% figure; histogram(mean(all_elec_sig_timepoint_count,2,'omitnan'), 30)
% figure; hold on;
% histogram(mean(all_elec_sig_timepoint_count(:,find(~is_stoptrial)),2,'omitnan'), 30)
% histogram(mean(all_elec_sig_timepoint_count(:,find(is_stoptrial)),2,'omitnan'), 30)
% legend('Go Trials', 'Stop Trials')
% figure; hold on;
% bar(mean(all_elec_sig_timepoint_count(:,find(~is_stoptrial)),2,'omitnan'))
% bar(-mean(all_elec_sig_timepoint_count(:,find(is_stoptrial)),2,'omitnan'))


% for i_trial = 1:10%numel(go_trials)
%     elec_avg_trial = mean(go_trials{i_trial}, 1, 'omitnan');
%     elec_std_trial = std(go_trials{i_trial},0,1,'omitnan');
% 
%     figure;
%     subplot(1,2,1)
%     hold on;
%     plot(elec_avg_trial)
%     plot(elec_avg_trial + elec_std_trial, '--k')
%     plot(elec_avg_trial - elec_std_trial, '--k')
% 
%     subplot(1,2,2)
%     %plot(sum(isoutlier(go_trials{i_trial},'movmedian',50),1))
%     %plot(sum(isoutlier(go_trials{i_trial}, "median",2),1))
% 
% end
