


% param = 'p_min_stim_prep_prod'; % general task responsivity
% param = 'p_stim';
% param = 'p_prep';
% param = 'p_prod';

% param = 'p_prep_learn';
% param = 'p_prod_learn';

param = 'p_prod_nn_v_nat';
% param = 'p_prep_nn_v_nat';

% param = 'p_prep_novel_vs_trained';
% param = 'p_prod_novel_vs_trained';

% param = 'p_prep_novel_vs_nat';
% param = 'p_prod_novel_vs_nat';

% param = 'p_stim_syl';
% param = 'p_prep_syl';
% param = 'p_prod_syl';

% param = 'p_stim_rime';
% param = 'p_prep_rime';
% param = 'p_prod_rime';


regiondef = {   'SMC',  {'1','2','3a','3b','4','6v','6d','43','55b','PEF','FEF','OP4','i6-8'};... % sensorimotor cortex... included operculum bc ecog strips can't get into operc
                'vPMC', {'6r','FOP1'};... % ventral premotor... there are some elcs put into 'SMC' areas that are actually in vPMC... included operculum bc ecog strips can't get into operc
                'MFG',  {'8Av','8C','p9-46v'};... middle frontal gyrus... maybe also inf front sulcus
                'IFG-IFS',  {'44','45','IFSp'};... % inferior frontal gyrus
                'SMG/PF', {'PF','PFop'};... % supramarginal gyrus, operculum, ventral postcentral sulcus
                'AG', {'PSL'};... % angular gyrus
                'STG', {'A4','A5','STGa','STV','TPOJ1' }; ... % superior temporal gyrus
                'MTG', {'TE1a','TE1m','TE1p'};... middle temporal gyrus / TE
                'STN', {'STN_associative_L','STN_motor_L','STN_motor_R' };...
                'Thal', {'087_Thalamus_ventro_oralis_anterior_Voa_L','088_Thalamus_ventro_oralis_posterior_Vop_L','088_Thalamus_ventro_oralis_posterior_Vop_R',...
                           '090_Thalamus_zentrolateralis_oralis_Zo_L','091_Thalamus_ventro_intermedius_internus_Vimi_R',...
                           '094_Thalamus_ventro_intermedius_externus_Vime_L','094_Thalamus_ventro_intermedius_externus_Vime_R' };...
                'GP', {'GPe_L','GPe_R','GPi_postparietal_R','GPi_premotor_R','GPi_sensorimotor_L','GPi_sensorimotor_L'};... % 
                };

alpha = 0.05; 

analyze_responsive_elcs_only = 1;

region_selected = 'IFG-IFS'; 

show_barplot = 0; 

paramvals = resp{:,param};
param_name = param; 
full_param_string = param; 
compare_areal_tuning()

%%
resp_slct = resp_temp(strcmp(resp_temp.region, region_selected),:);

means_to_plot = [mean(resp_slct.sign_prep_nn_minus_nat), mean(resp_slct.sign_prod_nn_minus_nat)]; 
erbar = [std(resp_slct.sign_prep_nn_minus_nat), std(resp_slct.sign_prod_nn_minus_nat)] ./ sqrt(height(resp_slct)); 

hfig = figure('Color','w'); box off
hbar = bar(means_to_plot); 
hold on
hax = gca; 
hax.XTickLabel = {'prep';'prod'};
h_ebar = errorbar(means_to_plot, erbar); 
    h_ebar.LineWidth = 0.8;
    h_ebar.LineStyle = 'none';
    h_ebar.Color = [0 0 0];

ylabel({'mean sign of HG response', '(nonnative vs. native)'})




