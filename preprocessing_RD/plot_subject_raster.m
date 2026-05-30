%%
clearvars;
TASK = 'smsl';
SESSION = 'intraop';
BAND = 'hg'; % beta-F, hg-E
REF = 'E';
DENOISING = 'CMR_SVD_c2'; % none, CMR, CMR_SVD_c2

rank = 1; % 0, 1
BW = 2; % 2, 10
file = "all"; % "raw" "notch" "notch mask" "power"

SUBJECT_LIST = {'DM1005','DM1007','DM1008','DM1024','DM1025','DM1037'};
SUBJECT_LIST = {'DM1025'};

% check computer, set paths accordingly
compname = getenv('COMPUTERNAME'); 
if any(strcmp(compname, {'MSI','677-GUE-WL-0010','AMSMEIER','NSSBML01'})) % AM computer or Turbo
    setpaths_dbs_seq
else % Rohan's computer
     PATH_DER = '/Volumes/Nexus4/DBS/derivatives'
end

%%
for i_sub = 1:numel(SUBJECT_LIST)
    sub = SUBJECT_LIST{i_sub};
    
    switch file
        case "raw"
            load([PATH DER '/sub-' sub '/fieldtrip/sub-' sub '_ses-intraop_task-smsl_ft-raw.mat'], 'D')
            y = [D.trial{:}];

        case "notch"
            load(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'])
            y = [D_sel_filt.trial{:}];
            % clearvars D_sel_filt

        case "notch mask"
            load(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'])
            y = [D_sel_filt_trial_mask.trial{:}];

        case "power"
            load([PATH_DER 'sub-',sub,'/fieldtrip/sub-',sub,'_ses-',SESSION,'_task-',TASK,'_ft-',BAND,'-trial_ar-',REF,'_ref-',DENOISING,'_not-denoised.mat'])    
             y = [D_wavpow.trial{:}];
             % clearvars D_wavpow.trial
        case "all"
            load([PATH_DER '/sub-' sub '/fieldtrip/sub-' sub '_ses-intraop_task-smsl_ft-raw.mat'], 'D')
            load(['/Users/rohandeshpande/Documents/School/Research/Code/data/ft/sub-' sub '_ft_notch_' num2str(BW) 'Hz_cont.mat'])
            load([PATH_DER '/sub-',sub,'/fieldtrip/sub-',sub,'_ses-',SESSION,'_task-',TASK,'_ft-',BAND,'-trial_ar-',REF,'_ref-',DENOISING,'_not-denoised.mat']) 
    end
end

%% RASTERS
figure; sgtitle(sub)
subplot(3,2,1); title('Raw - log')
y = [D.trial{:}];
imagesc(real(log(y)))

subplot(3,2,2); title('Raw - ranked')
imagesc(rank_data(y))
% clearvars D

subplot(3,2,3); title('Notch - log')
y = [D_sel_filt.trial{:}];
imagesc(real(log(y)))

subplot(3,2,4); title('Notch - ranked')
imagesc(rank_data(y))
% clearvars D_sel_filt

subplot(3,2,5); title('Power')
y = [D_wavpow.trial{:}];
imagesc(y)

subplot(3,2,6); title('Power - ranked')
imagesc(rank_data(y))
% clearvars D_wavpow

%% SCOUTING FOR ELECS
el_range = 55:80;

y = [D.trial{:}]; 
% y = [D_sel_filt.trial{:}];
% y = [D_wavpow.trial{:}];

y = rank_data(y);

figure; imagesc(y(el_range,:))
set(gca,'YTick', 1:length(el_range))
set(gca,'YTickLabel', el_range)

% figure; hold on;
% for i_elec = el_range
%     plot(y(i_elec,:), 'DisplayName',num2str(i_elec))
% end
% legend

%%
y = [D.trial{:}]; 
rank_y = rank_data(y);
temp = [D_wavpow.trial{:}];

figure; hold on;
for elec = 86:126
    x_isnan = isnan(temp(elec,:));

    % find blocks of nans
    % first index of block
     fi = x_isnan(2:end) - x_isnan(1:end-1);
     fi = find(fi==1) + 1;
    
    % last index of block
    li = x_isnan(2:end) - x_isnan(1:end-1);
    li = find(li==-1);
    
    % patch
    try
        p_x = [fi; li; li; fi];
        p_y = [zeros(size(fi)); zeros(size(fi)); ones(size(li)); ones(size(li))];
    catch
        if length(fi) > length(li)
            fi = fi(2:end);
        else
            li = li(2:end);
        end
        p_x = [fi; li; li; fi];
        p_y = [zeros(size(fi)); zeros(size(fi)); ones(size(li)); ones(size(li))];
    end

    % x_off
    x_offset = size([D.trial{:}],2) - size([D_wavpow.trial{:}],2)*10;
    x_scale = 0.86; % 0.5, 1, 0.4, 0., 0.86, 0.55
    x_offset = x_offset*x_scale;

    % Plot
    sgtitle(elec)
    subplot(2,1,1); 
    plot(y(elec,:))
    yl = get(gca,'ylim');
    patch(10*p_x + x_offset, [yl(1)*ones(size(fi)); yl(1)*ones(size(fi)); yl(2)*ones(size(li)); yl(2)*ones(size(li))],...
        'blue', 'FaceAlpha', 0.1)
    
    subplot(2,1,2);
    plot(rank_y(elec,:));
    yl = get(gca,'ylim');
    patch(10*p_x + x_offset, [yl(1)*ones(size(fi)); yl(1)*ones(size(fi)); yl(2)*ones(size(li)); yl(2)*ones(size(li))],...
        'blue', 'FaceAlpha', 0.05)
    
    pause
    clf
end
%% INDIVIDUAL ELEC PLOTS
elec = 65;

y = [D_wavpow.trial{:}];
x_isnan = isnan(y(elec,:));

% find blocks of nans
% first index of block
 fi = x_isnan(2:end) - x_isnan(1:end-1);
 fi = find(fi==1) + 1;

% last index of block
li = x_isnan(2:end) - x_isnan(1:end-1);
li = find(li==-1);

% patch
try
    p_x = [fi; li; li; fi];
    p_y = [zeros(size(fi)); zeros(size(fi)); ones(size(li)); ones(size(li))];
catch
    if length(fi) > length(li)
        fi = fi(2:end);
    else
        li = li(2:end);
    end
    p_x = [fi; li; li; fi];
    p_y = [zeros(size(fi)); zeros(size(fi)); ones(size(li)); ones(size(li))];
end

% x_off
x_offset = size([D.trial{:}],2) - size([D_wavpow.trial{:}],2)*10;
x_scale = 0.86; % 0.5, 0.975, 0.4, 0., 0.86, 0.55
x_offset = x_offset*x_scale;

% plot
figure; sgtitle([sub ' - ' num2str(elec)])
    % Raw Log
    % sp1 = subplot(3,2,1); title('Raw'); hold on;
    sp1 = subplot(3,1,1); title('Raw'); hold on;
    y = [D.trial{:}];
    plot(y(elec,:))
    % plot(real(log(y(elec,:))))

    yl = get(gca,'ylim');
    patch(10*p_x + x_offset, [yl(1)*ones(size(fi)); yl(1)*ones(size(fi)); yl(2)*ones(size(li)); yl(2)*ones(size(li))],...
        'blue', 'FaceAlpha', 0.1)

    % % Raw Rank
    % sp2 = subplot(3,2,2); title('Raw - rank'); hold on;
    % temp = rank_data(y);
    % plot(temp(elec,:));
    % clearvars temp;
    % 
    % yl = get(gca,'ylim');
    % patch(10*p_x + x_offset, [yl(1)*ones(size(fi)); yl(1)*ones(size(fi)); yl(2)*ones(size(li)); yl(2)*ones(size(li))],...
    %     'blue', 'FaceAlpha', 0.05)

    % Notch Log
    % sp3 = subplot(3,2,3); title('Notch'); hold on;
    sp2 = subplot(3,1,2); title('Notch'); hold on;
    y = [D_sel_filt.trial{:}];
    plot(y(elec,:))
    % plot(real(log(y(elec,:))))

    yl = get(gca,'ylim');
    patch(10*p_x + x_offset, [yl(1)*ones(size(fi)); yl(1)*ones(size(fi)); yl(2)*ones(size(li)); yl(2)*ones(size(li))],...
        'blue', 'FaceAlpha', 0.05)

    % Notch Rank
    % sp4 = subplot(3,2,4); title('Notch - rank'); hold on;
    % temp = rank_data(y);
    % plot(temp(elec,:));
    % clearvars temp;
    % 
    % yl = get(gca,'ylim');
    % patch(10*p_x + x_offset, [yl(1)*ones(size(fi)); yl(1)*ones(size(fi)); yl(2)*ones(size(li)); yl(2)*ones(size(li))],...
    %     'blue', 'FaceAlpha', 0.05)

    % Power 
    % sp5 = subplot(3,2,5); title('Power'); hold on;  
    sp3 = subplot(3,1,3); title('Power'); hold on;  
    y = [D_wavpow.trial{:}];
    plot(y(elec,:))
    % plot(real(log(y(elec,:))))

    yl = get(gca,'ylim');
    patch(p_x, [yl(1)*ones(size(fi)); yl(1)*ones(size(fi)); yl(2)*ones(size(li)); yl(2)*ones(size(li))],...
        'blue', 'FaceAlpha', 0.05);

    % sp6 = subplot(3,2,6); title('Power - rank'); hold on;
    % temp = rank_data(y);
    % plot(temp(elec,:));
    % clearvars temp;
    % 
    % yl = get(gca,'ylim');
    % patch(p_x, [yl(1)*ones(size(fi)); yl(1)*ones(size(fi)); yl(2)*ones(size(li)); yl(2)*ones(size(li))],...
    %     'blue', 'FaceAlpha', 0.05);

%% Power Spectrum
elec = 59;
y = [D.trial{:}]; fs = D.fsample;
% y = [D_sel_filt.trial{:}]; fs = D_sel_filt.fsample;
% y = [D_wavpow.trial{:}]; fs = D_wavpow.fsample

% y = y(:,[1:4*10^5 7*10^5:end]);

[pxx,f] = pwelch(y(elec,size(y,2)/2:end));
figure;
plot(0:0.5*fs/length(pxx):0.5*(fs - fs/length(pxx)), pow2db(pxx))
set(gca,'XTick',0:30:500)
grid on
title([sub ' - ' num2str(elec)])
%%
function y_rank = rank_data(y)

    y_rank = y;
    for i_elec = 1:size(y,1)
        y_rank(i_elec,:) = tiedrank(y(i_elec,:));
        y_rank(i_elec,:) = y_rank(i_elec,:)./abs(max(y_rank(i_elec,:)));
    end

end

%%
n_elecs = size(D_wavpow.trial{1},1);
tr_lengths = cellfun(@(x) size(x,2), D_wavpow.trial);
y = cell(size(D_wavpow.trial));
for i_y = 1:size(y,2); y{i_y} = zeros(142,max(tr_lengths)); end

num_real = zeros(n_elecs, max(tr_lengths));
cum_dat = zeros(n_elecs, max(tr_lengths));
for i_tr = 1:size(D_wavpow.trial,2)
    y{i_tr}(:,1:tr_lengths(i_tr)) = D_wavpow.trial{i_tr};
    y{i_tr}(isnan(y{i_tr})) = 0;
    num_real = num_real + y{i_tr}~=0;
    cum_dat = cum_dat + y{i_tr};
end
avg_dat = cum_dat./num_real;

%%
