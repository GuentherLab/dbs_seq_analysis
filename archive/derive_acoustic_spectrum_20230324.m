% function derive_acoustic_spectrum(SUBJECT, timetol)


%
% This protocol calculates pitch, intensity, F1 and F2 for each Lombard run. 
% Output: save fieldtrip objects to \derivatives and vowel annotation
% tables to \annot\XXXX-produced-vowels-acousticspectrum

% adapted from Latane Bullock's script used in Lombard analysis, stored in......
% .........Y:\DBS\groupanalyses\task-lombard\20210922-beh-lombard-effect-PLB\derive_acousticspectrum.m



%% loading paths
ft_defaults
bml_defaults
addpath(genpath('Y:\Documents\Code\dbs_seq_analysis')) %%% contained mPraat toolbox
format long

clear

if ~exist('timetol','var')
  timetol = 0.001;
end

%% Defining paths
SUBJECT='DM1008';
SESSION = 'intraop';
TASK = 'smsl';
RUN = '01'; 
PATH_DRIVE = 'Y:';
PATH_DATASET = [PATH_DRIVE filesep 'DBS'];
praat_script_path = 'Y:/Documents/Code/dbs_seq_analysis/extractF0F1F2.praat'; % script for pitch/formant extraction

SUBJECT_META = table2struct(readtable("Y:\DBS\participants.tsv",'Delimiter','\t','FileType','Text'));
SUBJECT_META = SUBJECT_META(strcmpi({SUBJECT_META.subject_id}, SUBJECT));

% Praat configuration
PCfg = []; % Praat configuration strucct
PCfg.nFormants = 5;
PCfg.formantCeiling = 5500;
PCfg.pitchLower = 100; 
PCfg.pitchUpper = 500; 
if strcmpi(SUBJECT_META.sex, 'male')
    PCfg.formantCeiling = 5000;
    PCfg.pitchLower = 60; 
    PCfg.pitchUpper = 300; 
end


PATH_DER = [PATH_DATASET filesep 'derivatives'];
PATH_DER_SUB = [PATH_DER filesep 'sub-' SUBJECT];  
PATH_ANNOT = [PATH_DER_SUB filesep 'annot'];
PATH_ANALYSIS = [PATH_DATASET '\groupanalyses\task-smsl'];
cd(PATH_ANALYSIS);
addpath(genpath('util'));


PATH_DER = [PATH_DATASET filesep 'derivatives'];
PATH_DER_SUB = [PATH_DER filesep 'sub-' SUBJECT];  
PATH_PREPROC = [PATH_DER_SUB filesep 'preproc'];
PATH_ANNOT = [PATH_DER_SUB filesep 'annot'];
PATH_FIELDTRIP = [PATH_DER_SUB filesep 'fieldtrip'];
PATH_AUDIO_DER = [PATH_DER_SUB filesep 'aec']; %path to acoustic echo cancelling folder


syllables = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_annot-produced-syllables.tsv'],'VariableNamingRule','preserve');



%loading subject specific tables
fp1 = [PATH_ANNOT filesep 'sub-' SUBJECT '_ses-' SESSION '_sync.tsv'];
fp2 = [PATH_ANNOT filesep 'sub-' SUBJECT '_sync.tsv'];
if exist(fp2, 'file') 
    sync = bml_annot_read_tsv(fp2);
elseif exist(fp1, 'file') 
    sync = bml_annot_read_tsv(fp1);
else
     error('Cannot find appropriate sync file')   
end
sync.folder = strrep(sync.folder,'W:',PATH_DRIVE); % fix drive name


runs = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_runs.tsv']);
runs_smsl = runs(strcmp(runs.session,SESSION) & strcmp(runs.task,TASK),:);
runs_smsl = runs_smsl(~contains(runs_smsl.comment,'test'),:);
runs_smsl = runs_smsl(~strcmp(runs_smsl.audio,''),:);
trials = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_annot-trials.tsv']);
     
