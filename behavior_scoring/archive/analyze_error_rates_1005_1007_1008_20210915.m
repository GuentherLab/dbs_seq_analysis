 % AM

 %%% look for whether certain clusters were especially difficult or easy for each subject
 % do not just average accuracy rates across subjects; this would be heavily biased by the different accuracy rates...
 % ... of the subjects and which words were learned/novel for each subjects
 
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

res1005.learned = unique(res1005.trials.word(res1005.trials.stim_condition==1));
res1007.learned = unique(res1007.trials_unambiguous.word(res1007.trials_unambiguous.stim_condition==1));
res1008.learned = unique(res1008.trials_unambiguous.word(res1008.trials_unambiguous.stim_condition==1));

varstokeep = {'sub','word','run_id','stim_condition','word_accuracy','seq_accuracy','onset_error','comments'}; 
tr1005 = res1005.trials; 
    tr1005.sub = repmat(1005, height(tr1005), 1); 
    tr1005.onset_error = tr1005.onset_error_type; 
tr1007 = res1007.trials; 
    tr1007.sub = repmat(1007, height(tr1007), 1);
    tr1007.seq_accuracy(tr1007.difficult_to_score==1) = 0.5; % half point for ambiguous trials
tr1008 = res1008.trials; 
    tr1008.sub = repmat(1008, height(tr1008), 1);
    tr1008.seq_accuracy(tr1008.difficult_to_score==1) = 0.5; % half point for ambiguous trials
    
alltr = [tr1005(:,varstokeep); tr1007(:,varstokeep); tr1008(:,varstokeep)]; % concatenate subjects
trnn = alltr(alltr.stim_condition == 1 | alltr.stim_condition == 2, :); % only nonnative trials
trlearned = alltr(alltr.stim_condition == 1, :);
trnovel = alltr(alltr.stim_condition == 2, :);
subnums = unique(alltr.sub); 
words = unique(trnn.word);
nwords = length(words); 
nanvar = NaN(nwords, nsubs); 
% following table will contain the accuracy rates for each word, for each subject, divided by stim condition
acc = table(words, nanvar, nanvar, nanvar, nanvar, 'VariableNames',...
    {'word', 'acc_learned', 'acc_learned_norm', 'acc_novel', 'acc_novel_norm'});
for iword = 1:nwords
   thisword = words{iword}; 
    for isub = 1:nsubs
       thissub = subnums(isub);
       
       % norm = accuracy of this word minus mean acc for this subject (or all subjects)
       learned_mean_thissub = nanmean(trlearned.seq_accuracy(trlearned.sub==thissub));
       learnedrows = strcmp(trlearned.word, thisword) & trlearned.sub==thissub; 
       acc.acc_learned(iword, isub) = nanmean(trlearned.seq_accuracy(learnedrows)); 
       acc.acc_learned_norm(iword, isub) = acc.acc_learned(iword, isub) - learned_mean_thissub; 
       
       novel_mean_thissub = nanmean(trnovel.seq_accuracy(trnovel.sub==thissub));
       novelrows = strcmp(trnovel.word, thisword) & trnovel.sub==thissub; 
       acc.acc_novel(iword, isub) = nanmean(trnovel.seq_accuracy(novelrows)); 
       acc.acc_novel_norm(iword, isub) = acc.acc_novel(iword, isub) - novel_mean_thissub; 

       
    end
end

acc.acc_learned_mean = nanmean(acc.acc_learned,2);
acc.acc_learned_mean_norm = acc.acc_learned_mean - nanmean(acc.acc_learned_mean);
acc.acc_novel_mean = nanmean(acc.acc_novel,2);
acc.acc_novel_mean_norm = acc.acc_novel_mean - nanmean(acc.acc_novel_mean);
acc = movevars(acc,{'acc_learned_norm','acc_learned_mean','acc_learned_mean_norm'} ,'After','acc_learned');

% check whether the error rate goes down during the session; subjects might start learning the novel words
windowsize = 8; % window size in trials
figure
for isub = 1:nsubs
    thissub = subnums(isub);
    plot(movmean(trnovel.seq_accuracy(trnovel.sub==thissub), windowsize))
    hold on
    ylabel('seq accuracy')
    xlabel(['trial (moving window size = ', num2str(windowsize), ')'])
    title('intraop, novel words')
    legend(sublist')
end
hold off

% learned words
figure
for isub = 1:nsubs
    thissub = subnums(isub);
    plot(movmean(trlearned.seq_accuracy(trlearned.sub==thissub), windowsize))
    hold on
    ylabel('seq accuracy')
    xlabel(['trial (moving window size = ', num2str(windowsize), ')'])
    title('intraop, learned words')
    legend(sublist')
end
hold off