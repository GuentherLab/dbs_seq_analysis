 %%%% check whether there is a nonrandom distribution of significantly tuned electrodes across areas
  %%% load resp_all_subjects first
setpaths_dbs_seq()

% load([PATH_RESULTS, filesep, 'resp_all_subjects.mat'])

% close all

 %% params
vardefault('show_barplot',1);

newfig = 1; 

%%% define anatomical regions composed of smaller areas
% 1 = 'Area 1' (Fischl et al 2008, Geyer et al 1999, Geyer et al 2000) ... posterior postcentral gyrus
% 2 = 'Area 2' ... postcentral sulcus
% 3a = 'Area 3a'.... central sulcus
% 3b = 'Primary Sensory Cortex'.... postcentral gyrus
% 4 = 'Primary Motor Cortex'.... anterior central sulcus
% 6v = 'Ventral Area 6' (Fischl et al 2008, Amunts et al 2010, Geyer 2004).... precentral gyrus, precentral sulcus
%
% 6d = 'Dorsal Area 6' (Fischl et al 2008, Geyer 2004, Geyer et al 2000).... dorsal precentral gyrus (hand knob?)
% 
% 6r = 'Rostral Area 6' (Amunts et al 2010)... ventral premotor, precentral sulcus
%
% FEF = Frontal Eye Fields... in first 5 dbsseq subs, this is close to precentral gyrus, but may be more frontal in future subs
% PEF = Premotor Eye Fields
%
% OP4 = 'Area OP4/PV' .... ventral precentral/postecentral gyrus, operculum
%
% 55b = 'Area 55b' (Hopf 1956)... mid precentral gyrus, precentral sulcus, posterior MFG... premotor cortex
% 
% 43 = 'Area 43' (Brodmann 1909, Brodmann 2007, Nieuwenhuys et al 2014)... operculum and ventral precentral gyrus
%
% i6-8 = 'Inferior 6-8 Transitional Area'(von Economo and Koskinas 1925, Triarhou 2007)... dorsal premotor
%
% 8Av = 'Area 8av' (Petredes and Pandya 1999) .... middle frontal gyrus
% 8C = 'Area 8C' (Petredes and Pandya 1999) ... ventral middle frontal gyrus
%
% A4 = 'Auditory 4 Complex' (Morosan et al 2005).... dorsal STG
% A5 = 'Auditory 5 Complex' .... ventral STG
%
% PF = 'Area PF Complex'.... supramarginal gyrus
% PFop = 'Area PF opercular'... ant supramarginal gyrus, operculum, ventral postcentral sulcus
%
% PSL = 'PeriSylvian Language Area'.... angular gyrus
%
% TE1a = 'Area TE1 anterior' (von Economo and Koskinas 1925, Triarhou 2007)... ant middle temporal gyrus
%
% STV = 'Superior Temporal Visual Area' .... post STG

regiondef = {   'SMC',  {'1','2','3a','3b','4','6v','6d','43','55b','PEF','FEF','OP4','i6-8'};... % sensorimotor cortex... included operculum bc ecog strips can't get into operc
                'vPMC', {'6r','FOP1'};... % ventral premotor... there are some elcs put into 'SMC' areas that are actually in vPMC... included operculum bc ecog strips can't get into operc
                'MFG',  {'8Av','8C','p9-46v'};... middle frontal gyrus... maybe also inf front sulcus
                'IFG/IFS',  {'44','45','IFSp'};... % inferior frontal gyrus
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

analyze_responsive_elcs_only = 0;

% param = 'p_min_stim_prep_prod'; % general task responsivity
% param = 'p_prep';
% param = 'p_prod';
% param = 'p_stim';

% param = 'p_prep_learn';
% param = 'p_prod_learn';

% param = 'p_prep_nn_v_nat';
% param = 'p_prod_nn_v_nat';

% param = 'p_prep_novel_vs_trained';
% param = 'p_prod_novel_vs_trained';

param = 'p_prep_novel_vs_nat';
% param = 'p_prod_novel_vs_nat';

% param = 'p_stim_syl';
% param = 'p_prep_syl';
% param = 'p_prod_syl';

% param = 'p_stim_rime';
% param = 'p_prep_rime';
% param = 'p_prod_rime';


% alpha = 0.01; 
alpha = 0.05; 

bar_face_color = [0.5 0.5 0.5]; 

paramvals = resp{:,param};
param_name = param; 
full_param_string = param; 

compare_areal_tuning() % in ieeg_funcs_am



