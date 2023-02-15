 % Rereferencing
  
%%%%% % Varun says to find connect info in 'channels' table within: derivatives/<subject_id>/annot/
 
% % % %   % ecog Common Average Reference
% % % %   el_ecog = electrode(electrode.type=="ECOG",:);
% % % %   cfg=[];
% % % %   cfg.label = el_ecog.name;
% % % %   cfg.group = el_ecog.connector;
% % % %   cfg.method = 'CTAR'; %using trimmed average referencing
% % % %   cfg.percent = 50; %percentage of 'extreme' channels in group to trim 
% % % %   D_filt_trial_mask_ref = bml_rereference(cfg,D_filt_trial_mask);

electrode.connector = ones(height(electrode),1); % delete this line once we get correct connector info
  D_hpf_ref = D_hpf;
  
  % macro bipolar reference to central
  el_macro = electrode(electrode.type=="MACRO",:);
  if ~isempty(el_macro)
    cfg=[];
    cfg.method = 'bipolar'; 
    cfg.label = unique(el_macro.electrode);
    cfg.refchan = {'macro_Lc'}; 
    cfg.refkeep = false; 
    D_hpf_ref = bml_rereference(cfg,D_hpf_ref);
  end
  
  % dbs lead bipolar reference
  el_dbs = electrode(electrode.type=="DBS",:);
  if ~isempty(el_dbs)
    cfg=[];
    cfg.method = 'CAR'; 
    cfg.group = el_dbs.connector;
    cfg.label = el_dbs.name;
    D_hpf_ref = bml_rereference(cfg,D_hpf_ref);
  end
    
  % ecog CTAR
  el_ecog = electrode(electrode.type=="ECOG",:);
  if ~isempty(el_ecog)
    cfg=[];
    cfg.method = 'CTAR'; 
    cfg.percent = 50;
    cfg.group = el_ecog.connector;
    cfg.label = el_ecog.name;
    D_hpf_ref = bml_rereference(cfg,D_hpf_ref);
  end
  
  clear D_filt_trial_mask