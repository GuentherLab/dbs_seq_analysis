triplet_subjects = [];
SMSL_subjects = [];

%% triplet loop
for i=1:length(triplet_subjects)
    SUBJECT = triplet_subjects(i); 
    %SUBJECT = 'DBS3001';
    disp(SUBJECT);

    PATH_DATASET = 'Z:\DBS';
    PATH_SUB = [PATH_DATASET filesep SUBJECT];
    PATH_PREPROC_DATA = [PATH_SUB filesep 'Preprocessed Data'];
    PATH_FT = [PATH_PREPROC_DATA filesep 'FieldTrip'];
    PATH_SYNC = [PATH_PREPROC_DATA filesep 'Sync'];
    PATH_ANNOT = [PATH_SYNC filesep 'annot'];

    filename = [SUBJECT '_ft_raw_session.mat'];

    tempname = load([PATH_FT filesep filename]);
    FT_file = tempname.D;

    % calculate frequencies
    freqs = 10.^(linspace(0,2.5,20)); % number of frequencies: 20
    for ifreq = 1:length(freqs)
        thisfreq = freqs(ifreq)
        cfg=[];
        cfg.out_freq = 100;
        cfg.wav_freq = thisfreq;
        cfg.wav_width = 7;
        D_wavtransf{ifreq} = bml_envelope_wavpow(cfg,FT_file);
    end

    % break up into trials
    numFreq = length(D_wavtransf);
    annot = readtable([PATH_ANNOT filesep SUBJECT '_trial_epoch'],'Delimiter','\t');

    % create new table with freqband file.trial and .time stored continuously
    continuous = cell(1,numFreq);
    for j = 1:numFreq
        continuous{1,j} = struct('time','trial');
        continuous{1,j}.time = horzcat(D_wavtransf{1,j}.time{1,1}, D_wavtransf{1,j}.time{1,2}, ...
            D_wavtransf{1,j}.time{1,3}, D_wavtransf{1,j}.time{1,4});
        continuous{1,j}.trial = horzcat(D_wavtransf{1,j}.trial{1,1}, D_wavtransf{1,j}.trial{1,2}, ...
            D_wavtransf{1,j}.trial{1,3}, D_wavtransf{1,j}.trial{1,4});
    end
    
    disp('calculating timepoints');
    % find all timepoints between start and end of each trial
    timepoints = []; % each row is a trial; first column is start location; second column is end location
        % both timepoints are from continuous
    annot_sz = size(annot);
    j=1;
    for k = 1:annot_sz(1)
        % for each timepoint (a) iterate through continuous and for each column in continuous (b) do a-b
        % when a-b becomes < 0, the previous timepoint is the selected column
        % optimization: after one timepoint is calculated, the calculation does not need to be performed on the previous set of times in continuous
    
        % loop to determine onset column
        onset=1;
        while onset<annot{k,2}
            onset = continuous{1,1}.time(1,j);
            j=j+1;
        end
        timepoints(k,1) = j;
        
        offset=1;
        while offset<annot{k,3}
            offset = continuous{1,1}.time(1,j);
            j=j+1;
        end
        timepoints(k,2) = j;
    end
    
    trialed = cell(1,numFreq);
    % loop through each frequency
    for n = 1:numFreq
        % copy other data stored in the table to the new variable (basically not .time and .trial)
        trialed{1,n} = struct('label','trial','time','cfg','hdr','fsample');
        trialed{1,n}.label = D_wavtransf{1,n}.label;
        trialed{1,n}.trial = {};
        trialed{1,n}.time = {};
        trialed{1,n}.cfg = D_wavtransf{1,n}.cfg;
        trialed{1,n}.hdr = D_wavtransf{1,n}.hdr;
        trialed{1,n}.fsample = D_wavtransf{1,n}.fsample;
        
        % paste the data into the new table under the correct trial number
        % run through each trial
        for j=1:annot_sz(1) % trial
            trial_temp = [];
            count = 1;
            for k=timepoints(j,1):timepoints(j,2) % timepoints
                % take each datapoint between onset and offset from continous and put into .trial
                % for each electrode
                cont_sz = size(continuous{1,n}.trial);
                for m=1:cont_sz(1);
                    trial_temp(m,count) = continuous{1,n}.trial(m,k); % need to do for each electrode
                end
                
                % take each timepoint between onset and offset and put into .time
                time_temp(1,count) = continuous{1,n}.trial(1,k);
                count = count+1;
            end
            trialed{1,n}.trial{1,j} = trial_temp;
            trialed{1,n}.time{1,j} = time_temp;
        end
    end

    save([PATH_FT filesep SUBJECT '_ft_raw_session_freqbands.mat'],'trialed','-v7.3');
