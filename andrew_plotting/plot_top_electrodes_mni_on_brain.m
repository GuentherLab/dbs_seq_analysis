% dbs-seq version
%%% before running this script, should to have the _respones.mat file created by response_types_seq.m loaded into workspace first

%% Loading paths
ft_defaults
bml_defaults
format long

% clear
% set(0,'DefaultFigureWindowStyle','docked')
set(0,'DefaultFigureWindowStyle','normal')

%% load electrode responses and mni coords
PATH_DATASET = 'Y:\DBS';
PATH_DBSSEQ_ANALYSIS = [PATH_DATASET '\groupanalyses\task-smsl\gotrials']; 
% load([PATH_DBSSEQ_ANALYSIS filesep 'resp_all_subjects'])

n_elc = height(resp);

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

%  struct_to_plot = 'ctx';
    snap_to_surf = 1; % cortex only - if true, project eletrodes to nearest point on ctx surface
    % shift electrodes so that they aren't covered by the brain surface
    %%% gets applied after snapping to surface
    %%% .... if snapping, offset of -1 should be enough to have points entirely above ctx surface (in L hem)
    x_offset = -1;
struct_to_plot = 'stn';
% struct_to_plot = 'thal';

%%% pick hemisphere to plot - subcortical only
side = 'L'; 
% side = 'R'; 


% % % % % % % % % % % % % % % % % elc_types_to_plot = {'ECOG'};

also_plot_nonsgnf_elcs = 1; 

inclusion_mode = 'thresh';
    % p_thresh = 0.001; 
%     p_thresh = 0.01;
    p_thresh = 0.05; 
% inclusion_mode = 'proportion';
%     p_proportion = 0.05; 
    p_proportion = 1; 

% inclusion_var = 'p_prep';
% inclusion_var = 'p_prod';

% inclusion_var = 'p_prep_learn';
% inclusion_var = 'p_prod_learn';


% inclusion_var = 'p_prep_nn_v_nat';
% inclusion_var = 'p_prod_nn_v_nat';


% inclusion_var = 'p_prep_novel_vs_nat'; 
% inclusion_var = 'p_prod_novel_vs_nat'; 

inclusion_var = 'p_prep_novel_vs_trained';
% inclusion_var = 'p_prod_novel_vs_trained';


% inclusion_var = 'p_prod_syl';
% inclusion_var = 'p_prep_syl';


% inclusion_var = 'p_rime'; 
% inclusion_var = 'p_rime_prep';


switch inclusion_mode
    case 'thresh'
        sgn_rows = resp{:,inclusion_var} < p_thresh;
    case 'proportion'
        [~, rows_ranked] = sort(resp{:,inclusion_var});
        sgn_rows = rows_ranked( 1:round(p_proportion * n_elc) ); 
end


% plotcolor = 'b';
plotcolor = 'r';

plotcolor_nonsgn = [0.3 0.3 0.3]; 

marker_size = 40; % size of electrode marker; scatter 'SizeData' parameter
marker_size_nonsgn = 5; 

view_angle = [-90, 0]; % use [-90, 0] for straight-on lateral left hemisphere


%% load brain surfaces
switch struct_to_plot
    case 'ctx'
        %loading cortical reconstructions
        average_mni = load(PATH_AVERAGE_MNI);
    case 'stn'
        subcort_stn = load(PATH_STN_ATLAS);
    case 'thal'
        subcort_vim = load(PATH_SUBCORT_ATLAS_VIM);
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
end


%% make brainplot

switch side
    case 'L'
        side_number = 2;
    case 'R'
        side_number = 1; 
end


% close all

% % % % % % % % % % % % % % % hfig = figure('WindowState','maximized');
% % % % % % % % % % % % % % % patch('vertices', average_mni.Vertices, 'faces', average_mni.Faces,...
% % % % % % % % % % % % % % % 'FaceColor', [.9 .9 .9], 'EdgeColor', 'none', 'FaceAlpha',1, ...
% % % % % % % % % % % % % % % 'facelighting', 'gouraud', 'specularstrength', 0, 'ambientstrength', 0.5, 'diffusestrength', 0.5)
% % % % % % % % % % % % % % % hold on




% rows_to_plot & any(strcmp(resp.type,elc_types_to_plot), 2);



