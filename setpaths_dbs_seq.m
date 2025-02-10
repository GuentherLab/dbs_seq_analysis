%%%% set paths for AM dbs-seq analysis depending on computer

[~,compname] = system('hostname'); compname = string(deblank(compname));

%%%%% paths differentiated by matlab running locally vs. on server
  if strcmp(compname, 'NSSBML01') % if working on TURBO (BML server computer)
      PATH_BML = 'C:\Program Files\Brain-Modulation-Lab\bml'; 
     PATH_IEEG_FT_FUNCS_AM = 'C:\Users\amsmeier\ieeg_ft_funcs_am'; % ieeg processing code shared across AM projects
     PATH_DBSSEQ_CODE = 'Y:\Documents\Code\dbs_seq_analysis'; 
     PATH_FIELDTRIP_CODE = 'Y:\Users\lbullock\MATLAB_external_libs_Turbo20230907\fieldtrip'; 
     PATH_LEADDBS = 'C:\Program Files\LeadDBS';
 elseif any(strcmp(compname, {'MSI','677-GUE-WL-0010'})) % if working with files local on AM computers 
     PATH_CODE = 'C:\docs\code'; % AM laptop top directory for all code repos 
     PATH_BML = [PATH_CODE filesep 'bml']; 
     PATH_IEEG_FT_FUNCS_AM = [PATH_CODE filesep 'ieeg_ft_funcs_am']; % ieeg processing code shared across AM projects
     PATH_DBSSEQ_CODE = [PATH_CODE filesep 'dbs_seq_analysis'];; 
     PATH_FIELDTRIP_CODE = [PATH_CODE filesep 'fieldtrip']; % previously tried using remote Y drive version, but often causes matlab to freeze
     PATH_BML = [PATH_CODE filesep 'bml']; 
     PATH_LEADDBS = [PATH_CODE filesep ]; % ? have a copy on local computer ? 
  else 
     error('computer name not recognized; please add computer to setpaths_dbs_triplet.m')
 end

 %%%% paths differentiated by whether or not Y drive on Turbo is available
 % sometimes running [ isdir('Y:\DBS') ] over a VPN will make matlab lag endlessly
 % ........ may help to restart local machine and reconnect to VPN
 if strcmp(compname, 'NSSBML01') || isdir('Y:\DBS')  % if working on TURBO (BML server computer) or accessing via mapped Y drive
      PATH_DATA='Y:\DBS';
     
     PATH_RESULTS = [PATH_DATA filesep 'groupanalyses\task-smsl\gotrials'];
     PATH_AVERAGE_MNI = 'Z:/DBS/DBS_subject_lists/MNI_ICBM_2009b_NLIN_ASYM/cortex/CortexLowRes_15000V.mat';
     PATH_SUBCORT_ATLAS_VIM = 'C:\Program Files\LeadDBS_Classic\leaddbs\templates\space\MNI_ICBM_2009b_NLIN_ASYM\atlases\DISTAL (Ewert 2017)/atlas_index.mat';
     PATH_STN_ATLAS = 'Z:\Resources\STN-Atlas\atlas_index.mat';
 elseif any(strcmp(compname, {'MSI','677-GUE-WL-0010'})) % if working with local data - not stored on server
     PATH_DATA = 'D:\DBS_MGH'; %%% may not have a copy on all machines.... use the SSD for faster load times
     PATH_RESULTS = [PATH_DATA filesep 'groupanalyses\task-smsl\gotrials'];
     PATH_AVERAGE_MNI = [PATH_RESULTS filesep 'atlases' filesep 'CortexLowRes_15000V_MNI_ICBM_2009b_NLIN_ASYM.mat']; 
     PATH_SUBCORT_ATLAS_VIM = [PATH_RESULTS filesep 'atlases' filesep 'atlas_index_DISTAL_Ewert2017.mat']; % too large to keep in github; put atlases in Results
     PATH_STN_ATLAS = [PATH_RESULTS filesep 'atlases' filesep 'atlas_index_subcort_Ewert_v2.1.7.mat']; 
     
 else 
     error('computer name not recognized; please add computer to setpaths_dbs_triplet.m')
 end



 % common paths
  PATH_DER = [PATH_DATA filesep 'derivatives'];
 PATH_SRC = [PATH_DATA filesep 'sourcedata'];
 

paths_to_add = {PATH_DATA;... % derivatives and (if on server) sourcedata
                PATH_RESULTS;... % outputs of post-derivatives analyses by AM
                PATH_DBSSEQ_CODE;... % code by AM for triplet analysis
                    [PATH_DBSSEQ_CODE filesep 'preprocessing'];...
                    [PATH_DBSSEQ_CODE filesep 'andrew_plotting'];  ...
                    [PATH_DBSSEQ_CODE filesep 'coherence'];...
                    [PATH_DBSSEQ_CODE filesep 'mPraat-master'];  ...
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

vardefault('op',struct);
field_default('op','art_crit','E'); % E = high gamma, F = beta

PATH_ARTIFACT = [PATH_DBSSEQ_CODE filesep 'P08_artifact_criteria_', op.art_crit]; % keep in repo to sync across devices


 clearvars compname paths_to_add PATH_CODE PATH_BML