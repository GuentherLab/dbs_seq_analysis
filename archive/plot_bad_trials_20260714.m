 %%% plot sample timecourses to look at whether automated artifact removal marked them as artifactual


% load([PATH_RESULTS, filesep, 'resp_all_subjects_hg_ref-CMR.mat'])

% sort_top_tuned_seq(); 

sub = 'DM1024'; 
chan = 'ecog_L225';

elcresp = resp(find(strcmp(resp.sub,sub) & ismember(resp.chan, {chan})),:); 
trialnums = 110:113; 




figure; 
for i = 1:length(trialnums)
    plot(elcresp.timecourse{1}{trialnums(i)}') % not aligned, but shouldn't matter for seeing artifacts
    hold on
end

hold off
ylabel('hg normed'); 
xlabel('time (sec post trial start)')
legend(string(trialnums))

title([sub, ' ', chan, ' trials'])