% % % % % % % % % % % % % % % load phonemes annotation
% % % % % % % % % % % % % % % phonemes = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_annot-produced-phonemes.tsv']);
% % % % % % % % % % % % % % for ip = 1:height(syllables)
% % % % % % % % % % % % % %     itrial = trials.trial_id==syllables.trial_id(ip) & trials.run_id==syllables.run_id(ip);
% % % % % % % % % % % % % %     syllables.noise_type(ip) = trials.noise_type(itrial);
% % % % % % % % % % % % % %     syllables.sentence_id(ip) = trials.sentence_id(itrial);
% % % % % % % % % % % % % % end

% % % % % % % % % % % % % % % % % % % % % % % % define the translations from one phoneme to another
% % % % % % % % % % % % % % % % % % % % % % % % PLB 2021 12 20: We must do this to account for the forced-aligner's
% % % % % % % % % % % % % % % % % % % % % % % % inconsistent transcription of the same word. Their are a few problematic
% % % % % % % % % % % % % % % % % % % % % % % % sentences: ids 2, 5, 7, 8. For these trials, we must normalize the
% % % % % % % % % % % % % % % % % % % % % % % % transcription. 
% % % % % % % % % % % % % % % % % % % % % % % tmp =       {2, 'R', 'ER', 'AA', 'M'}; 
% % % % % % % % % % % % % % % % % % % % % % % tmp = [tmp; {8, 'R', 'ER', 'AA', 'M'}];
% % % % % % % % % % % % % % % % % % % % % % % tmp = [tmp; {7, 'S', 'ER', 'AA', 'AH'}];
% % % % % % % % % % % % % % % % % % % % % % % tmp = [tmp; {2, 'HH',  'IH', 'IY', 'R' }];
% % % % % % % % % % % % % % % % % % % % % % % trans = struct;
% % % % % % % % % % % % % % % % % % % % % % % trans.sentence_id = tmp(1:end, 1); % which sentences to translate? 
% % % % % % % % % % % % % % % % % % % % % % % trans.prec = tmp(1:end, 2); % the proceeding phoneme
% % % % % % % % % % % % % % % % % % % % % % % trans.curr = tmp(1:end, 3); % phoneme to be replaced
% % % % % % % % % % % % % % % % % % % % % % % trans.replace_with = tmp(1:end, 4); % phoneme to replace it with
% % % % % % % % % % % % % % % % % % % % % % % trans.proc = tmp(1:end, 5); % the proceeding phoneme
% % % % % % % % % % % % % % % % % % % % % % % for ip = 1:height(syllables)
% % % % % % % % % % % % % % % % % % % % % % %     for itrans = 1:length(trans.sentence_id)
% % % % % % % % % % % % % % % % % % % % % % %         if syllables.sentence_id(ip)==trans.sentence_id{itrans} && ...
% % % % % % % % % % % % % % % % % % % % % % %            startsWith(syllables.phoneme{ip},   trans.curr{itrans}) && ...
% % % % % % % % % % % % % % % % % % % % % % %            startsWith(syllables.phoneme{ip-1}, {'sp', trans.prec{itrans}}) && ...
% % % % % % % % % % % % % % % % % % % % % % %            startsWith(syllables.phoneme{ip+1}, {'sp', trans.proc{itrans}})
% % % % % % % % % % % % % % % % % % % % % % %         
% % % % % % % % % % % % % % % % % % % % % % %            syllables.phoneme{ip} = trans.replace_with{itrans};
% % % % % % % % % % % % % % % % % % % % % % %         end
% % % % % % % % % % % % % % % % % % % % % % %     end
% % % % % % % % % % % % % % % % % % % % % % % end
% % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % VOWELS = { 'AA','AE', 'AH', 'AO', 'AW', 'AY', 'EH', 'ER', 'EY', 'IH', 'IY', 'OW', 'OY', 'UH', 'UW' };
% % % % % % % % % % % % % % % % % % % % % % % vowels = bml_annot_table(syllables(startsWith(syllables.phoneme, VOWELS), :));

%% loading produced audio from zoom
cfg=[];
cfg.epoch = runs_smsl;
cfg.roi=sync(sync.chantype=="directionalmicaec",:);
cfg.chantype = 'audio';
cfg.relabel = 'audioAEC_p';
cfg.timetol_consolidate = timetol; % if you get an error, increase if necessary based on max delta value in the error message
cfg.match_labels = false;
audioAEC_p = bml_load_epoched(cfg);

