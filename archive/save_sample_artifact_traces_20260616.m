 %%% save a few example traces to send to Alfonso

 setpaths_dbs_seq()
 tempdir = 'C:\temp'; 

 %%
 % message:
% % %  here’s the data for an example channel with the ~0.3Hz oscillation that was not removed by the cleaning function. 
% % %  That updated function is also attached - I%m using the default parameters. 
% % %  This artifact is visible in 5 channels in sub1052 and 20 channels in sub1054. 
% % %  All ecog channels that don’t look like they have much activity aside from the oscillation, 
% % %  .....so not too bad to just mask them all, but it might be useful to understand why the 2Hz high pass filter isn.t getting rid of the activity. 

sub = 'DM1054';

clear D
load([PATH_DER, filesep, 'sub-',sub, filesep, 'fieldtrip', filesep, 'sub-',sub, '_ses-intraop_task-smsl_ft-raw.mat'])

cfg = [];
cfg.channel = 'ecog_L147'; 
channel_data = ft_selectdata(cfg, D);
save([tempdir, filesep, '0_3Hz oscillation example - ', sub, ' - ', cfg.channel],'D')

%%
%%% message: 
% % %  I’ve attached an example channel with a long stretch of what may be real but high-amplitude raw traces (sub 1008, ecog107)
% % %  ....that got flattened by the cleaning function. 
% % %      Also included is the neighboring channel e108, which has lower amplitude, real-looking raw traces
% % %  ...that did not get flattened by the cleaning function. 
% % %  This is an even smaller problem - only 5 already-somewhat-questionable ecog channels in sub 1008. 

sub = 'DM1008';

clear D
load([PATH_DER, filesep, 'sub-',sub, filesep, 'fieldtrip', filesep, 'sub-',sub, '_ses-intraop_task-smsl_ft-raw.mat'])

cfg = [];
cfg.channel = {'ecog_L107', 'ecog_L108'}; 
channel_data = ft_selectdata(cfg, D);
save([tempdir, filesep, 'flattened high-amplitude raw trace example - ', sub, ' - ', cfg.channel{1}],'D')