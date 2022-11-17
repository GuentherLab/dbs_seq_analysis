%% this version reads audio from the full session recording via bml_redefinetrial.m
%    ...... which seems to cause problems on Mac
%% subsequent versions read in audio trial files cut from the full session

%%% call this script for each subject after specifying paths
%
%%% semi-manually determine voice onset and offset times for GO trials
%%% reaction time (trials.ontime) = time after go beep offset, which is 50ms after go beep onset
%
% score both accurate and error trials so we can get RTs for all usuable trials
%
% make sure that the following Matlab preference is checked: General / Deleting Files / Move to the Recycle Bin
%
% updated by Andrew Meier 2021/11/1

% loading annotation tables
sync = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_sync.tsv']);
sessions = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_sessions.tsv']);
runs = bml_annot_read_tsv([PATH_ANNOT filesep 'sub-' SUBJECT '_runs.tsv']);
server_comp_name = 'NSSBML01';

if exist(durations_file, 'file') % if some scoring has been performed for this subject/task
    load(durations_file) % load preexisting scoring
elseif ~exist(durations_file , 'file') % starting scoring for this subject/task
    load(trials_file)
    % add vars to trial table
    ntrials = height(trials);
    cellcol = cell(ntrials,1);
    nancol = NaN(ntrials,1); 
    % ontime and offtime are in ms; time after audio_go_onset (ontime = reaction time)
    %       ... NaN = not yet scored or could not be scored due to speech error
    % correct = did not contain sequencing error; NaN = unscored
    trials = [trials, table(nancol, nancol, nancol, 'VariableNames',...
                       {'ontime', 'offtime', 'ut_duration'} )];
end
trials = movevars(trials, {'ontime', 'offtime', 'ut_duration'}, 'Before', 'visual_onset'); 

% unscored trials are those [without labeled onset or offset] AND [not unusable]
unscored_trials = find([isnan(trials.ontime) | isnan(trials.offtime)] & ~trials.unusable_trial);
n_unscored_trials = length(unscored_trials);

% load and organize audio and trial data
trials = trials(trials.is_stoptrial==0,:); % only assign durations to GO trials
trials.starts = trials.audio_go_offset + postbeep_buffer_ms/1e3;
trials = bml_annot_table(trials);
cfg=[];
[audiofiledir, audiofilename] = fileparts(audiofile);
cfg.roi = sync(contains(sync.name, audiofilename),:);
if ~strcmp(server_comp_name, getenv('computername')) % if we're not on the BML server
    cfg.roi.folder{1} = audiofiledir; % update the folder; the sync table will list BML server folder
end
session_aud = bml_load_continuous(cfg);

% figure settings
screen_pts = get(0,'ScreenSize');
pos = [screen_pts(1) screen_pts(2) screen_pts(3) screen_pts(4) - 45];

%% score each unscored trial
for i_unscored = 1:n_unscored_trials
    itrial = unscored_trials(i_unscored); % itrial index within complete trial table (scored and unscored)
    cfg=[];
    cfg.epoch=trials(itrial,:);
    thistrial = bml_redefinetrial(cfg,session_aud);
