 % AM

 clear
 close all
 
sublist = {'DM1005' ,'DM1007', 'DM1008'}; 


nsubs = length(sublist);

res1005 = load(...
    'Y:\DBS\derivatives\sub-DM1005\analysis\task-smsl_trial-audio\sub-DM1005_ses-intraop_task-smsl_go-trials-analysis');
res1007 = load(...
    'Y:\DBS\derivatives\sub-DM1007\analysis\task-smsl_trial-audio\sub-DM1007_ses-intraop_task-smsl_go-trials-analysis');
res1008 = load(...
    'Y:\DBS\derivatives\sub-DM1008\analysis\task-smsl_trial-audio\sub-DM1008_ses-intraop_task-smsl_go-trials-analysis');


correct_prop_novel_unambiguous = [res1005.correct_prop_novel; res1007.correct_prop_novel_unambiguous; res1008.correct_prop_novel_unambiguous];
correct_prop_learned_unambiguous = [res1005.correct_prop_learned; res1007.correct_prop_learned_unambiguous; res1008.correct_prop_learned_unambiguous];
correct_prop_native_unambiguous = [res1005.correct_prop_native; res1007.correct_prop_native_unambiguous; res1008.correct_prop_native_unambiguous];

    ylab = 'Proportion sequencing accuracy'; 
% % % %     xticklab = {['nonnative novel, n=' num2str(ntrials_novel_unambiguous)],...
% % % %         ['nonnative learned, n=' num2str(ntrials_learned_unambiguous)],...
% % % %         ['native, n=' num2str(ntrials_native_unambiguous)]}; 
    xticklab = {['nonnative novel'],...
        ['nonnative learned'],...
        ['native']}; 
    
%% 1005
    figure 
    yvals = [res1005.correct_prop_novel, res1005.correct_prop_learned, res1005.correct_prop_native];
    bar(yvals)
    ylabel(ylab)
    set(gca,'XTickLabel', xticklab)
    title(['Manual Trial Scoring'])
    ylim([0 1])
    
    %% 1007
    figure 
    yvals = [res1007.correct_prop_novel_unambiguous, res1007.correct_prop_learned_unambiguous, res1007.correct_prop_native_unambiguous];
    bar(yvals)
    ylabel(ylab)
    set(gca,'XTickLabel', xticklab)
    title(['Manual Trial Scoring'])
    ylim([0 1])
    
        %% 1008
    figure 
    yvals = [res1008.correct_prop_novel_unambiguous, res1008.correct_prop_learned_unambiguous, res1008.correct_prop_native_unambiguous];
    bar(yvals)
    ylabel(ylab)
    set(gca,'XTickLabel', xticklab)
    title(['Manual Trial Scoring'])
    ylim([0 1])

%% all subjects
    figure 
    yvals = [mean(correct_prop_novel_unambiguous), mean(correct_prop_learned_unambiguous), mean(correct_prop_native_unambiguous)];
    ervals = [std(correct_prop_novel_unambiguous)/sqrt(nsubs),...
        std(correct_prop_learned_unambiguous)/sqrt(nsubs), std(correct_prop_native_unambiguous)/sqrt(nsubs)];
    bar(yvals)
    hold on
    errorbar(yvals, ervals,'.k')
    hold off
    ylabel(ylab)
    set(gca,'XTickLabel', xticklab)
    title(['Manual Trial Scoring'])
    ylim([0 1])