%% create time series for formant values and write to \derivatives
NEW_DER_NAME = 'acousticspectrum';
NEW_DER_PATH = [PATH_DER_SUB filesep NEW_DER_NAME];
if ~exist(NEW_DER_PATH, 'dir')
    mkdir(NEW_DER_PATH)
end

for irun = 1:length(audioAEC_p.trial) % do we need to iterate through multiple SMSL runs? audio is only ever captured in a single audiofile during intraop
    file = [];
    file.Dir = [PATH_ANALYSIS filesep 'data' filesep];
    file.Name = ['sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_run-' sprintf('%02d',runs_smsl.run(irun))];
    file.Tail = '_recording-directionalmicaec';
    file.Path = [file.Dir file.Name file.Tail '.wav'];
    
    % copy wav into local ./data folder
    audiowrite(file.Path, audioAEC_p.trial{irun}, audioAEC_p.fsample);
    
    % call Praat to extract pitch and formant time series
    fprintf('Calling Praat to extract pitch and formants...\n');
    % extractF0F1F2.praat directory name formantCeilingHz pitchLowerHz
    % pitchUpperHz
    cmd = ['"C:\Program Files\Praat\Praat.exe" --run ', praat_script_path];    
    cmd = [cmd ' ' file.Dir];
    cmd = [cmd ' ' file.Name file.Tail];
    cmd = sprintf('%s %d', cmd, PCfg.formantCeiling);
    cmd = sprintf('%s %d', cmd, PCfg.pitchLower);
    cmd = sprintf('%s %d', cmd, PCfg.pitchUpper);
    system(cmd); % run praat script to extract pitch and formants
    fprintf('Praat finished \n\n');
    
    file.Path = [file.Dir file.Name file.Tail '.Formant'];
    formant = formantRead(file.Path);
    formant.F123 = zeros(3, length(formant.frame)); % array of formants 1, 2, 3
    for i = 1:length(formant.frame)
        if length(formant.frame{i}.frequency) < 3 
           % Praat had trouble finding formants properly
           formant.frame{i}.frequency = padarray(formant.frame{i}.frequency, [0, 3-length(formant.frame{i}.frequency)], 'post');
           
        end
        formant.F123(:, i) = formant.frame{i}.frequency(1:3); % best estimate of fundamental frequency
    end
    ft = []; 
    ft.label = {'acousticspectrum_F1', 'acousticspectrum_F2', 'acousticspectrum_F3' };
    ft.time = {audioAEC_p.time{irun}(1) + formant.t};
    ft.trial = {formant.F123};
    ft.fsample = 1/formant.dx;
    ft = ft_datatype_raw(ft);
    
    file.Tail2 = '_acousticspectrum-formant';
    fpath = [NEW_DER_PATH filesep file.Name file.Tail2];
    save(fpath, '-struct', 'ft');
    

    file.Path = [file.Dir file.Name file.Tail '.Pitch'];
    pitch = pitchRead(file.Path);
    pitch.F0 = zeros(1, length(pitch.frame));
    pitch.intensity = zeros(1, length(pitch.frame));
    for i = 1:length(pitch.frame)
        pitch.F0(i) = pitch.frame{i}.frequency(1); % best estimate of fundamental frequency
        pitch.intensity(i) = pitch.frame{i}.intensity;
    end
    ft = []; 
    ft.label = {'acousticspectrum_pitch', 'acousticspectrum_intensity'};
    ft.time = {audioAEC_p.time{irun}(1) + pitch.t};
    ft.trial = {[pitch.F0; pitch.intensity]};
    ft.fsample = 1/pitch.dx;
    ft = ft_datatype_raw(ft);
    
    file.Tail = '_acousticspectrum-pitch';
    filePath = [NEW_DER_PATH filesep file.Name file.Tail];
    save(filePath, '-struct', 'ft');
    
