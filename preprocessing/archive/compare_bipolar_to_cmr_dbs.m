% compare_bipolar_to_cmr_dbs - compare sample dbs chans beta power traces when using different methods

clear; close all

op.plotinds = [127, 128];

op.xlimits = [63384 63390];
% op.xlimits = [];


sub = 'DM1005';

hfig = figure;

%% old CMR reref
D_ref_cmr = load('Y:\DBS\derivatives\sub-DM1005\fieldtrip\sub-DM1005_ses-intraop_task-smsl_ft-raw-filt_ar-G_ref-CMR.mat'); 

%%
subplot(2,1,1)
plot_traces(D_ref_cmr,op)
title(['sub ', sub, '.... cmr reref'])

%% bipolar reref
D_ref_bip = load('Y:\DBS\derivatives\sub-DM1005\fieldtrip\sub-DM1005_ses-intraop_task-smsl_ft-raw-filt_ar-G_ref.mat'); 

%%
subplot(2,1,2)
plot_traces(D_ref_bip,op)
title(['sub ', sub, '.... bipolar reref'])

%%
function plot_traces(D_in,op)
    dref = D_in.D_ref; 
    plot(dref.time{1}, dref.trial{1}(op.plotinds, :))
    ylabel('reref trace')
    xlabel('time (sec)')
    
    if ~isempty(op.xlimits)
        xlim(op.xlimits)
    end

    legend(dref.label{op.plotinds})

end

