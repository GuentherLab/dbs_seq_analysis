% get response types from each dbs-seq subject then compile into a single table

clear
setpaths_dbs_seq()

% params
subject_list_filename = [PATH_DATA filesep 'participants.tsv'];

% op.art_crit = 'E'; op.resp_signal = 'hg';
op.art_crit = 'F'; op.resp_signal = 'beta';

op.denoised = 0; op.denoise_string = '_not-denoised'; % do not use vibration-denoised data

op.rereference_method = 'none';
% op.rereference_method = 'CTAR';

subnums = [1005, 1007, 1008, 1024, 1025, 1037];
%     subnums = [1007]; 

compiled_responses_filepath = [PATH_RESULTS, filesep, 'resp_all_subjects_', op.resp_signal, '_ref-',op.rereference_method '.mat']; 



% set up sub list
subnames = arrayfun(@(x)['DM',num2str(x)],subnums','UniformOutput',0);
subs = bml_annot_read_tsv(subject_list_filename);
subs = subs(cellfun(@(x)ismember(x,subnames),subs.subject_id), :); 
subs = renamevars(subs,'subject_id','subject');
nsubs = height(subs);

%% run response type analysis on each subject individually
analysis_spec_string = [op.resp_signal, '_ar-', op.art_crit, '_ref-',op.rereference_method, op.denoise_string]; 

for isub = 1:nsubs
    clearvars -except subs op compiled_responses_filepath nsubs isub analysis_spec_string

    op.sub = subs.subject{isub};
    fprintf(['.... Getting response types (', analysis_spec_string, ') for subject: ' op.sub, '\n'])

    response_types_seq()
    savefile = [PATH_RESULTS, filesep, op.sub '_responses_' resp_signal, '_ref-',rereference_method];
    save(savefile, 'trials','resp')
end
cd(PATH_RESULTS)

%% combine responses from all subjects into one table
setpaths_dbs_seq()
fprintf(['Compiling response tables in %s \n'], compiled_responses_filepath);
resp_temp = table; 
for isub = 1:nsubs
    op.sub = subs.subject{isub};
    load([PATH_RESULTS, filesep, op.sub, '_responses_', op.resp_signal, '_ref-',op.rereference_method],'resp','trials')
    resp_temp = [resp_temp; resp];
    subs.trials{isub} = trials; 
end

resp = resp_temp; clear resp_temp
save(compiled_responses_filepath, 'resp','subs','op')