%     %  pitch estimations with custom implementation
%     [f0,t,~] = voicepitch(audioAEC_p.trial{irun}(:),audioAEC_p.fsample); 
%     ft = []; 
%     ft.label = {'acousticspectrum_pitchMan_01'};
%     ft.time = {audioAEC_p.time{irun}(1) + t};
%     ft.trial = {f0};
%     ft.fsample = 1/mean(diff(t));
%     ft = ft_datatype_raw(ft);
%     
%     fileDir = [newDataDir filesep]; 
%     fileName = [File.Name '_acousticspectrum-pitchMan01'];
%     filePath = [fileDir fileName];
%     save(filePath, '-struct', 'ft');
    
end

%% LOAD formant and pitch FieldTrip objects

formant = []; % concat all 
for irun = 1:length(audioAEC_p.trial)
    file = []; 
    file.Name = ['sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_run-' sprintf('%02d',runs_smsl.run(irun))];
    file.Tail = '_acousticspectrum-formant';
    file.Path = [PATH_DER_SUB filesep NEW_DER_NAME filesep file.Name file.Tail];
    
    if isempty(formant)
        formant = load(file.Path);
    else %  formant <- already has a ft object
        tmp = load(file.Path);
        cfg = [];
        formant = ft_appenddata(cfg, formant, tmp);
    end
end


pitch = []; % concat all 
for irun = 1:length(audioAEC_p.trial)
    file = []; 
    file.Name = ['sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_run-' sprintf('%02d',runs_smsl.run(irun))];
    file.Tail = '_acousticspectrum-pitch';
    file.Path = [PATH_DER_SUB filesep NEW_DER_NAME filesep file.Name file.Tail];
    
    if isempty(pitch)
        pitch = load(file.Path);
    else %  formant <- already has a ft object
        tmp = load(file.Path);
        cfg = [];
        pitch = ft_appenddata(cfg, pitch, tmp);
    end
end


%% calculate acoustic features, add to produced_syllables annot table

features =     {'intensity', 'pitch', 'F1',    'F2'};
featuresData = {pitch,       pitch,   formant, formant};

for ifeat = 1:length(features)
    feat = features{ifeat};
    data = featuresData{ifeat};
    
    cfg=[];
    syllables.channel = repmat({sprintf('acousticspectrum_%s', feat)}, height(syllables), 1);
    cfg.epoch = syllables;
    cfg.warn = false;
    cfg.minduration = 0.010;
    syllables = bml_annot_calculate(cfg, data, feat, @(x) median(x, 'omitnan'));
    syllables.channel_epoch_orig = [];
    syllables.channel_right = [];
%     vowels.channel = [];
    syllables.(feat)(syllables.(feat) == 0) = NaN;
    
end

syllables.Properties.VariableNames{'intensity'} = 'intensity_praat';
syllables.Properties.VariableNames{'pitch'} = 'F0';

% in addition to Praat's intensity, calculate intensity manually
cfg=[];
cfg.epoch = syllables;
cfg.warn = false;
cfg.minduration = 0.010;
syllables = bml_annot_calculate(cfg, audioAEC_p, 'intensity_rms',@(x) sqrt(sum(x.^2)/length(x)));
syllables.channel = [];

% cfg=[];
% cfg.epoch = sentences;
% cfg.warn = false;
% cfg.minduration = 0.010;
% sentences = bml_annot_calculate(cfg,audioAEC_p,'intensity_rms',@(x) sqrt(sum(x.^2)/length(x)));
% sentences.channel = [];