% % % % if also_plot_nonsgnf_elcs
% % % %     elc_to_plot = resp(~rows_to_plot,{'mni_x','mni_y','mni_z'}); 
% % % % 
% % % %     xyz_to_plot_nonsnapped = [elc_to_plot.mni_x, elc_to_plot.mni_y, elc_to_plot.mni_z];
% % % %     if snap_to_surf
% % % %         [~, surfpoint_idx] = min(pdist2(xyz_to_plot_nonsnapped,average_mni.Vertices), [], 2); % find nearest surf points
% % % %         xyz_to_plot = average_mni.Vertices(surfpoint_idx,:); 
% % % %     elseif ~snap_to_surf
% % % %         xyz_to_plot = xyz_to_plot_nonsnapped;
% % % %     end
% % % % 
% % % %     hscat = scatter3(xyz_to_plot(:,1) + x_offset, xyz_to_plot(:,2), xyz_to_plot(:,3), 'filled',...
% % % %   'MarkerFaceAlpha',1,'MarkerFaceColor',plotcolor_nonsgnf,'MarkerEdgeColor','k','LineWidth',0.01);
% % % %     hscat.SizeData = 20;
% % % %     % % % % % % % % % % % scalebar(0,70,-50, 10, 'mm')
% % % % end
% % % % 
% % % % 
% % % % 
% % % % 
% % % % 
% % % % elc_to_plot = resp(rows_to_plot,{'mni_x','mni_y','mni_z'}); 

%%

% xyz_to_plot_nonsnapped = [elc_to_plot.mni_x, elc_to_plot.mni_y, elc_to_plot.mni_z];
% if snap_to_surf
%     [~, surfpoint_idx] = min(pdist2(xyz_to_plot_nonsnapped,average_mni.Vertices), [], 2); % find nearest surf points
%     xyz_to_plot = average_mni.Vertices(surfpoint_idx,:); 
% elseif ~snap_to_surf
%     xyz_to_plot = xyz_to_plot_nonsnapped;
% end
% 
% hscat = scatter3(xyz_to_plot(:,1) + x_offset, xyz_to_plot(:,2), xyz_to_plot(:,3), 'filled',...
%   'MarkerFaceAlpha',1,'MarkerFaceColor',plotcolor,'MarkerEdgeColor','k','LineWidth',0.01);
% hscat.SizeData = 60;
% set(gcf, 'Color', [1 1 1]); % white backgroud
% view(-90,0)
% axis off; axis equal
% camlight('headlight','infinite');
% % % % % % % % % % % % scalebar(0,70,-50, 10, 'mm')


close all

