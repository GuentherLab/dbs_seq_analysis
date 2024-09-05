% load the data; open the file and the variable in which the data is stored
% load the speech data
% Get the speech onset data. This can be modified to audio or visual onset
% data depending on the requirements
% Select start time of window, window duration and the channels
% input("0 if MSCOHERE, 1 if Wavelet")
% Select range of frequencies you want to observe

data = load('/Users/Temporary/Downloads/sub-DM1005_ses-intraop_task-smsl_ft-raw_filt_trial_ar-E_ref-CTAR_not-denoised.mat').D_trial_ref
sp_data = readtable("/Users/Temporary/Downloads/sub-DM1005_ses-intraop_task-smsl_annot-produced-syllables.tsv", "FileType","text",'Delimiter', '\t');
start_window = 0
window_length = 100
chan_1 = 1
chan_2 = 120
option = 0
freq_lo = 1
freq_hi = 50


fs = data.fsample
sp_on = table2array(sp_data(:, "sp_on"))
f = freq_lo:1:freq_hi

% Processing to get the time window

num_non_nans = 0
for i = 1:1:length(sp_on)
    start_time = sp_on(i) - data.time{i}(1) + start_window/1000
    if isnan(start_time) == 0
        if isnan(window_length) == 0
            if start_time*fs+window_length-1 < length(data.time{i})
                num_non_nans = num_non_nans + 1
            end
        end
    end
end

% Selecting a particular method, either MSCOHERE or Wavelet Coherence
if option == 1
    % wavelet
elseif option == 0
    % mscohere
    tp_x = zeros(1,window_length*(num_non_nans))
    tp_y = zeros(1,window_length*(num_non_nans))
    k = 1
    for i = 1:1:length(sp_on)
        start_time = sp_on(i) - data.time{i}(1) + start_window/1000
        if isnan(start_time) == 0
            if isnan(window_length) == 0
                if start_time*fs+window_length-1 < length(data.time{i})
                    tp_x(1,k:k+window_length-1) = data.trial{i}(chan_1,start_time*fs:start_time*fs+window_length-1)
                    tp_y(1,k:k+window_length-1) = data.trial{i}(chan_2,start_time*fs:start_time*fs+window_length-1)
                    k = k + window_length
                end
            end
        end
    end
    [cxy, f_mscohere] = mscohere(tp_x,tp_y,window_length,0,f,fs)
    plot(f,sqrt(cxy))
    xlabel('frequency')
    ylabel('coherence')
    title('Coherence vs Frequency')
else 
    % return wrong input
end