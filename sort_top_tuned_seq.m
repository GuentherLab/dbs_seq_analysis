 %%%% find and plot the electrodes which are best tuned for a given parameter
 .... might need to run plot_top_electrodes_mni_on_ctx.m first




% param = 'p_prep';
% param = 'p_prod';
% param = 'p_learn';
% param = 'p_learn_prep';
% param = 'p_nat_v_nn';
% param = 'p_nat_v_nn_prep';
% param = 'p_stim_id';
% param = '';
% param = '';

exclude_if_p_zero = 1; % delete channels if they have p=0 for the key parameter

%%
%  load('resp_all_subjects.mat'); 

[srtvals, varname] = triplet_tablevar(resp, param);
[srtvals, idxorder] = sort(srtvals);

srt = resp(idxorder,:); 
srt = movevars(srt,{varname},'After','MOREL_label_1');

if exclude_if_p_zero
    pzero_rows = srtvals == 0; 
    srt = srt(~pzero_rows,:);    
        clear srtvals idxorder
end