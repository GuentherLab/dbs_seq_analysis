% plot all electrodes' trial-averaged timecourses from all subjects, save figure 
%
% resp = electrode response table created by response_types_seq.m

resp_signal = 'hg_ref-CMR'; 
% load(['Y:\DBS\groupanalyses\task-smsl\gotrials\resp_all_subjects_', resp_signal, '.mat'])
% sort_top_tuned_seq(); 
close all
clear op

%% params 
op.n_rows = 6;
op.n_cols = 6; 

%%%%% trial table varname for times used for time-locking responses
op.time_align_var = 't_prod_on'; % speech onset
% op.time_align_var = 't_aud_go_on'; % go beep
% op.time_align_var = 't_vis_syl_on'; % audio stim cue on

% blank some labels or they overlap each other
op.times_to_plot = {...    
    't_vis_syl_on', [0 0 1],        {'vis','on'},       'L';... 
    't_aud_syl_on', [0.6 0.4 0.1],  {'aud','on'},       'L';...
    't_aud_syl_off',[0.6 0.4 0.1],  {'aud','off'},      'L';...
    't_aud_go_on',  [0 1 0],        {'GO'}       'L';...
    't_prod_on',    [0.5 0.5 0.5],  {'sp','on'}, 'L';...
    't_prod_off',   [0.5 0.5 0.5],  {'sp','end'},    'R';...
    };

%%%%%%%%%%% params for plot_response_timecourse_seq
op.smooth_timecourses = 1; 
    % op.smooth_method = 'movmean';
    op.smooth_method = 'gaussian';
    op.smooth_windowsize = 30; 
op.y_timelabel_height = 0.8; % how high up the plot to put the timepoint label text
op.fig_resolution = 300; 


op.savedir = [PATH_RESULTS_FIGS filesep 'timecourses', filesep, resp_signal, '_', op.time_align_var]; 
mkdir(op.savedir)


%% loop to save timecourse figs for each subject 
op.newfig = 0; 
for isub = 1:height(subs)
    op.sub = subs.sub{isub}
    close all
    plot_all_elcs_within_subject(resp, subs, op); 
end





    %% subfunction for plotting all electrodes within a subject
function [hfig] = plot_all_elcs_within_subject(resp, subs, op)
    op.n_elcs_per_fig = op.n_rows * op.n_cols; 
    
    %%
    
    resp_sub = resp(resp.sub == string(op.sub), :);
    trials_tmp = subs.trials{subs.sub == string(op.sub)}; 
    
    n_elcs = height(resp_sub);
    ifig = 0; 
    for i_elc = 1:n_elcs
        if mod(i_elc, op.n_elcs_per_fig) == 1
            ifig = ifig+1; 
            hfig(ifig) = figure('Color','w', 'WindowState', 'maximized'); box off
        end
    
        subplot(op.n_rows, op.n_cols, i_elc - [ifig-1]*op.n_elcs_per_fig)
        plot_resp_timecourse_seq(resp_sub(i_elc,:),trials_tmp,op) % in ieeg_ft_funcs_am repo 
    
    end
    
    nfigs = length(hfig);
    for ifig = 1:nfigs
        savename = [op.savedir, filesep, 'sub-',op.sub, '_elcs_timecourses_', num2str(ifig), '.png'];
        exportgraphics(hfig(ifig), savename, 'Resolution', op.fig_resolution)
    end

end

