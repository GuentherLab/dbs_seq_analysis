 %%%% find and plot the electrodes which are best tuned for a given parameter
 .... might need to run plot_top_electrodes_mni_on_ctx.m first



% op.param = 'p_min_stim_prep_prod'; % general task responsivity
% op.param = 'p_stim';
% op.param = 'p_prep';
% op.param = 'p_prod';


% op.param = 'p_prep_learn';
% op.param = 'p_prod_learn';

% op.param = 'p_prep_nn_v_nat';
% op.param = 'p_prod_nn_v_nat';

% op.param = 'p_prep_novel_vs_trained';
% op.param = 'p_prod_novel_vs_trained';

% op.param = 'p_stim_novel_vs_nat';
% op.param = 'p_prep_novel_vs_nat';
% op.param = 'p_prod_novel_vs_nat';

% op.param = 'p_stim_syl';
% op.param = 'p_prep_syl';
% op.param = 'p_prod_syl';

% op.param = 'p_stim_rime';
% op.param = 'p_prep_rime';
% op.param = 'p_prod_rime';

% op.param = {'p_stim_cons',1};
% op.param = {'p_prep_cons',1};
op.param = {'p_prod_cons',1};

% op.param = {'p_stim_cons',2};
% op.param = {'p_prep_cons',2};
% op.param = {'p_prod_cons',2};

% op.param = {'p_stim_cons',3};
% op.param = {'p_prep_cons',3};
% op.param = {'p_prod_cons',3};

% op.param = 'p_stim_vow';
% op.param = 'p_prep_vow';
% op.param = 'p_prod_vow';

exclude_if_p_zero = 1; % delete channels if they have p=0 for the key parameter

%%
% load([PATH_RESULTS, filesep, 'resp_all_subjects.mat'])


if iscell(op.param) % if we need to select only 1 column from the table variable
    resp.paramvals = resp{:,op.param{1}}(:,op.param{2});
    field_default('op','full_param_string',[op.param{1}, '_', num2str(op.param{2})]); % display name of the param - default to its name in resp table with index number
    [srtvals, idxorder] = sort(resp{:,op.param{1}}(:,op.param{2}));
    op.param_base = op.param{1}; 
else
    resp.paramvals = resp{:,op.param};
    field_default('op','full_param_string',op.param); % display name of the param - default to its name in resp table
    [srtvals, idxorder] = sort(resp{:,op.param});
    op.param_base = op.param; 
end




srt = resp(idxorder,:); 
srt = movevars(srt,{'sub','chan',op.param_base,'HCPMMP1_label_1','DISTAL_label_1'},'Before',1);

if exclude_if_p_zero
    pzero_rows = srtvals == 0; 
    srt = srt(~pzero_rows,:);    
    idxorder = idxorder(~pzero_rows,:);  
        % clear srtvals idxorder
end

% srt = srt(string(srt.type) ~= "ECOG",:); % exclude ecog electrodes
% srt = srt(string(srt.sub) ~= 'DM1037',:); % exclude specific subject