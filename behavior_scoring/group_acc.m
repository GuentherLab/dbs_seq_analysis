%%%% plot/analyze accuracy from all subjects

clear

setpaths_dbs_seq()

subs_beh = readtable(PATH_SUB_MASTER_TABLE,'FileType','text','Delimiter','tab'); subs_beh = subs_beh(subs_beh.analyze==1,:); 
nsubs = height(subs_beh);
ses = 'intraop'; 
task = 'smsl'; 
plot_cond_labels = {'nonnative_novel','nonnative_learned','native'}; 

for isub = 1:nsubs
    thissub = subs_beh.sub{isub}; 
    PATH_DER_SUB = [PATH_DER filesep 'sub-',thissub]; 
    PATH_TRIAL_AUDIO = [PATH_DER_SUB, filesep 'analysis' filesep 'task-',task,'_trial-audio']; 

    % load go trial acc for this sub; add to subtable   
    sub_acc_file = [PATH_TRIAL_AUDIO filesep 'sub-',thissub, '_ses-',ses, '_task-',task, '_go-trials-analysis.mat'];
    subdat = load(sub_acc_file);
    subs_beh.trial{isub} = {subdat.trials}; % add this sub's trials to table
    subs_beh.acc_native(isub) = subdat.correct_prop_native; 
    subs_beh.acc_learned(isub) = subdat.correct_prop_learned; 
    subs_beh.acc_novel(isub) = subdat.correct_prop_novel; 

end

subs_beh.acc_mean = mean([subs_beh.acc_native, subs_beh.acc_learned, subs_beh.acc_novel], 2); % avg across conditions, rather than across trials
subs_beh.acc_nonnative = mean([subs_beh.acc_learned, subs_beh.acc_novel],2); 

% compute subject-level stats which will be helpful to reference for other purposes
subs_beh.learned_min_novel = subs_beh.acc_learned - subs_beh.acc_novel;
subs_beh.nat_min_nn = subs_beh.acc_native - subs_beh.acc_nonnative; 
subs_beh = movevars(subs_beh,{'sub','learned_min_novel','nat_min_nn','diagnosis','ecog_target'}, 'Before',1); 
subs_beh_srt = sortrows(subs_beh,'learned_min_novel','descend'); % organize by best learning performance

acc_by_cond = [subs_beh.acc_novel, subs_beh.acc_learned, subs_beh.acc_native]; 
acc_by_cond_normed = acc_by_cond - repmat(acc_by_cond(:,2),1,3); 

%% plotting
close all

hfig = figure; hfig.Color = [1 1 1];
subplot(1,2,1)
hplot = plot(acc_by_cond'); box off
ylabel('Sequencing accuracy')
hax = gca;
hax.XTick = [1 2 3]; hax.XTickLabels = plot_cond_labels; 
xlim([0.5 3.5])
%
subplot(1,2,2)
hplot = plot(acc_by_cond_normed'); box off
ylabel('Sequencing accuracy (normeed)')
hax = gca;
hax.XTick = [1 2 3]; hax.XTickLabels = plot_cond_labels; 
xlim([0.5 3.5])
hxline = xline(0);


%% stats tests

[~, p_nn_vs_nat] = ttest(subs_beh.acc_nonnative, subs_beh.acc_native)
[~, p_novel_vs_learned] = ttest(subs_beh.acc_novel, subs_beh.acc_learned)

within = table([1 2 3]', 'VariableNames', {'learncon'});
rm = fitrm(subs_beh, 'acc_novel,acc_learned,acc_native ~ 1', 'WithinDesign', within);
ranovatbl = ranova(rm, 'WithinModel', 'learncon')

save(['Y:\DBS\groupanalyses\task-smsl\group_acc_20250728\group_acc_20250728'])
savefig(['Y:\DBS\groupanalyses\task-smsl\group_acc_20250728\group_acc_20250728.fig'])