%     bml_praat(thistrial);

    fs = thistrial.fsample; 
    trialaud = thistrial.trial{1};
    winSize = round(fs * .0015); %sets winSize of 66 samples (about .15% of sampling rate) = 1.5 ms
    winSize_ms = winSize / fs * 1e3;
    stride_samples = round(fs * .001); %sets Incr of 44 samples (about .1% of sampling rate) = 1 ms
    stride_ms = stride_samples / fs * 1e3; 
    time = 0:1/fs:(length(trialaud)-1)/fs; %creates time vector going from 0 to length of audio clip in s, in intervals of 1/fs
    iter = 1;
    speechOn = 0; %indicates speech Onset and speech Offset have not been set yet for this trial
    speechOff = 0;
    I = []; %creates Intensity variable to be filled below
    tm = []; %creates tm variable to be filled below
    BegWin = 1;  %uncomment if beep is not audible to start at beginning of recording
    %BegWin = round(1.85*fs) + 1; %if beeps audible, use this line instead to start first window after the latest jittered beep
    EndWin = BegWin + winSize;  %moving window of 1.5 ms, advancing 1 ms each time (some overlap)

    %% onset/offset detection loop
    while EndWin < length(trialaud) % && speechOff == 0  %loops until it reaches the end of audio file (y) OR sets offset time
        dat = detrend(trialaud(BegWin:EndWin), 0)';  %detrends mean from data
        dat = convn(dat,[1;-.95]); %high-pass filter (removes low-frequency info); potentially remove! 
        int = sum(dat.^2); %sum of dat squared
        I(iter) = 20*log10(int/.0015); %000015;  calculates I (dB) for this window; /.0015 finds mean of squared
        tm(iter) = time(BegWin); %sets time for the start of the window

        onset_window = max(1, iter-OnDur) : iter; 
        n_superthresh = length(find(I(onset_window) > onThresh)); % number of samples meeting threshold
        offset_window = max(1, iter-OffDur) : iter; 
        n_subthresh = length(find(I(offset_window) < offThresh)); % number of samples meeting threshold

        % checks for following conditions for Speech Onset:
        %1. Iter has passed the  minimum onDur # of seconds; %2. speechOnset hasn't already been set
        %3. number of samples exceeding Intensity threshold is equal to OnDur # of seconds
        %4. time in which iter beyond onDur is greater than 90 ms- cutpoint for anticipation errors/background noise 
        if iter > OnDur && speechOn == 0 &&...
            n_superthresh >= thresh_proportionOfSamples * length(I(iter-OnDur:iter)) %&& tm(iter-OnDur) > .09
            speechOn = 1; %marks that a speech onset has been set
            speechOnTime = tm(iter-OnDur); %calculate onset time (onDur samples prior to current iteration, where it actually started)
            speechOnIter = iter; 

            if widen_window_after_onset
                EndWin = BegWin + round(fs * .010);  %creates larger window for speech offset calculations (10 ms instead)
            end

        %checks for following conditions for speechOffset:
        %1. Iter greater than OffDur minimum (can't reach minimum until iter reaches that number)
        %2. speechOn marked in prior step; %3. No speechOff marked yet
        %4. no segment with I > offThresh for the length of OffDur
        %5. time between OffDur and iter is at least 400 ms (minimum length of stimuli- may need to update
        elseif iter > OffDur && speechOn == 1 && speechOff ==0 &&...
                n_subthresh >= thresh_proportionOfSamples * length(I(iter-OffDur:iter)) &&...
                tm(iter-OffDur) - speechOnTime > .40
            speechOff = 1;  %marks that speechOff has been set
            speechOffTime = tm(iter-OffDur); %calculates the point of speechOff, OffDur# of samples prior to current iteration point
            speechOffIter = iter; 
        end

        BegWin = BegWin + stride_samples; %moves the window forward 1 ms for next iter
        EndWin = EndWin + stride_samples; 
        iter = iter + 1;
    end
    
    %%
   %if while loop reaches end of audio without finding speech on/off set
    if speechOn == 0
        speechOnTime = 0; %sets speechOnTime as 0 if it could never be detected
        disp('Speech onset time not detected.')
    end
    if speechOff == 0
        speechOffTime = recordTime; %sets speechOffTime as end of recording if it could never be detected
        disp('Speech offset time not detected; marked as end of recording.')
    end

    %%Second GUI---------------------------------------------------
    guidat.hfig = figure('Position', pos);

    %TOP PLOT------------------------------------------------------
    yvis = trialaud;
    guidat.hsp1 = subplot(3, 1, 1); plot(time, detrend(yvis, 0), 'k'); hold on;
    %title(['Token is ' char(StimList(i)) '  < press spacebar to continue >']);
    axis tight;
    ax = axis;

    if speechOn == 1 && speechOff == 1
        line([speechOnTime speechOnTime], [ax(3) ax(4)], 'Color', 'k', 'LineWidth', 2.0);
        line([speechOffTime speechOffTime], [ax(3) ax(4)], 'Color', 'k', 'LineWidth', 2.0);
    end
    ylabel('Waveform')

    %MIDDLE PLOT---------------------------------------------------
    guidat.hsp2 = subplot(3, 1, 2); plot(tm, I, 'k'); hold on;
    bx = axis;

    if speechOn == 1 && speechOff == 1
        line([speechOnTime speechOnTime], [bx(3) bx(4)], 'Color', 'k', 'LineWidth', 2.0);
        line([speechOffTime speechOffTime], [bx(3) bx(4)], 'Color', 'k', 'LineWidth', 2.0);
    end
    axis([ax(1) ax(2) bx(3) bx(4)]);
    ylabel('Intensity')
    
    %BOTTOM PLOT---------------------------------------------------

     %alternate spectrogram code
     %nwin = 512; % samples  %noverlap = 256; %samples  %nfft = 512; %samples
     %spectrogram(yvis, nwin, noverlap, nfft, fs, 'yaxis');
     %ylim([0 4000]);

    guidat.hsp3 = subplot(3, 1, 3); hold on;
    show_spectrogram(trialaud, fs, 'noFig');    
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');

    %mark SpeechOn/Offset Times on spectrogram
    cx =axis;
    if speechOn == 1 && speechOff == 1
        line([speechOnTime speechOnTime], [cx(3) cx(4)], 'Color', 'k', 'LineWidth', 2.0);
        line([speechOffTime speechOffTime], [cx(3) cx(4)], 'Color', 'k', 'LineWidth', 2.0);
    end

    guidat.hLineOn = [NaN, NaN, NaN];
    guidat.hLineEnd = [NaN, NaN, NaN];

    %% manually adjust onset/offset times
    while 1
        %display menu with analysis choices
        accept = menu('Select', 'Accept', 'Edit Onset', 'Edit Offset', 'Edit Onset & Offset', 'Play Segment');

        switch accept
        case 1  %Accept RMS-generated on/off times
            break;

        case 2  %Edit RMS-generated ON time only
            bTimeLabelsOkay = 0; %mark TimeLabels as wrong

            while ~bTimeLabelsOkay  %loop until TimeLabels fixed
                %input times
                set(0, 'CurrentFigure', guidat.hfig);
                set(gcf, 'CurrentAxes', guidat.hsp1);
                ys = get(gca, 'YLim');

                for j0 = 1 : length(guidat.hLineOn)
                    if ~isnan(guidat.hLineOn(j0))
                        delete(guidat.hLineOn(j0));
                    end
                end
                for j0 = 1 : length(guidat.hLineEnd)
                    if ~isnan(guidat.hLineEnd(j0))
                        delete(guidat.hLineEnd(j0));
                    end
                end

                title('Set the onset time', 'Color', 'b'); drawnow;
                coord1 = ginput(1);

                set(gcf, 'CurrentAxes', guidat.hsp1);
                guidat.hLineOn(1) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                set(gcf, 'CurrentAxes', guidat.hsp2);
                guidat.hLineOn(2) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                set(gcf, 'CurrentAxes', guidat.hsp3);
                guidat.hLineOn(3) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                set(gcf, 'CurrentAxes', guidat.hsp1);

                numResp_on = coord1(1);  %Save coordinate for mouse click (manually marked onset)
                numResp_end = speechOffTime %original variable

                %Confirm that manually marked speech onset occurs before end of speech
                bTimeLabelsOkay = (speechOffTime > numResp_on);
                if ~bTimeLabelsOkay
                    title('The onset time you set is incorrect. Try again...', 'Color', 'r');
                    drawnow;
                    pause(1);
                else
                    title('', 'Color', 'b'); drawnow;
                end
            end

            speechOnTime = numResp_on; %Replace manual measurement with automatic measurement
            title('Click ACCEPT to keep or EDIT to change manual measurements.'); drawnow; 
            pause(pausesec); %then returns to main menu (accept), where accept will add duration to data structure

        case 3  %Edit RMS-generated OFF time
            bTimeLabelsOkay = 0; %mark TimeLabels as wrong

            while ~bTimeLabelsOkay  %loop until TimeLabels fixed
                %input times
                set(0, 'CurrentFigure', guidat.hfig);
                set(gcf, 'CurrentAxes', guidat.hsp1);
                ys = get(gca, 'YLim');

                for j0 = 1 : length(guidat.hLineOn)
                    if ~isnan(guidat.hLineOn(j0))
                        delete(guidat.hLineOn(j0));
                    end
                end
                for j0 = 1 : length(guidat.hLineEnd)
                    if ~isnan(guidat.hLineEnd(j0))
                        delete(guidat.hLineEnd(j0));
                    end
                end

                numResp_on = speechOnTime;

                title('Set the offset time', 'Color', 'b'); drawnow;
                coord2 = ginput(1);

                set(gcf, 'CurrentAxes', guidat.hsp1);
                guidat.hLineEnd(1) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                set(gcf, 'CurrentAxes', guidat.hsp2);
                guidat.hLineEnd(2) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                set(gcf, 'CurrentAxes', guidat.hsp3);
                guidat.hLineEnd(3) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                set(gcf, 'CurrentAxes', guidat.hsp1);

                numResp_end = coord2(1); %Save coordinate for mouse click (manually marked onset)

                set(gcf, 'CurrentAxes', guidat.hsp1);
                set(gca, 'YLim', ys);

                %Confirm that manually marked speech onset occurs before end of speech
                bTimeLabelsOkay = (numResp_end > speechOnTime);
                if ~bTimeLabelsOkay
                    title('The offset time you set is incorrect. Try again...', 'Color', 'r');
                    drawnow;
                    pause(1);
                else
                    title('', 'Color', 'b'); drawnow;
                end
            end

            speechOffTime = numResp_end; %Replace manual measurements with automatic measurement
            title('Click ACCEPT to keep or EDIT to change manual measurements.'); drawnow; 
            pause(pausesec); %then returns to main menu (accept), where accept will add duration to data structure

        case 4  %Edit RMS-generated on/off times
            bTimeLabelsOkay = 0; %mark TimeLabels as wrong

            while ~bTimeLabelsOkay  %loop until TimeLabels fixed
                %input times
                set(0, 'CurrentFigure', guidat.hfig);
                set(gcf, 'CurrentAxes', guidat.hsp1);
                ys = get(gca, 'YLim');

                for j0 = 1 : length(guidat.hLineOn)
                    if ~isnan(guidat.hLineOn(j0))
                        delete(guidat.hLineOn(j0));
                    end
                end
                for j0 = 1 : length(guidat.hLineEnd)
                    if ~isnan(guidat.hLineEnd(j0))
                        delete(guidat.hLineEnd(j0));
                    end
                end

                title('Set the onset time', 'Color', 'b'); drawnow;
                coord1 = ginput(1);

                set(gcf, 'CurrentAxes', guidat.hsp1);
                guidat.hLineOn(1) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                set(gcf, 'CurrentAxes', guidat.hsp2);
                guidat.hLineOn(2) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                set(gcf, 'CurrentAxes', guidat.hsp3);
                guidat.hLineOn(3) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                set(gcf, 'CurrentAxes', guidat.hsp1);

                numResp_on = coord1(1);  %Save coordinate for mouse click (manually marked onset)

                title('Set the offset time', 'Color', 'b'); drawnow;
                coord2 = ginput(1);

                set(gcf, 'CurrentAxes', guidat.hsp1);
                guidat.hLineEnd(1) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                set(gcf, 'CurrentAxes', guidat.hsp2);
                guidat.hLineEnd(2) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                set(gcf, 'CurrentAxes', guidat.hsp3);
                guidat.hLineEnd(3) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                set(gcf, 'CurrentAxes', guidat.hsp1);

                numResp_end = coord2(1); %Save coordinate for mouse click (manually marked onset)

                set(gcf, 'CurrentAxes', guidat.hsp1);
                set(gca, 'YLim', ys);

                %Confirm that manually marked speech onset occurs before end of speech
                bTimeLabelsOkay = (numResp_end > numResp_on);
                if ~bTimeLabelsOkay
                    title('The onset and offset times you set are incorrect. Try again...', 'Color', 'r');
                    drawnow;
                    pause(pausesec);
                else
                    title('', 'Color', 'b'); drawnow;
                end
            end

            speechOnTime = numResp_on; %Replace manual measurements with automatic measurement
            speechOffTime = numResp_end; 
            title('Click ACCEPT to keep or EDIT to change manual measurements.'); drawnow; 
            pause(pausesec); %then returns to main menu (accept), where accept will add duration to data structure

        case 5 % Select and play
            set(0, 'CurrentFigure', guidat.hfig);
            set(gcf, 'CurrentAxes', guidat.hsp1);
            ys = get(gca, 'YLim');

            green = [0, 0.5, 0];
            title('Set beginning of sound', 'Color', green); drawnow;
            coord1 = ginput(1);
            set(gcf, 'CurrentAxes', guidat.hsp1);
            guidat.hPBLine0 = plot(repmat(coord1(1), 1, 2), ys, '--', 'Color', green);
            drawnow;

            title('Set end of sound', 'Color', green); drawnow;
            coord2 = ginput(1);
            set(gcf, 'CurrentAxes', guidat.hsp1);
            guidat.hPBLine1 = plot(repmat(coord2(1), 1, 2), ys, '-', 'Color', green);

            drawnow;
            title('', 'Color', 'b'); drawnow;

            ysnip = trialaud(time >= coord1(1) & time < coord2(1));

            %play audio (if segment is selected)
            if ~isempty(ysnip)
                    soundsc(ysnip, fs);
            else
                fprintf(1, 'WARNING: the selected audio appears to be empty. It will not be played.\n');
            end

            pause(pausesec);

            delete(guidat.hPBLine0);
            delete(guidat.hPBLine1);
        end  %end of "accept" GUI
    end
    close(guidat.hfig)
    trials.ontime(itrial) = speechOnTime + reaction_time_adjust_sec;
    trials.offtime(itrial) = speechOffTime + reaction_time_adjust_sec; 
    trials.ut_duration(itrial) = trials.offtime(itrial) - trials.ontime(itrial); 
    if mod(backup_every_n_trials, itrial) == 0
        save(durations_file_local_backup, 'trials')
        delete(durations_file_local_backup) % delete to have extra copy in recycle bin
        fprintf('%s\n', ['Saved and deleted backup of durations file:  ', durations_file_local_backup])
    end
    save(durations_file, 'trials')
    fprintf('%s\n', ['Saved durations for ', trials.filename{itrial}, ' into: ', durations_file])
end

close all
fprintf(['\n Finished getting GO trial durations for ', SUBJECT, ', session = ', SESSION, '\n'])

% % % % % 
% % % % %                 
% % % % %                 
% % % % %                 %%
%%
function show_spectrogram(varargin)
if nargin >= 2
    w = varargin{1};
    fs = varargin{2};
elseif nargin == 1
    wavfn = varargin{1};
    [w, fs] = wavread(wavfn);
else
    fprintf('Wrong number of input arguments\n');
    return
end
    

% [s, f, t]=spectrogram(w, 128, 96, 1024, fs);

            nwin = 256; % samples
            noverlap = 192; %samples
            nfft = 1024; %samples
            
[s, f, t]=spectrogram(w, nwin, noverlap, nfft, fs);
 %spectrogram(yvis, nwin, noverlap, nfft, fs, 'yaxis');
imagesc(t, f, 10 * log10(abs(s))); hold on;
axis xy;
hold on;
set(gca, 'YLim', [f(1), f(end)]);

ylim = 4000;
set(gca, 'YLim', [0, ylim]);
set(gca, 'XLim', [t(1), t(end)]);
return
end
    