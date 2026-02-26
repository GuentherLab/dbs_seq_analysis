 %%%% plot learning percent vs. percent of tuned electrodes to novel vs native

%  group_acc(); % load subject table with learned minus novel performance
% load('Y:\DBS\groupanalyses\task-smsl\gotrials\resp_all_subjects_hg_ref-CMR.mat'); % load elc tuning


nsubs = height(subs); % table for subs we have elc tuning for

for isub = 1:nsubs
    thissub = subs.subject{isub};
    matchrow = strcmp(thissub,subs_beh.sub); 
    subs.learned_min_novel(isub) = subs_beh.learned_min_novel(matchrow);
    subs.nat_min_nn(isub) = subs_beh.nat_min_nn(matchrow);

    elcs_this_sub = resp(strcmp(thissub, resp.sub),:);
    subs.n_rspv(isub) = nnz(elcs_this_sub.rspv);
    subs.n_prep_novel_vs_trained(isub) = nnz(elcs_this_sub.rspv & elcs_this_sub.p_prep_novel_vs_trained < 0.05);
    subs.n_prep_nn_v_nat(isub) = nnz(elcs_this_sub.rspv & elcs_this_sub.p_prep_nn_v_nat < 0.05);
end

subs.prop_prop_novel_vs_trained = subs.n_prep_novel_vs_trained ./ subs.n_rspv;
subs.prop_prop_nn_v_nat = subs.n_prep_nn_v_nat ./ subs.n_rspv;

figure('Color','w'); scatter(  subs.prop_prop_novel_vs_trained,  subs.learned_min_novel)
xlabel('proportion rspv. electrodes tuned for trained vs. novel (prep, HG)')
ylabel('trained minus novel accuracy')
ylim([-0.15, 0.4])
xlim([-0.01, 0.1])
[h, p] = corrcoef(subs.prop_prop_novel_vs_trained,  subs.learned_min_novel)