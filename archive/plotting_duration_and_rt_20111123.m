% plot utterance durations and reaction times between stim conditions for individual subjects
ylimits_dur = [0.2 1.2]; 
ylimits_rt = [0.2 1.3];


%% 1005
include_error_trials_1005 = 1; 


if include_error_trials_1005
    erstring_1005 = '(including sequencing errors)'; 
else 
    erstring_1005 = '(no sequencing errors)'; 
end

%% ut duration
load('Y:\DBS\derivatives\sub-DM1005\analysis\task-smsl_trial-audio\sub-DM1005_ses-intraop_go-trial-durations.mat')
% close all
if include_error_trials_1005
    tr = trials(~isnan(trials.seq_accuracy),:); 
else 
     tr = trials(trials.seq_accuracy==1,:); 
end
    
[p,tbl,stats] = anova1(tr.ut_duration,tr.stim_condition);
ylabel('utterance duration (sec)')
set(gca,'XTickLabel',{'learned','novel','native'})
title(['sub-1005 intraop, ' erstring_1005])
ylim(ylimits_dur)
annotation('textbox',[0.4 0.1 .1 .1],'String',['anova p = ',num2str(p)],'FitBoxToText','on')

[~, p_novel_vs_learned] = ttest2(tr.ut_duration(tr.stim_condition==1), tr.ut_duration(tr.stim_condition==2))
[~, p_learned_vs_native] = ttest2(tr.ut_duration(tr.stim_condition==1), tr.ut_duration(tr.stim_condition==3))
[~, p_novel_vs_native] = ttest2(tr.ut_duration(tr.stim_condition==2), tr.ut_duration(tr.stim_condition==3))

%% RT
load('Y:\DBS\derivatives\sub-DM1005\analysis\task-smsl_trial-audio\sub-DM1005_ses-intraop_go-trial-durations.mat')
% close all
if include_error_trials_1005
    tr = trials(~isnan(trials.seq_accuracy),:); 
else 
     tr = trials(trials.seq_accuracy==1,:); 
end

[p,tbl,stats] = anova1(tr.ontime_post_beep_onset,tr.stim_condition);
ylabel('reaction time (sec)')
set(gca,'XTickLabel',{'learned','novel','native'})
title(['sub-1005 intraop, ' erstring_1005])
ylim(ylimits_rt)

[~, p_novel_vs_learned] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==1), tr.ontime_post_beep_onset(tr.stim_condition==2))
[~, p_learned_vs_native] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==1), tr.ontime_post_beep_onset(tr.stim_condition==3))
[~, p_novel_vs_native] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==2), tr.ontime_post_beep_onset(tr.stim_condition==3))


%% 1008
include_error_trials_1008 = 1; 


if include_error_trials_1008
    erstring_1008 = '(including sequencing errors)'; 
else 
    erstring_1008 = '(no sequencing errors)'; 
end

%% ut duration
load('Y:\DBS\derivatives\sub-DM1008\analysis\task-smsl_trial-audio\sub-DM1008_ses-intraop_go-trial-durations.mat')
close all
if include_error_trials_1008
    tr = trials(~isnan(trials.seq_accuracy),:); 
else 
     tr = trials(trials.seq_accuracy==1,:); 
end
    
[p,tbl,stats] = anova1(tr.ut_duration,tr.stim_condition);
ylabel('utterance duration (sec)')
set(gca,'XTickLabel',{'learned','novel','native'})
title(['sub-1008 intraop, ' erstring_1008])
ylim(ylimits_dur)
annotation('textbox',[0.4 0.1 .1 .1],'String',['anova p = ',num2str(p)],'FitBoxToText','on')

[~, p_novel_vs_learned] = ttest2(tr.ut_duration(tr.stim_condition==1), tr.ut_duration(tr.stim_condition==2))
[~, p_learned_vs_native] = ttest2(tr.ut_duration(tr.stim_condition==1), tr.ut_duration(tr.stim_condition==3))
[~, p_novel_vs_native] = ttest2(tr.ut_duration(tr.stim_condition==2), tr.ut_duration(tr.stim_condition==3))

%% RT
load('Y:\DBS\derivatives\sub-DM1008\analysis\task-smsl_trial-audio\sub-DM1008_ses-intraop_go-trial-durations.mat')
% close all
if include_error_trials_1008
    tr = trials(~isnan(trials.seq_accuracy),:); 
else 
     tr = trials(trials.seq_accuracy==1,:); 
end

[p,tbl,stats] = anova1(tr.ontime_post_beep_onset,tr.stim_condition);
ylabel('reaction time (sec)')
set(gca,'XTickLabel',{'learned','novel','native'})
title(['sub-1008 intraop, ' erstring_1008])
ylim(ylimits_rt)

[~, p_novel_vs_learned] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==1), tr.ontime_post_beep_onset(tr.stim_condition==2))
[~, p_learned_vs_native] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==1), tr.ontime_post_beep_onset(tr.stim_condition==3))
[~, p_novel_vs_native] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==2), tr.ontime_post_beep_onset(tr.stim_condition==3))








%% 1007

%% ut duration
load('Y:\DBS\derivatives\sub-DM1007\analysis\task-smsl_trial-audio\sub-DM1007_ses-intraop_go-trial-durations.mat')
% close all
[p,tbl,stats] = anova1(trials.ut_duration(trials.difficult_to_score==0),trials.stim_condition(trials.difficult_to_score==0));
ylabel('utterance duration (sec)')
set(gca,'XTickLabel',{'learned','novel','native'})
title('sub-1007 intraop (including sequencing errors)')
ylim(ylimits_dur)

%% RT
load('Y:\DBS\derivatives\sub-DM1007\analysis\task-smsl_trial-audio\sub-DM1007_ses-intraop_go-trial-durations.mat')
% close all
[p,tbl,stats] = anova1(trials.ontime_post_beep_onset(trials.difficult_to_score==0),trials.stim_condition(trials.difficult_to_score==0));
ylabel('reaction time (sec)')
set(gca,'XTickLabel',{'learned','novel','native'})
title('sub-1007 intraop (including sequencing errors)')
annotation('textbox',[0.4 0.1 .1 .1],'String',['anova p = ',num2str(p)],'FitBoxToText','on')
ylim(ylimits_rt)
tr = trials(trials.difficult_to_score==0,:); 
[~, p_novel_vs_learned] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==1), tr.ontime_post_beep_onset(tr.stim_condition==2))
[~, p_learned_vs_native] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==1), tr.ontime_post_beep_onset(tr.stim_condition==3))
[~, p_novel_vs_native] = ttest2(tr.ontime_post_beep_onset(tr.stim_condition==2), tr.ontime_post_beep_onset(tr.stim_condition==3))



