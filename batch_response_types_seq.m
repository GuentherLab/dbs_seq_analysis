% get response types from each dbs-seq subject then compile into a single table

clear
setpaths_dbs_seq()

% params
subject_list_filename = [PATH_DATA filesep 'participants.tsv'];

subnums = [1005, 1007, 1008, 1024, 1025, 1037];
%     sublist = [1037]; 

compiled_responses_filepath = [PATH_RESULTS, filesep, 'resp_all_subjects']; 

%% set up sub list
subnames = arrayfun(@(x)['DM',num2str(x)],subnums','UniformOutput',0);
subs = bml_annot_read_tsv(subject_list_filename);
subs = subs(cellfun(@(x)ismember(x,subnames),subs.subject_id), :); 
subs = renamevars(subs,'subject_id','subject');
nsubs = height(subs);

%% run response type analysis on each subject individually
for isub = 1:nsubs
    clearvars -except subs compiled_responses_filepath nsubs isub
    SUBJECT = subs.subject{isub}
    response_types_seq()
    save(savefile, 'trials', 'resp')
end
cd(PATH_RESULTS)

%% combine responses from all subjects into one table
setpaths_dbs_seq()
fprintf(['Compiling response tables in %s \n'], compiled_responses_filepath);
resp_temp = table; 
for isub = 1:nsubs
    SUBJECT = subs.subject{isub};
    load([PATH_RESULTS, filesep, SUBJECT, '_responses'],'resp')
    resp_temp = [resp_temp; resp];
    subs.trials{isub} = trials; 
end

resp = resp_temp; clear resp_temp
save(compiled_responses_filepath, 'resp','subs')