% % % % % % % % % % % % % % % % % % % % %% combine sentences and vowels
% % % % % % % % % % % % % % % % % % % % % collapse across vowels in a trial
% % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % voi = {'IY', 'UW', 'AA'};
% % % % % % % % % % % % % % % % % % % % formantsStr = {'F1', 'F2'};
% % % % % % % % % % % % % % % % % % % % for isent = 1:height(sentences)
% % % % % % % % % % % % % % % % % % % %     idxs = vowels.run_id==sentences.run_id(isent) & vowels.trial_id==sentences.trial_id(isent);
% % % % % % % % % % % % % % % % % % % %     subset = vowels(idxs, :);
% % % % % % % % % % % % % % % % % % % %     
% % % % % % % % % % % % % % % % % % % %     % these vowels should be produced in one single trial--therefore should be all Lombard=1 or Lombard=0 
% % % % % % % % % % % % % % % % % % % %     assert(sum(diff(subset.noise_type))==0); 
% % % % % % % % % % % % % % % % % % % %     sentences.noise_type(isent) = subset.noise_type(1); 
% % % % % % % % % % % % % % % % % % % %     
% % % % % % % % % % % % % % % % % % % % %     clearvars IH UW AA
% % % % % % % % % % % % % % % % % % % % %     i.F1 = subset.F1(startsWith(subset.phoneme, 'IH'));
% % % % % % % % % % % % % % % % % % % %     
% % % % % % % % % % % % % % % % % % % %     for ivoi = 1:length(voi)
% % % % % % % % % % % % % % % % % % % %         for iform = 1:length(formantsStr)
% % % % % % % % % % % % % % % % % % % %             sentences{isent, [voi{ivoi} '_' formantsStr{iform}]} = mean(subset.(formantsStr{iform})(startsWith(subset.phoneme, voi{ivoi})));
% % % % % % % % % % % % % % % % % % % %         end
% % % % % % % % % % % % % % % % % % % %     end
% % % % % % % % % % % % % % % % % % % %     sentences.vowel_duration(isent) = mean(subset.duration, 'omitnan');
% % % % % % % % % % % % % % % % % % % %     sentences.F0(isent) = mean(subset.F0, 'omitnan');
% % % % % % % % % % % % % % % % % % % %     sentences.intensity_rms(isent) = mean(subset.intensity_rms, 'omitnan');
% % % % % % % % % % % % % % % % % % % %     sentences.intensity_praat(isent) = mean(subset.intensity_praat, 'omitnan');
% % % % % % % % % % % % % % % % % % % %    
% % % % % % % % % % % % % % % % % % % % %     sent.iF1 = subset.F1(startsWith(subset.phoneme, 'IH'));
% % % % % % % % % % % % % % % % % % % % end
% % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % CALCULATE FCR per sentence
% % % % % % % % % % % % % % % % % % % % sentences.FCR = ((sentences.UW_F2) + (sentences.AA_F2) + (sentences.IY_F1) + (sentences.UW_F1)) ./ ((sentences.IY_F2) + (sentences.AA_F1));





%% write to disk
bml_annot_write_tsv(syllables, [PATH_DER_SUB filesep 'annot' filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_annot-produced-syllables-acoustics.tsv']);



%% Detect acoustic edges and write 
pitch = []; % concat all 
for irun = 1:length(audioAEC_p.trial)
    file = []; 
    file.Name = ['sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_run-' sprintf('%02d',runs_smsl.run(irun))];
    file.Tail = '_acousticspectrum-pitch';
    file.Path = [PATH_DER_SUB filesep NEW_DER_NAME filesep file.Name file.Tail];
    
    if isempty(pitch)
        pitch = load(file.Path);
    else %  formant <- already has a ft object
        tmp = load(file.Path);
        cfg = [];
        pitch = ft_appenddata(cfg, pitch, tmp);
    end
end







%%
% %% plot 
% close all; 
% 
% X0 = {vowels.pitch_mean(vowels.noise_type == 0), vowels.pitch_mean(vowels.noise_type == 1)};
% raincloud(X0, 'data_labels', {'control', 'lombard'});
% %% Calculating pitch for 
% 
% %sentences
% cfg=[];
% cfg.epoch = ITG;
% cfg.warn = false;
% cfg.minduration = 0.010;
% ITG = bml_annot_calculate(cfg,audio_p,'rms_audio_p',@(x) sqrt(sum(x.^2)/length(x)));
% ITG.channel = [];
% 
% cfg=[];
% cfg.epoch = ITG;
% cfg.warn = false;
% cfg.minduration = 0.010;
% ITG = bml_annot_calculate(cfg,audioAEC_p,'rms_audioAEC_p',@(x) sqrt(sum(x.^2)/length(x)));
% ITG.channel = [];
% 
% bml_annot_write_tsv(ITG, [PATH_ANALYSIS filesep 'data' filesep 'sub-' SUBJECT '_ses-' SESSION '_task-' TASK '_annot-itg.tsv']);