switch struct_to_plot
    case 'ctx'
        rows_to_plot_sgn = sgn_rows & string(resp.type)=="ECOG"; 
        elc_to_plot = resp(rows_to_plot_sgn,{'mni_x','mni_y','mni_z'}); 
        xyz_to_plot_nonsnapped = [elc_to_plot.mni_x, elc_to_plot.mni_y, elc_to_plot.mni_z];

        rows_to_plot_nonsgn = ~sgn_rows & string(resp.type)=="ECOG"; 
        elc_to_plot_nonsgn = resp(rows_to_plot_nonsgn,{'mni_x','mni_y','mni_z'}); 
        xyz_to_plot_nonsnapped_nonsgn = [elc_to_plot_nonsgn.mni_x, elc_to_plot_nonsgn.mni_y, elc_to_plot_nonsgn.mni_z];

        if snap_to_surf
            [~, surfpoint_idx] = min(pdist2(xyz_to_plot_nonsnapped,average_mni.Vertices), [], 2); % find nearest surf points
            xyz_to_plot = average_mni.Vertices(surfpoint_idx,:); 
            [~, surfpoint_idx] = min(pdist2(xyz_to_plot_nonsnapped_nonsgn,average_mni.Vertices), [], 2); % find nearest surf points
            xyz_to_plot_nonsgn = average_mni.Vertices(surfpoint_idx,:); 
        elseif ~snap_to_surf
            xyz_to_plot = xyz_to_plot_nonsnapped;
            xyz_to_plot_nonsgn = xyz_to_plot_nonsnapped_nonsgn;
        end

        hpatch = patch('vertices', average_mni.Vertices, 'faces', average_mni.Faces,...
            'FaceColor', [.9 .9 .9], 'EdgeColor', 'none', 'FaceAlpha',1, ...
            'facelighting', 'gouraud', 'specularstrength', 0, 'ambientstrength', 0.5, 'diffusestrength', 0.5);


    case 'stn'
        rows_to_plot_sgn = sgn_rows & contains(resp.type,{'DBS';'MACRO'}) & contains(resp.DISTAL_label_1,{'STN_'}) & contains(resp.DISTAL_label_1,{['_',side]});
        elc_to_plot = resp(rows_to_plot_sgn,{'mni_x','mni_y','mni_z'}); 
        xyz_to_plot = [elc_to_plot.mni_x, elc_to_plot.mni_y, elc_to_plot.mni_z];

        rows_to_plot_nonsgn = ~sgn_rows & contains(resp.type,{'DBS';'MACRO'}) & contains(resp.DISTAL_label_1,{'STN_'}) & contains(resp.DISTAL_label_1,{['_',side]});
        elc_to_plot_nonsgn = resp(rows_to_plot_nonsgn,{'mni_x','mni_y','mni_z'}); 
        xyz_to_plot_nonsgn = [elc_to_plot_nonsgn.mni_x, elc_to_plot_nonsgn.mni_y, elc_to_plot_nonsgn.mni_z];

        hpatch = patch('vertices', subcort_stn.atlases.fv{1,side_number}.vertices, 'faces', subcort_stn.atlases.fv{1,side_number}.faces,...
            'FaceColor', [.7 .6 .6], 'EdgeColor', 'none', 'FaceAlpha',0.5, ...
            'facelighting', 'gouraud', 'specularstrength', 0, 'ambientstrength', 0.5, 'diffusestrength', 0.5);

    case 'thal' %%%%%% need to find an appropriate VIM atlas before using this option
        rows_to_plot_sgn = sgn_rows & contains(resp.type,{'DBS';'MACRO'});
        rows_to_plot_sgn = rows_to_plot_sgn & contains(resp.MOREL_label_1,{'Thalamus'}) & contains(resp.DISTAL_label_1,{['_',side]});
        elc_to_plot = resp(rows_to_plot_sgn,{'mni_x','mni_y','mni_z'}); 
        xyz_to_plot = [elc_to_plot.mni_x, elc_to_plot.mni_y, elc_to_plot.mni_z];

        % hpatch = patch('vertices', subcort_vim.atlases.fv{???????,side_number}.vertices, 'faces', subcort_vim.atlases.fv{???????,side_number}.faces,...
        %     'FaceColor', [.7 .6 .6], 'EdgeColor', 'none', 'FaceAlpha',0.5, ...
        %     'facelighting', 'gouraud', 'specularstrength', 0, 'ambientstrength', 0.5, 'diffusestrength', 0.5);   


    case 'gp'  %%%%%% need to find an appropriate VIM atlas before using this option
        rows_to_plot_sgn = sgn_rows & contains(resp.type,{'DBS';'MACRO'}) & contains(resp.DISTAL_label_1,{'???'}) & contains(resp.DISTAL_label_1,{['_',side]});
        elc_to_plot = resp(rows_to_plot_sgn,{'mni_x','mni_y','mni_z'}); 
        xyz_to_plot = [elc_to_plot.mni_x, elc_to_plot.mni_y, elc_to_plot.mni_z];

        rows_to_plot_nonsgn = ~sgn_rows & contains(resp.type,{'DBS';'MACRO'}) & contains(resp.DISTAL_label_1,{'???'}) & contains(resp.DISTAL_label_1,{['_',side]});
        elc_to_plot_nonsgn = resp(rows_to_plot_nonsgn,{'mni_x','mni_y','mni_z'}); 
        xyz_to_plot_nonsgn = [elc_to_plot_nonsgn.mni_x, elc_to_plot_nonsgn.mni_y, elc_to_plot_nonsgn.mni_z];

        % hpatch = patch('vertices', subcort_vim.atlases.fv{???????,side_number}.vertices, 'faces', subcort_vim.atlases.fv{???????,side_number}.faces,...
        %     'FaceColor', [.7 .6 .6], 'EdgeColor', 'none', 'FaceAlpha',0.5, ...
        %     'facelighting', 'gouraud', 'specularstrength', 0, 'ambientstrength', 0.5, 'diffusestrength', 0.5);   

end

hold on

if  also_plot_nonsgnf_elcs
    hscat_non_sgnf = scatter3(xyz_to_plot_nonsgn(:,1) + x_offset, xyz_to_plot_nonsgn(:,2), xyz_to_plot_nonsgn(:,3), 'filled',...
       'MarkerFaceAlpha',1,'MarkerFaceColor',plotcolor_nonsgn,'MarkerEdgeColor','k','LineWidth',0.01);
    hscat_non_sgnf.SizeData = marker_size_nonsgn;
end


hscat_sgnf = scatter3(xyz_to_plot(:,1) + x_offset, xyz_to_plot(:,2), xyz_to_plot(:,3), 'filled',...
   'MarkerFaceAlpha',1,'MarkerFaceColor',plotcolor,'MarkerEdgeColor','k','LineWidth',0.01);
hscat_sgnf.SizeData = marker_size;



set(gcf, 'Color', [1 1 1]); % white backgroud
view(view_angle(1),view_angle(2))
axis off; axis equal
camlight('headlight','infinite');
% % % % % % % % % % % scalebar(0,70,-50, 10, 'mm')




















titlestr = inclusion_var; 
title(titlestr,'interpreter', 'none')

% print(gcf,[PATH_ANALYSIS 'qqq.png'],'-dpng','-r300')

