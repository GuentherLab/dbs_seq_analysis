% get response types from each dbs-seq subject then compile into a single table

clear

sublist = [1005, 1007, 1008];

group_datadir = 'Y:\DBS\groupanalyses\task-smsl\gotrials'; 
resp_all_subs_filename = 'resp_all_subjects'; 

nsubs = length(sublist);

%% run response type analysis on each subject individually
for isub = 1:nsubs
    clearvars -except sublist group_datadir resp_all_subs_filename nsubs isub
    SUBJECT = ['DM', num2str(sublist(isub))];
    response_types_seq()
end
cd(group_datadir)

%% combine responses from all subjects into one table
resptemp = table; 
for isub = 1:nsubs
    SUBJECT = ['DM', num2str(sublist(isub))];
    load([group_datadir, filesep, SUBJECT, '_responses'],'resp')
    resptemp = [resptemp; resp];
end

resp = resptemp; clear resptemp
save([group_datadir, filesep, resp_all_subs_filename], 'resp')
