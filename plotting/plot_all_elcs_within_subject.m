% plot all electrodes from a subject 
%
% resp = electrode response table created by response_types_seq.m

function [hfig] = plot_all_elcs_within_subject(resp, op)

vardefault('op',struct')
field_default('op','sub','DM1049'); 
field_default('op','n_rows',7);
field_default('op','n_cols',7);

op.n_elcs_per_fig = op.n_rows * op.n_cols; 

%%

resp_sub = resp(resp.sub == string(op.sub), :);

n_elcs = height(resp_sub);
ifig = 1; 
for i_elc = 1:n_elcs
    if mod(i_elc, op.n_elcs_per_fig) == 1
        hfig(ifig) = figure('color','w'); box off
        ifig = ifig+1; 
    end

    subplot(op.n_rows, op.n_cols, i_elc - [ifig-1]*op.n_els_per_fig)
    
