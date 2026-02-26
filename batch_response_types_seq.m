% get response types from each dbs-seq subject then compile into a single table

clear
setpaths_dbs_seq()

% params
% subject_list_filename = [PATH_DATA filesep 'participants.tsv'];
subject_list_filename = [PATH_DBSSEQ_CODE, filesep, 'dbs_seq_subjects_master.tsv']; 

resp_signal = 'hg'; ARTIFACT_CRIT = 'E'; rereference_method = 'CMR';
% resp_signal = 'beta'; ARTIFACT_CRIT = 'F';  rereference_method = 'none';

% rereference_method = 'CTAR';


subnums = [...
    1005;...
    1007;...
    1008;...
    1024;...
    1025;...
    1037;...
    1044;...
% % % % %     1045;... % resolve switched-reference issue
    1046;...
    1047;...
    1048;...
    1049;... % 
% % % %     1050;... % finish b06
% % % %     1051;... % finish b06
% % % %     1052;... % finish b06    
% % % % %     1054;... % finish b06  
    ];


compiled_responses_filepath = [PATH_RESULTS, filesep, 'resp_all_subjects_', resp_signal, '_ref-',rereference_method]; 
% compiled_responses_filepath = [PATH_RESULTS, filesep, 'resp_all_44_48_', resp_signal, '_ref-',rereference_method]; 

%% set up sub list
subnames = arrayfun(@(x)['DM',num2str(x)],subnums','UniformOutput',0);
subs = bml_annot_read_tsv(subject_list_filename);
subs = subs(cellfun(@(x)ismember(x,subnames),subs.sub), :); 
nsubs = height(subs);

%% run response type analysis on each subject individually
for isub = 1:nsubs
    clearvars -except subs compiled_responses_filepath nsubs isub resp_signal rereference_method ARTIFACT_CRIT
    op.sub = subs.sub{isub}
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
    op.sub = subs.sub{isub};
    load([PATH_RESULTS, filesep, op.sub, '_responses_', resp_signal, '_ref-',rereference_method],'resp','trials')
    resp_temp = [resp_temp; resp];
    subs.trials{isub} = trials; 
end

resp = resp_temp; clear resp_temp
save(compiled_responses_filepath, 'resp','subs')
