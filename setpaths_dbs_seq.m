%%%% set paths for AM dbs-seq analysis depending on computer

[~,compname] = system('hostname'); compname = string(deblank(compname));
vardefault('op',struct);
field_default('op','art_crit','E'); % E = high gamma, F = beta
field_default('op','default_trialdur_max_if_empty',15);  % use this trial duration in sec if it's not provided (used in set_project_specific_variables.m)

 switch compname
     case {'MSI','677-GUE-WL-0010'} % AM personal computer, work laptop
         PATH_DATA = 'D:\DBS_MGH'; %%% may not have a copy on all machines.... use the SSD for faster load times
         PATH_CODE = 'C:\docs\code'; % AM laptop top directory for all code repos
         PATH_DBSSEQ_CODE = [PATH_CODE filesep 'dbs_seq_analysis']; 
         PATH_IEEG_FT_FUNCS_AM = [PATH_CODE filesep 'ieeg_ft_funcs_am']; % ieeg processing code shared across AM projects
         PATH_BML = [PATH_CODE filesep 'bml']; 
         PATH_FIELDTRIP_CODE = [PATH_CODE filesep 'fieldtrip']; 
         PATH_LEADDBS = [PATH_CODE filesep ]; 
         PATH_AVERAGE_MNI = [PATH_RESULTS filesep 'atlases' filesep 'CortexLowRes_15000V_MNI_ICBM_2009b_NLIN_ASYM.mat']; 
         PATH_SUBCORT_ATLAS_VIM = [PATH_RESULTS filesep 'atlases' filesep 'atlas_index_DISTAL_Ewert2017.mat']; % too large to keep in github; put atlases in Results
         PATH_STN_ATLAS = [PATH_RESULTS filesep 'atlases' filesep 'atlas_index_subcort_Ewert_v2.1.7.mat']; 
     case 'NSSBML01' % TURBO - BML server computer
         PATH_DATA='Y:\DBS';
         PATH_DBSSEQ_CODE = 'Y:\Documents\Code\dbs_seq_analysis'; 
         PATH_IEEG_FT_FUNCS_AM = 'C:\Users\amsmeier\ieeg_ft_funcs_am'; % ieeg processing code shared across AM projects
         PATH_BML = 'C:\Program Files\Brain-Modulation-Lab\bml'; 
         PATH_FIELDTRIP_CODE = 'Y:\Users\lbullock\MATLAB_external_libs_Turbo20230907\fieldtrip'; 
         PATH_LEADDBS = 'C:\Program Files\LeadDBS';
         PATH_AVERAGE_MNI = 'Z:/DBS/DBS_subject_lists/MNI_ICBM_2009b_NLIN_ASYM/cortex/CortexLowRes_15000V.mat';
         PATH_SUBCORT_ATLAS_VIM = 'C:\Program Files\LeadDBS_Classic\leaddbs\templates\space\MNI_ICBM_2009b_NLIN_ASYM\atlases\DISTAL (Ewert 2017)/atlas_index.mat';
         PATH_STN_ATLAS = 'Z:\Resources\STN-Atlas\atlas_index.mat';
     otherwise 
         error('computer name not recognized; please add computer to setpaths_dbs_triplet.m')
 end

 % common paths
  PATH_DER = [PATH_DATA filesep 'derivatives'];
 PATH_SRC = [PATH_DATA filesep 'sourcedata'];
 PATH_RESULTS = [PATH_DATA filesep 'groupanalyses\task-smsl\gotrials'];
PATH_ARTIFACT = [PATH_DATA filesep 'groupanalyses\task-smsl' filesep 'A09_artifact_criteria_', op.art_crit];

paths_to_add = {PATH_DATA;... % derivatives and (if on server) sourcedata
                PATH_RESULTS;... % outputs of post-derivatives analyses by AM
                PATH_DBSSEQ_CODE;... % code by AM for triplet analysis
                    [PATH_DBSSEQ_CODE filesep 'preprocessing'];...
                    [PATH_DBSSEQ_CODE filesep 'andrew_plotting'];  ...
                PATH_IEEG_FT_FUNCS_AM;.... 
                    [PATH_IEEG_FT_FUNCS_AM, filesep, 'util'];...
                PATH_BML;... % Brain Modulation Lab repo
                PATH_FIELDTRIP_CODE;...
                PATH_LEADDBS;...
    };
addpath(paths_to_add{:});

ft_defaults()
bml_defaults()

set(0, 'DefaultTextInterpreter', 'none')
set(0, 'DefaultLegendInterpreter', 'none')
% set(0, 'DefaultAxesTickLabelInterpreter', 'none')

format long

 clearvars compname paths_to_add PATH_CODE PATH_BML