end

%% SMSL loop
for i=1:length(SMSL_subjects)
    SUBJECT = SMSL_subjects(i); 
    %SUBJECT = 'sub-DM1005';
    disp(SUBJECT);

    PATH_DATASET = 'Y:\DBS';
    PATH_DER = [PATH_DATASET filesep 'derivatives'];
    PATH_SUB = [PATH_DER filesep SUBJECT];
    PATH_FT = [PATH_SUB filesep 'fieldtrip'];
    PATH_ANNOT = [PATH_SUB filesep 'annot'];

    filename = [SUBJECT '_ses-intraop_task-smsl_ft-raw'];

    tempname = load([PATH_FT filesep filename]);
    FT_file = tempname.D;

    % compute frequencies
    freqs = 10.^(linspace(0,2.5,20)); % number of frequencies: 20
    for ifreq = 1:length(freqs)
        thisfreq = freqs(ifreq)
        cfg=[];
        cfg.out_freq = 100;
        cfg.wav_freq = thisfreq;
        cfg.wav_width = 7;
        D_wavtransf{ifreq} = bml_envelope_wavpow(cfg,FT_file); 
    end

    % break up into trials
    numFreq = length(D_wavtransf);
    annot = readtable([PATH_ANNOT filesep SUBJECT '_ses-intraop_task-smsl_annot-trials.tsv'],'FileType','text','Delimiter','\t');

    continuous = cell(1,numFreq);
    for j = 1:numFreq
        continuous{1,j} = struct('time','trial');
        continuous{1,j}.time = D_wavtransf{1,j}.time{:,:};
        continuous{1,j}.trial = D_wavtransf{1,j}.trial{:,:};
    end

    disp('calculating timepoints');
    % find all timepoints between start and end of each trial
    timepoints = []; % each row is a trial; first column is start location; second column is end location
        % both timepoints are from continuous
    annot_sz = size(annot);
    j=1;
    for k = 1:annot_sz(1)
        % for each timepoint (a) iterate through continuous and for each column in continuous (b) do a-b
        % when a-b becomes < 0, the previous timepoint is the selected column
        % optimization: after one timepoint is calculated, the calculation does not need to be performed on the previous set of times in continuous
    
        % loop to determine onset column
        onset=1;
        while onset<annot{k,1}
            onset = continuous{1,1}.time(1,j);
            j=j+1;
        end
        timepoints(k,1) = j;
        
        offset=1;
        offsettimep = annot{k,1} + annot{k,2}; % annot{i,2} is the duration, not offset
        while offset<offsettimep
            offset = continuous{1,1}.time(1,j);
            j=j+1;
        end
        timepoints(k,2) = j;
    end
    
    trialed = cell(1,numFreq);
    % loop through each frequency
    for n = 1:numFreq
        % copy other data stored in the table to the new variable (basically not .time and .trial)
        trialed{1,n} = struct('label','trial','time','cfg','hdr','fsample');
        trialed{1,n}.label = D_wavtransf{1,n}.label;
        trialed{1,n}.trial = {};
        trialed{1,n}.time = {};
        trialed{1,n}.cfg = D_wavtransf{1,n}.cfg;
        trialed{1,n}.hdr = D_wavtransf{1,n}.hdr;
        trialed{1,n}.fsample = D_wavtransf{1,n}.fsample;
        
        % paste the data into the new table under the correct trial number
        % run through each trial
        for j=1:annot_sz(1) % trial
            trial_temp = [];
            count = 1;
            for k=timepoints(j,1):timepoints(j,2) % timepoints
                % take each datapoint between onset and offset from continous and put into .trial
                % for each electrode
                cont_sz = size(continuous{1,n}.trial);
                for m=1:cont_sz(1);
                    trial_temp(m,count) = continuous{1,n}.trial(m,k); % need to do for each electrode
                end
                
                % take each timepoint between onset and offset and put into .time
                time_temp(1,count) = continuous{1,n}.trial(1,k);
                count = count+1;
            end
            trialed{1,n}.trial{1,j} = trial_temp;
            trialed{1,n}.time{1,j} = time_temp;
        end
    end

    save([PATH_FT filesep SUBJECT '_ses-intraop_task-smsl_ft-raw_freqbands.mat'],'trialed','-v7.3');
end
