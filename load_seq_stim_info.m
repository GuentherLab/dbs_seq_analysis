% load info about all stim used in the study, including a breakdown of phonemes

function stimtable = load_seq_stim_info(stim_info_file)

if ~exist("stim_info_file",'file')
    setpaths_dbs_seq();
    stim_info_file = PATH_STIM_INFO_TABLE;
end

stimtable = readtable(stim_info_file); 
phonemes = cellfun(@(x)split(x,',')',(stimtable.phonemes),'UniformOutput',false);
phonemes = vertcat(phonemes{:}); 
stimtable.consonant = phonemes(:,[1,2,4]); %% CCVC
stimtable.vowel = phonemes(:,3); %% CCVC
stimtable.phonemes = [];