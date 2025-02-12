 %%%% find and plot the electrodes which are best tuned for a given parameter
 .... might need to run plot_top_electrodes_mni_on_ctx.m first



% param = 'p_min_stim_prep_prod'; % general task responsivity
% param = 'p_stim';
% param = 'p_prep';
% param = 'p_prod';

% param = 'p_prep_learn';
% param = 'p_prod_learn';

% param = 'p_prod_nn_v_nat';
% param = 'p_prep_nn_v_nat';

param = 'p_prep_novel_vs_trained';
% param = 'p_prod_novel_vs_trained';

% param = 'p_prep_novel_vs_nat';
% param = 'p_prod_novel_vs_nat';

% param = 'p_stim_syl';
% param = 'p_prep_syl';
% param = 'p_prod_syl';

% param = 'p_stim_rime';
% param = 'p_prep_rime';
% param = 'p_prod_rime';

exclude_if_p_zero = 1; % delete channels if they have p=0 for the key parameter

%%
% load([PATH_RESULTS, filesep, 'resp_all_subjects.mat'])

[srtvals, idxorder] = sort(resp{:,param});

srt = resp(idxorder,:); 
srt = movevars(srt,{'sub','chan',param,'HCPMMP1_label_1','DISTAL_label_1'},'Before',1);

if exclude_if_p_zero
    pzero_rows = srtvals == 0; 
    srt = srt(~pzero_rows,:);    
    idxorder = idxorder(~pzero_rows,:);  
        % clear srtvals idxorder
end

% srt = srt(string(srt.type) ~= "ECOG",:); % exclude ecog electrodes