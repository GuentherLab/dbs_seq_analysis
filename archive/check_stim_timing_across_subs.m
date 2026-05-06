 %%%% compile a table of timepoints across subs to check whether key timepoints are missing
% for a list of events within a trial, get the number of trials where the timepoint is not nan
% first column for an even is number of missing trials, second number is proportion of missing trials
% for speech events, this is only computed for go trials

 addpath('C:\docs\code\dbs_seq_analysis')
setpaths_dbs_seq();
subs = bml_annot_read_tsv(PATH_SUB_MASTER_TABLE);
    subs = subs(logical(subs.analyze),:);

nsubs = height(subs);
op.ses = 'intraop';
op.task = 'smsl';

events_to_check_alltrials = {'keypress_time','visual_onset','audio_onset'}
events_to_check_gotrials = {'sp_on','sp_off'}; 

all_ev = [events_to_check_alltrials, events_to_check_gotrials]
nancol = nan(nsubs,1);
for iev = 1:length(all_ev)
    subs{:,[all_ev{iev},'_nan']} = nancol;
        subs = movevars(subs,[all_ev{iev},'_nan'],'After','sub');
    subs{:,[all_ev{iev},'_nanprop']} = nancol;
        subs = movevars(subs,[all_ev{iev},'_nanprop'],'After','sub');
end

for isub = 1:nsubs
    thissub = subs.sub{isub}; 
    sylprod_file = [PATH_DER, filesep, 'sub-',thissub, filesep, 'annot', filesep, 'sub-',thissub, '_ses-',op.ses, '_task-',op.task, '_annot-produced-syllables.tsv']; 
    trials = bml_annot_read_tsv(sylprod_file); trials = trials(~[trials.unusable_trial==1],:);
    trials_go = trials(~trials.is_stoptrial, :); 
    subs.ntrials(isub) = height(trials);
    subs.ntrials_go(isub) = nnz(~trials.is_stoptrial); 
    for iev = 1:length( events_to_check_alltrials) 
        thisev = events_to_check_alltrials{iev};
        subs{isub,[thisev, '_nan']} = nnz(isnan(trials{:,thisev}));
        subs{isub,[thisev, '_nanprop']} = nnz(isnan(trials{:,thisev})) / subs.ntrials(isub);
    end
    for iev = 1:length( events_to_check_gotrials) 
        thisev = events_to_check_gotrials{iev};
        subs{isub,[thisev, '_nan']} = nnz(isnan(trials_go{:,thisev}));
        subs{isub,[thisev, '_nanprop']} = nnz(isnan(trials_go{:,thisev})) / subs.ntrials_go(isub);
    end

end