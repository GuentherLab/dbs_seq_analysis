%% alternative method of concatenateing trialwise data.... not full working; instead use section from P08_detect_artifact_criteria_E

%%% cut overlaps between fieldtrip trials within each run, then concatenate within each run
%
%%% inputs: 
    % cfg.runtable
    %
    % D_in = fieldtrip struct with electrode data to be processed; should be wavelet-transformed first

function D_trials_edited = concat_trials_within_run(cfg, D_trials)

ntrials = numel(D_trials.trial); 
nruns = height(cfg.runs);
fs = D_trials.hdr.Fs; 
sampper = 1/fs; % period
nchans = size(D_trials.trial{1},1); 

D_trials_edited = D_trials; 


trials=table;
trials.start = [cellfun(@(x)x(1),D_trials_edited.time)]';
trials.end = [cellfun(@(x)x(end),D_trials_edited.time)]';

% get run numbers for each trial
for itrial = 1:ntrials
    trials.run(itrial) = min(find(trials.end(itrial) < cfg.runs.ends)); %#ok<MXFND> 
end

% remove trial overlaps by removing from each trial the timepoints after the start of the subsequent trial
%%%% pad gaps between trials within a run
for itrial = 1:ntrials-1
    inds_to_remove = D_trials_edited.time{itrial} >= trials.start(itrial+1); 
    D_trials_edited.time{itrial} = D_trials_edited.time{itrial}(~inds_to_remove); % remove overlapping times
    D_trials_edited.trial{itrial} = D_trials_edited.trial{itrial}(:,~inds_to_remove); % remove overlapping data points

    % if there are gaps between this trial and the next trial in this run, pad gaps with NaNs
    if trials.run(itrial) == trials.run(itrial+1) % if same run
        trialgap = D_trials_edited.time{itrial+1}(1) - D_trials_edited.time{itrial}(end);
        if trialgap > sampper % if there's a gap greater than sample interval 
            npadsamps = floor(trialgap / sampper);    % fill in gap with nans
            D_trials_edited.time{itrial} = [D_trials_edited.time{itrial}, D_trials_edited.time{itrial}(end) + sampper*[1:npadsamps]]; % pad interpolated time
            D_trials_edited.trial{itrial} = [D_trials_edited.trial{itrial}, nan(nchans,npadsamps)]; % pad data
        end

    end
end

% concat within trials
cfg.epoch = cfg.runs;
D_concat = bml_redefinetrial(cfg,D_trials_edited);

D_concat.hdr.nTrials = nruns;
D_concat.sampleinfo = []; % clear this data, as it will likely no longer be accurate