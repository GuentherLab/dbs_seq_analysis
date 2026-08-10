% get response types from each dbs-seq subject then compile into a single table

clear
setpaths_dbs_seq()

% params
% subject_list_filename = [PATH_DATA filesep 'participants.tsv'];
subject_list_filename = [PATH_DBSSEQ_CODE, filesep, 'dbs_seq_subjects_master.tsv']; 


freq_bands_to_analyze = {'beta','hg'}; 
% freq_bands_to_analyze = {'beta'}; 
% freq_bands_to_analyze = {'hg'}; 

op.art_crit = 'G'; 
op.denoise_string = '_not_denoised'; %%% comment out??


op.baseline_method = 'subtract_then_divide'; % options: 'divide_then_subtract','subtract'


subnums = [...
    1005;...
    1007;...
    1008;...
    1024;...
    1025;...
    1037;...
    1044;...
    1045;... % problematic just for HG? 
    1046;...
    1047;...
    1048;...
    1049;... % problem during notch filter preproc 2026/7/5 - add back when fixed
% % % %     1050;... % poor behavior and ecog localization - don't use
    1051;... % 
    1052;... % 
    1054;... % 
     ];

% subnums = 1024;




%% set up sub list
subnames = arrayfun(@(x)['DM',num2str(x)],subnums','UniformOutput',0);
subs = bml_annot_read_tsv(subject_list_filename);
subs = subs(cellfun(@(x)ismember(x,subnames),subs.sub), :); 
nsubs = height(subs);

nbands = length(freq_bands_to_analyze);
for iband = 1:nbands % run full analysis, compile subjects, save results for all signals of interest
    op.resp_signal = freq_bands_to_analyze{iband};
    compiled_responses_filepath = [PATH_RESULTS, filesep, 'resp_all_subjects_', op.resp_signal, '_ref-',op.rereference_method]; 

    % run response type analysis on each subject individually
    for isub = 1:nsubs    
        op.sub = subs.sub{isub}
        set_project_specific_variables(); % subject-specific paths and variables
        [resp, trials, op] = response_types_seq(op);
        savefile = [PATH_RESULTS, filesep, op.sub '_responses_' op.resp_signal, '_ref-',op.rereference_method];
        save(savefile, 'trials','resp','op'); clear resp trials
    end

    
    % combine responses from all subjects into one table
    fprintf(['Compiling response tables in %s \n'], compiled_responses_filepath);
    resp_all = table; 
    for isub = 1:nsubs
        op.sub = subs.sub{isub};
        load([PATH_RESULTS, filesep, op.sub, '_responses_', op.resp_signal, '_ref-',op.rereference_method],'resp','trials','op')
        resp_all = [resp_all; resp];
        subs.trials{isub} = trials; 
    end

    resp = resp_all; clear resp_all; op = rmfield(op,'sub'); 
    save(compiled_responses_filepath, 'resp','subs','op')
    fprintf(['Saved all-subject response table in %s \n'], compiled_responses_filepath);

end

cd(PATH_RESULTS)


