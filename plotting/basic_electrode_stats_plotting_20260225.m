%%%% plot basic electrode, behavior, demogr stats for each subject


%  group_acc(); % load subject table with learned minus novel performance
% load('Y:\DBS\groupanalyses\task-smsl\gotrials\resp_all_subjects_hg_ref-CMR.mat'); % load elc tuning


nsubs = height(subs); % table for subs we have elc tuning for

for isub = 1:nsubs
    thissub = subs.sub{isub};
    matchrow = strcmp(thissub,subs_beh.sub); 
    subs.learned_min_novel(isub) = subs_beh.learned_min_novel(matchrow);
    subs.nat_min_nn(isub) = subs_beh.nat_min_nn(matchrow);
    subs.acc_mean(isub) = subs_beh.acc_mean(matchrow); 

    elcs_this_sub = resp(strcmp(thissub, resp.sub),:);
    subs.n_elc(isub) = height(elcs_this_sub); 
    subs.n_rspv(isub) = nnz(elcs_this_sub.rspv);
    subs.n_prep_novel_vs_trained(isub) = nnz(elcs_this_sub.rspv & elcs_this_sub.p_prep_novel_vs_trained < 0.05);
    subs.n_prep_nn_v_nat(isub) = nnz(elcs_this_sub.rspv & elcs_this_sub.p_prep_nn_v_nat < 0.05);
end

subs.prop_rspv = subs.n_rspv ./ subs.n_elc; 
subs.prop_prop_novel_vs_trained = subs.n_prep_novel_vs_trained ./ subs.n_rspv;
subs.prop_prop_nn_v_nat = subs.n_prep_nn_v_nat ./ subs.n_rspv;


%% responsive electrodes per subject
close all

hfig = figure('Color','w'); box off
hbar = bar(subs.prop_rspv);
hax = gca;
hax.XTickLabel = subs.sub; 
ylabel('proportion of responsive electrodes')

%% 
hfig = figure('Color','w'); scatter( subs.prop_rspv ,  subs.learned_min_novel, 'filled','o','MarkerFaceColor','k')
[r, p_prop_rsvp_vs_learned_minus_novel] = corrcoef(subs.prop_rspv,  subs.learned_min_novel);
xlabel('proportion of task-responsive electrodes (HG)')
ylabel('trained minus novel accuracy')
h_anno = annotation(hfig, 'textbox','Position',[0.2 0.8 0.1 0.1], 'String',['p=',sprintf('%.3f\n',p_prop_rsvp_vs_learned_minus_novel(2,1))])

%%
hfig = figure('Color','w'); scatter( subs.prop_rspv ,  subs.acc_mean, 'filled','o','MarkerFaceColor','k')
[r, p_prop_rsvp_vs_mean_acc] = corrcoef(subs.prop_rspv,  subs.acc_mean);
xlabel('proportion of task-responsive electrodes (HG)')
ylabel('mean accuracy')
h_anno = annotation(hfig, 'textbox','Position',[0.15 0.8 0.1 0.1], 'String',['p=',sprintf('%.3f\n',p_prop_rsvp_vs_mean_acc(2,1))])