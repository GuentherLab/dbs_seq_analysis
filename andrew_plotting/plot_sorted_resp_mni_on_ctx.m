% dbs-seq version

%% Loading paths
ft_defaults
bml_defaults
format long

% clear
set(0,'DefaultFigureWindowStyle','docked')
% set(0,'DefaultFigureWindowStyle','normal')

markersize = 50; 

% srt_row = 19;


%% load electrode responses and mni coords
PATH_DATASET = 'Y:\DBS';
PATH_DBSSEQ_ANALYSIS = [PATH_DATASET '\groupanalyses\task-smsl\gotrials']; 
% load([PATH_DBSSEQ_ANALYSIS filesep 'resp_all_subjects'])

% % % % % % % % n_elc = height(resp);

%% Configuration Variables and Paths
% PATH_ANALYSIS = '/Users/ao622/Dropbox (Personal)/Lab-BML/Expan/2021-11-16-FOOOF-figures';
% % % % % % % % % PATH_DATA='/Users/ao622/Dropbox (Personal)/Lab-BML/Expan/2021-11-16-FOOOF-figures/data';
PATH_AVERAGE_MNI = 'Z:\DBS\DBS_subject_lists/MNI_ICBM_2009b_NLIN_ASYM/cortex/CortexLowRes_15000V.mat';
PATH_SUBCORT_ATLAS = '/Volumes/Nexus/Resources/STN-Atlas/atlas_index.mat';
PATH_SUBCORT_ATLAS_VIM = '/Users/ao622/git/leaddbs/templates/space/MNI_ICBM_2009b_NLIN_ASYM/atlases/DISTAL (Ewert 2017)/atlas_index.mat';


% cd(PATH_ANALYSIS)
% electrode = readtable('data/A01_DBS_aper_coord_dx.tsv','Delimiter', '\t', 'TreatAsEmpty', 'NA','FileType','text');

%loading cortical reconstructions
average_mni = load(PATH_AVERAGE_MNI);

% subcort = load(PATH_SUBCORT_ATLAS);
% subcort_vim = load(PATH_SUBCORT_ATLAS_VIM);
% nii_vimi = ea_load_nii('/Users/ao622/git/leaddbs/templates/space/MNI_ICBM_2009b_NLIN_ASYM/atlases/DISTAL (Ewert 2017)/lh/91.nii.gz');
% nii_vime = ea_load_nii('/Users/ao622/git/leaddbs/templates/space/MNI_ICBM_2009b_NLIN_ASYM/atlases/DISTAL (Ewert 2017)/lh/94.nii.gz');
% nii_vimip = ea_load_nii('/Users/ao622/git/leaddbs/templates/space/MNI_ICBM_2009b_NLIN_ASYM/atlases/DISTAL (Ewert 2017)/lh/104.nii.gz');
% nii_vimep = ea_load_nii('/Users/ao622/git/leaddbs/templates/space/MNI_ICBM_2009b_NLIN_ASYM/atlases/DISTAL (Ewert 2017)/lh/122.nii.gz');
% 
% subcort_vimi_lh_fv = ea_nii2fv(nii_vimi);
% subcort_vime_lh_fv = ea_nii2fv(nii_vime);
% subcort_vimip_lh_fv = ea_nii2fv(nii_vimip);
% subcort_vimep_lh_fv = ea_nii2fv(nii_vimep);

% % % %loading VL posterior ventral from Morel atlas
% nii_vlpv = ea_load_nii('/Users/ao622/git/leaddbs/templates/space/MNI_ICBM_2009b_NLIN_ASYM/atlases/MorelAtlasICBM2009b (Jakab 2008)/lh/VLpv.nii.gz');
% subcort_vlpv_lh_fv = ea_nii2fv(nii_vlpv);

color_et_ecog = '#C4604F';% #ET ECoG
color_pd_ecog = '#6F67A6';% #PD ECoG
color_ep_seeg = '#8A4F80';% #EP sEEG
color_pd_stn = '#F7924A';% #PD STN
color_pd_gpi = '#F9BD00';% #PD GPi
color_et_vim = '#36A5D1';% #ET VIM
color_ep_cm = '#9EB859';% #EP CM



%% make sorted version of resp table
%%%% find and plot the electrodes which are best tuned for a given parameter

param = 'p_prep_syl3';

% % % % % delete channels if they have nan for the following parameter
% exclude_if_nan_param = 'p_prep';

srt = sortrows(resp,param); 
srt = movevars(resp,{param},'After','chan');



%% ecog
plotcolor = 'r';

snap_to_surf = 1; % if true, project eletrodes to nearest point on ctx surface

% shift electrodes so that they aren't covered by the brain surface
%%% gets applied after snapping to surface
%%% .... if snapping, offset of -1 should be enough to have points entirely above ctx surface (in L hem)
x_offset = -1;

elc_to_plot = srt(srt_row,{'mni_nonlinear_x','mni_nonlinear_y','mni_nonlinear_z'}); 

% close all
% figure;
hpatch = patch('vertices', average_mni.Vertices, 'faces', average_mni.Faces,...
'FaceColor', [.9 .9 .9], 'EdgeColor', 'none', 'FaceAlpha',1, ...
'facelighting', 'gouraud', 'specularstrength', 0, 'ambientstrength', 0.5, 'diffusestrength', 0.5); 
hold on

xyz_to_plot_nonsnapped = [elc_to_plot.mni_nonlinear_x, elc_to_plot.mni_nonlinear_y, elc_to_plot.mni_nonlinear_z];
if snap_to_surf
    [~, surfpoint_idx] = min(pdist2(xyz_to_plot_nonsnapped,average_mni.Vertices), [], 2); % find nearest surf points
    xyz_to_plot = average_mni.Vertices(surfpoint_idx,:); 
elseif ~snap_to_surf
    xyz_to_plot = xyz_to_plot_nonsnapped;
end

hscat = scatter3(xyz_to_plot(:,1) + x_offset, xyz_to_plot(:,2), xyz_to_plot(:,3), 'filled',...
  'MarkerFaceAlpha',1,'MarkerFaceColor',plotcolor,'MarkerEdgeColor','k','LineWidth',0.01);
hscat.SizeData = 100;
view(-90,0)
axis off; axis equal
camlight('headlight','infinite');
hold off
% % % % % % % % % % % scalebar(0,70,-50, 10, 'mm')


% title(titlestr,'interpreter', 'none')

% print(gcf,[PATH_ANALYSIS 'qqq.png'],'-dpng','-r300')

