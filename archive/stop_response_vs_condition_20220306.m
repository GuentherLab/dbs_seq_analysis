%%%% compile stop trial data for comparing stop response to condition

clear
close all

save_results = 1; 

SUBJECTS = {'DM1005', 'DM1007', 'DM1008'};
SESSION = 'intraop';
TASK = 'smsl'; 
PATH_DATASET = 'Y:\DBS';
PATH_DER = [PATH_DATASET filesep 'derivatives'];
savename = 'Y:\DBS\groupanalyses\task-smsl\20220306-stop-response-vs-condition\stop_response_vs_condition_table'; 

nsubs = length(SUBJECTS);
trials = table;
for isub = 1:nsubs
    substr = SUBJECTS{isub};
    subnum = str2double(regexp(substr,'\d*','Match'));
    PATH_DER_SUB = [PATH_DER filesep 'sub-' substr];  
    PATH_PREPROC = [PATH_DER_SUB filesep 'preproc'];
    PATH_ANNOT = [PATH_DER_SUB filesep 'annot'];
    PATH_AEC = [PATH_DER_SUB filesep 'aec']; 
    PATH_SCORING = [PATH_DER_SUB filesep 'analysis' filesep 'task-', TASK, '_scoring'];
    PATH_ANALYSIS = [PATH_DER_SUB filesep 'analysis'];
    PATH_TRIAL_AUDIO = [PATH_ANALYSIS filesep 'task-', TASK, '_trial-audio'];
    thissubtrials = load([PATH_TRIAL_AUDIO, filesep, 'sub-', substr, '_ses-', SESSION,...
        '_stop-trial-durations.mat'], 'trials');            thissubtrials = thissubtrials.trials;
    thissubtrials = [table(repmat(subnum,height(thissubtrials),1),'VariableNames',{'sub'}), thissubtrials];
    trials = [trials; thissubtrials];
end

trials = movevars(trials,{'trial_id','stim_condition','word','stop_response','ontime_post_beep_onset',...
    'ut_duration'},'After','id');

if save_results
   save(savename, 'trials') 
end