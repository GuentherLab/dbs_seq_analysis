function annotate_manual_ephys_artifacts(op)
%ANNOTATE_MANUAL_EPHYS_ARTIFACTS  Interactive GUI for manual annotation of
%   intra-operative ephys artifacts in a FieldTrip raw structure.
%
% Usage
%   annotate_manual_ephys_artifacts()
%   annotate_manual_ephys_artifacts(op)
%
% op fields (all optional)
%   .sub                – Subject ID string, e.g. 'DM1005'  (prompted if absent)
%   .n_chans_raster     – Channels shown per screen in raster view     [40]
%   .n_chans_timecourse – Channels shown per screen in timecourse view [20]
%
% Input file
%   Y:\DBS\derivatives\sub-<SUB>\fieldtrip\sub-<SUB>_ses-intraop_task-smsl_ft-raw.mat
%   Must contain a FieldTrip raw struct with fields: trial, time, label.
%   data_mat = D.trial{1}  [nCh x nTime]
%   time_vec = D.time{1}   [1   x nTime]  (global time coordinates, seconds)
%
% Output .tsv columns
%   id       – integer row index
%   starts   – window start  [global time / s]
%   ends     – window end    [global time / s]
%   duration – ends - starts [s]
%   label    – channel label matching D.label
%
% Requirements: MATLAB R2018b+ (yline, string arrays, datetime arithmetic)
%==========================================================================
%% 0.  Defaults
%==========================================================================
if nargin < 1 || isempty(op), op = struct(); end
if ~isfield(op,'n_chans_raster'),      op.n_chans_raster     = 40; end
if ~isfield(op,'n_chans_timecourse'),  op.n_chans_timecourse = 20; end
%==========================================================================
%% 1.  Subject ID
%==========================================================================
if ~isfield(op,'sub') || isempty(op.sub)
    ans_ = inputdlg('Enter subject ID:','Subject ID',1,{'DM10'});
    if isempty(ans_), return; end
    op.sub = strtrim(ans_{1});
end
%==========================================================================
%% 2.  Load FieldTrip file
%==========================================================================
ft_path = fullfile('Y:\DBS','derivatives', ...
    ['sub-' op.sub], 'fieldtrip', ...
    ['sub-' op.sub '_ses-intraop_task-smsl_ft-raw.mat']);
fprintf('\n=== FieldTrip file ===\n');
fprintf('  Path : %s\n', ft_path);
dinfo = dir(ft_path);
if isempty(dinfo)
    errordlg(sprintf('File not found:\n%s',ft_path),'File Not Found');
    return;
end
fprintf('  Size : %.2f MB\n', dinfo.bytes/1e6);
t_load0 = datetime('now');
fprintf('  Load started : %s\n', char(t_load0,'HH:mm:ss.SSS'));
loaded = load(ft_path);
t_load1 = datetime('now');
fprintf('  Load done    : %s  (%.2f s)\n\n', ...
    char(t_load1,'HH:mm:ss.SSS'), seconds(t_load1 - t_load0));
% Identify FieldTrip raw struct
D = [];
for fv_ = fieldnames(loaded)'
    cand_ = loaded.(fv_{1});
    if isstruct(cand_) && all(isfield(cand_,{'trial','label','time'}))
        D = cand_; break;
    end
end
if isempty(D)
    errordlg('No FieldTrip raw struct (trial/label/time) found in file.','Load Error');
    return;
end
data_mat  = D.trial{1};         % [nCh x nTime]
time_vec  = D.time{1};          % [1   x nTime]
ch_labels = cellstr(D.label);   % {nCh x 1}
n_chans   = size(data_mat,1);

% Run external cleaning function
fprintf('  Running initial data cleaning...\n');
t_clean0 = datetime('now');
[D_cleaned, cleaning_func_cfg_out] = hpf_and_instantaneous_artifact_mask(D);
data_mat_clean = D_cleaned.trial{1};
t_clean1 = datetime('now');
fprintf('  Cleaning done: %.2f s\n\n', seconds(t_clean1 - t_clean0));

%==========================================================================
%% 3.  Shared state  (accessed/modified by nested functions)
%==========================================================================
viewmode  = 'timecourse';    % 'raster' | 'timecourse'
cur_chunk = 1;
% Custom zoom limits
custom_xlim = [];
custom_ylim = [];
% Trace Scaling values
raw_scale_val = 1.0;
clean_scale_val = 1.0;
% Artifact table
artifact = table( ...
    zeros(0,1,'double'), zeros(0,1,'double'), ...
    zeros(0,1,'double'), zeros(0,1,'double'), strings(0,1), ...
    'VariableNames',{'id','starts','ends','duration','label'});
% Current gray selections – struct array
SEL = struct('t_start',{},'t_end',{},'ch_start',{},'ch_end',{});
% Rubber-band drag state
is_dragging = false;
drag_x0     = NaN;
drag_y0     = NaN;
rband_h     = [];   % graphics handle, [] = none
% Colormaps (15)
CMAPS = {'parula','turbo','jet','hsv','hot','cool','spring','summer', ...
         'autumn','winter','gray','bone','copper','pink','colorcube'};
cur_cmap   = 'parula';
MAX_TC_PTS = 5000;  % max displayed time-points per trace (timecourse mode)
%==========================================================================
%% 4.  Build figure & controls
%==========================================================================
LP_W = 0.19;   % fractional figure width for left panel
fig = figure( ...
    'Name',          ['Artifact Annotator  |  sub-' op.sub], ...
    'NumberTitle',   'off', ...
    'Units',         'normalized', ...
    'OuterPosition', [0.01 0.03 0.98 0.94], ...
    'Color',         [0.93 0.93 0.93], ...
    'WindowButtonDownFcn',   @btn_down_cb, ...
    'WindowButtonMotionFcn', @btn_motion_cb, ...
    'WindowButtonUpFcn',     @btn_up_cb, ...
    'WindowKeyPressFcn',     @key_press_cb);
% ── Left panel ────────────────────────────────────────────────────────────
lp = uipanel(fig, ...
    'Title','Controls','Units','normalized', ...
    'Position',[0 0 LP_W 1], ...
    'BackgroundColor',[0.87 0.87 0.87],'FontSize',9);
% Stacking helpers
ny_ = 0.985;  ch_ = 0.028;  dh_ = 0.032;

% View mode Toggle
yp_ = ny_-ch_; ny_ = ny_-dh_;
btn_viewmode = uicontrol(lp,'Style','pushbutton', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_],'Callback',@viewmode_cb);

% Legend (Changed to style 'text' to safely handle HTML)
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','text','String','<html><b>Traces: Black = Raw, <font color="blue">Blue = cleaned</font></b></html>', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87]);

% Colormap
yp_ = ny_-ch_; ny_ = ny_-dh_;
lbl_cmap = uicontrol(lp,'Style','text','String','Colormap:', ...
    'Units','normalized','Position',[0.05 yp_ 0.40 ch_], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87]);
dd_cmap = uicontrol(lp,'Style','popupmenu','String',CMAPS, ...
    'Units','normalized','Position',[0.45 yp_ 0.50 ch_],'Callback',@cmap_cb);

% Channel count modifiers
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','text','String','N Visible Chans Raster:', ...
    'Units','normalized','Position',[0.05 yp_ 0.50 ch_], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87]);
ed_raster = uicontrol(lp,'Style','edit','String',num2str(op.n_chans_raster), ...
    'Units','normalized','Position',[0.60 yp_ 0.35 ch_]);
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','text','String','N Visible Chans Timecourse:', ...
    'Units','normalized','Position',[0.05 yp_ 0.50 ch_], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87]);
ed_timecourse = uicontrol(lp,'Style','edit','String',num2str(op.n_chans_timecourse), ...
    'Units','normalized','Position',[0.60 yp_ 0.35 ch_]);
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','pushbutton','String','Update Chans', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_],'Callback',@update_chans_cb);
ny_ = ny_ - 0.010;   % spacer

% Trace Scaling Controls
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','text','String','Raw scaling:', ...
    'Units','normalized','Position',[0.05 yp_ 0.45 ch_], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87]);
ed_raw_scale = uicontrol(lp,'Style','text','String',num2str(raw_scale_val,'%.2f'), ...
    'Units','normalized','Position',[0.50 yp_ 0.15 ch_], 'BackgroundColor','w');
uicontrol(lp,'Style','pushbutton','String','▲', ...
    'Units','normalized','Position',[0.68 yp_ 0.12 ch_],'Callback',@(~,~) scale_cb('raw', 0.25));
uicontrol(lp,'Style','pushbutton','String','▼', ...
    'Units','normalized','Position',[0.82 yp_ 0.12 ch_],'Callback',@(~,~) scale_cb('raw', -0.25));

yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','text','String','Cleaned scaling:', ...
    'Units','normalized','Position',[0.05 yp_ 0.45 ch_], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87]);
ed_clean_scale = uicontrol(lp,'Style','text','String',num2str(clean_scale_val,'%.2f'), ...
    'Units','normalized','Position',[0.50 yp_ 0.15 ch_], 'BackgroundColor','w');
uicontrol(lp,'Style','pushbutton','String','▲', ...
    'Units','normalized','Position',[0.68 yp_ 0.12 ch_],'Callback',@(~,~) scale_cb('clean', 0.25));
uicontrol(lp,'Style','pushbutton','String','▼', ...
    'Units','normalized','Position',[0.82 yp_ 0.12 ch_],'Callback',@(~,~) scale_cb('clean', -0.25));
ny_ = ny_ - 0.010;   % spacer

% Channel group
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','text','String','Channel group:', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87]);
yp_ = ny_-ch_; ny_ = ny_-dh_;
dd_chunk = uicontrol(lp,'Style','popupmenu','String',{'...'}, ...
    'Units','normalized','Position',[0.05 yp_ 0.65 ch_],'Callback',@chunk_cb);
uicontrol(lp,'Style','pushbutton','String','▲', ...
    'Units','normalized','Position',[0.72 yp_ 0.10 ch_],'Callback',@chunk_prev_cb);
uicontrol(lp,'Style','pushbutton','String','▼', ...
    'Units','normalized','Position',[0.84 yp_ 0.10 ch_],'Callback',@chunk_next_cb);
ny_ = ny_ - 0.018;   % spacer

% Zoom controls
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','pushbutton','String','Zoom selection (q)', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_], ...
    'Callback',@zoom_sel_cb);
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','pushbutton','String','Zoom full (w)', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_], ...
    'Callback',@zoom_full_cb);
ny_ = ny_ - 0.018;   % spacer

% Artifact action buttons
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','pushbutton','String','Add artifact (a)', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_], ...
    'FontWeight','bold','Callback',@add_artifact_cb);
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','pushbutton','String','Remove selected artifact (r)', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_],'Callback',@remove_artifact_cb);
ny_ = ny_ - 0.018;   % spacer

% File buttons
yp_ = ny_-ch_; ny_ = ny_-dh_;
uicontrol(lp,'Style','pushbutton','String','Load artifact mask (o)', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_],'Callback',@load_artifact_cb);
yp_ = ny_-ch_; 
uicontrol(lp,'Style','pushbutton','String','Save artifact mask (k)', ...
    'Units','normalized','Position',[0.05 yp_ 0.90 ch_],'Callback',@save_artifact_cb);

% Sub-panel for Cleaning Config
pnl_clean = uipanel(lp, 'Title','Cleaning Config', 'Units','normalized', ...
    'Position',[0.02 0.01 0.96 0.23], 'BackgroundColor',[0.87 0.87 0.87]);

tt_spike = 'estimated duration of a spike artifact in seconds, from spike onset to peak';
tt_iqr   = 'threshold to identify outliers (e.g. outlier > 75th percentile + iqr_thr*interquartile range)';
tt_fc    = 'Cutoff frequency for high-pass filter';

% Expected spike dur (s)
uicontrol(pnl_clean,'Style','text','String','Expected spike dur (s):', ...
    'Units','normalized','Position',[0.02 0.73 0.65 0.20], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87], ...
    'TooltipString', tt_spike);
ed_spike_dur = uicontrol(pnl_clean,'Style','edit', ...
    'String',num2str(cleaning_func_cfg_out.spike_dur), ...
    'Units','normalized','Position',[0.70 0.73 0.25 0.20], ...
    'TooltipString', tt_spike);

% Outlier IQR threshold
uicontrol(pnl_clean,'Style','text','String','Outlier IQR threshold:', ...
    'Units','normalized','Position',[0.02 0.48 0.65 0.20], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87], ...
    'TooltipString', tt_iqr);
ed_iqr_thr = uicontrol(pnl_clean,'Style','edit', ...
    'String',num2str(cleaning_func_cfg_out.iqr_thr), ...
    'Units','normalized','Position',[0.70 0.48 0.25 0.20], ...
    'TooltipString', tt_iqr);

% High pass cutoff (Hz)
init_fc = '0';
if isfield(cleaning_func_cfg_out, 'f_c')
    init_fc = num2str(cleaning_func_cfg_out.f_c);
end

uicontrol(pnl_clean,'Style','text','String','High pass cutoff (Hz):', ...
    'Units','normalized','Position',[0.02 0.23 0.65 0.20], ...
    'HorizontalAlignment','left','BackgroundColor',[0.87 0.87 0.87], ...
    'TooltipString', tt_fc);
ed_fc = uicontrol(pnl_clean,'Style','edit', ...
    'String',init_fc, ...
    'Units','normalized','Position',[0.70 0.23 0.25 0.20], ...
    'TooltipString', tt_fc);

uicontrol(pnl_clean,'Style','pushbutton','String','Update cleaned traces', ...
    'Units','normalized','Position',[0.05 0.02 0.90 0.18], ...
    'Callback',@update_clean_cb);

% ── Selection Information Text (under plots) ──────────────────────────────
txt_sel_info = uicontrol(fig, 'Style','text', 'Units','normalized', ...
    'Position',[LP_W+0.04, 0.02, 0.6, 0.04], 'HorizontalAlignment','left', ...
    'BackgroundColor', [0.93 0.93 0.93], 'FontSize', 10, ...
    'String', 'Selection: None');

% ── Main axes ─────────────────────────────────────────────────────────────
ax = axes(fig,'Units','normalized', ...
    'Position',[LP_W+0.04, 0.09, 1-LP_W-0.06, 0.87]);
%==========================================================================
%% 5.  Initialise display
%==========================================================================
update_viewmode_button();
update_chunk_dropdown();
update_plot();

%==========================================================================
%%   ═══════════  N E S T E D   F U N C T I O N S  ═══════════
%==========================================================================

% ── Simple helpers ────────────────────────────────────────────────────────
    function n = n_per_chunk()
        if strcmp(viewmode,'raster'), n = op.n_chans_raster;
        else,                         n = op.n_chans_timecourse; end
    end

    function nc = n_chunks()
        nc = ceil(n_chans / n_per_chunk());
    end

    function vis = get_vis_chans()
        npc = n_per_chunk();
        s   = (cur_chunk-1)*npc + 1;
        e   = min(s+npc-1, n_chans);
        vis = s:e;
    end

    function gi = lbl2idx(lbl)
        gi = find(strcmp(ch_labels, char(lbl)), 1);
    end

% ── Chunk dropdown ────────────────────────────────────────────────────────
    function update_chunk_dropdown()
        npc  = n_per_chunk();
        nc   = n_chunks();
        strs = cell(nc,1);
        for ci = 1:nc
            s = (ci-1)*npc + 1;
            e = min(s+npc-1, n_chans);
            strs{ci} = sprintf('%s - %s', ch_labels{s}, ch_labels{e});
        end
        dd_chunk.String = strs;
        cur_chunk = max(1, min(cur_chunk, nc));
        dd_chunk.Value  = cur_chunk;
    end

    function update_chans_cb(~,~)
        v_rast = str2double(ed_raster.String);
        v_time = str2double(ed_timecourse.String);
        if ~isnan(v_rast) && v_rast > 0, op.n_chans_raster = round(v_rast); end
        if ~isnan(v_time) && v_time > 0, op.n_chans_timecourse = round(v_time); end
        custom_xlim = []; custom_ylim = [];
        update_chunk_dropdown();
        clip_sels_to_vis();
        update_plot();
    end

    function chunk_prev_cb(~,~)
        if dd_chunk.Value > 1
            dd_chunk.Value = dd_chunk.Value - 1;
            chunk_cb();
        end
    end

    function chunk_next_cb(~,~)
        if dd_chunk.Value < numel(dd_chunk.String)
            dd_chunk.Value = dd_chunk.Value + 1;
            chunk_cb();
        end
    end

% ── Scaling Callback ──────────────────────────────────────────────────────
    function scale_cb(type, delta)
        if strcmp(type, 'raw')
            raw_scale_val = max(0.1, raw_scale_val + delta);
            ed_raw_scale.String = num2str(raw_scale_val, '%.2f');
        else
            clean_scale_val = max(0.1, clean_scale_val + delta);
            ed_clean_scale.String = num2str(clean_scale_val, '%.2f');
        end
        update_plot();
    end

% ── Update Cleaning Config ────────────────────────────────────────────────
    function update_clean_cb(~,~)
        cfg = struct();
        val_spike = str2double(ed_spike_dur.String);
        val_iqr = str2double(ed_iqr_thr.String);
        val_fc = str2double(ed_fc.String);
        
        if isnan(val_spike) || isnan(val_iqr) || isnan(val_fc)
            errordlg('Invalid cleaning parameters (must be numeric).','Invalid Input');
            return;
        end
        
        cfg.spike_dur = val_spike;
        cfg.iqr_thr = val_iqr;
        cfg.f_c = val_fc;
        
        set(fig, 'pointer', 'watch'); drawnow;
        
        % Setup dialog without a progress bar, but with a timer
        dlg = dialog('Name', 'Please wait', 'Position', [500 500 250 80]);
        txt_dlg = uicontrol(dlg, 'Style', 'text', 'Position', [20 20 210 40], ...
            'String', 'Updating cleaned traces... 0.0 s', 'FontSize', 10);
        t0 = tic;
        tmr = timer('ExecutionMode','fixedSpacing', 'Period',0.1, ...
                    'TimerFcn', @(~,~) update_stopwatch_dlg(txt_dlg, t0));
        start(tmr);

        try
            [D_cleaned_new, cfg_out_new] = hpf_and_instantaneous_artifact_mask(D, cfg);
            data_mat_clean = D_cleaned_new.trial{1};
            
            ed_spike_dur.String = num2str(cfg_out_new.spike_dur);
            ed_iqr_thr.String = num2str(cfg_out_new.iqr_thr);
            if isfield(cfg_out_new, 'f_c')
                ed_fc.String = num2str(cfg_out_new.f_c);
            end
        catch ME
            stop(tmr); delete(tmr);
            if isgraphics(dlg), close(dlg); end
            set(fig, 'pointer', 'arrow');
            errordlg(sprintf('Cleaning function failed:\n%s', ME.message), 'Cleaning Error');
            return;
        end
        
        stop(tmr); delete(tmr);
        if isgraphics(dlg), close(dlg); end
        
        set(fig, 'pointer', 'arrow');
        update_plot();
    end

    function update_stopwatch_dlg(txt_dlg, t0)
        if isgraphics(txt_dlg)
            el = toc(t0);
            txt_dlg.String = sprintf('Updating cleaned traces...\nElapsed time: %.1f s', el);
        end
    end

% ── Main plot ─────────────────────────────────────────────────────────────
    function update_plot()
        delete(findobj(fig,'Type','colorbar'));
        ax.Position = [LP_W+0.04, 0.09, 1-LP_W-0.06, 0.87];
        cla(ax);
        hold(ax,'on');
        vis   = get_vis_chans();
        n_vis = numel(vis);

        % ── RASTER ───────────────────────────────────────────────────────
        if strcmp(viewmode,'raster')
            set(lbl_cmap,'Visible','on');
            set(dd_cmap, 'Visible','on');
            % Standardise each row relative to itself to avoid blowouts
            vis_data = double(data_mat(vis,:));
            for i = 1:size(vis_data,1)
                s = std(vis_data(i,:));
                if s < eps('single'), s = 1; end
                vis_data(i,:) = (vis_data(i,:) - mean(vis_data(i,:))) / s;
            end
            imagesc(ax, time_vec, 1:n_vis, vis_data);
            colormap(ax, cur_cmap);
            try 
                cbh = colorbar(ax); 
                cbh.FontSize = 8; 
                % Apply decimal formatting safely to colorbar only
                cbh.Ruler.TickLabelFormat = '%.1f'; 
                cbh.Ruler.Exponent = 0; 
            catch
            end
            
            for ai = 1:height(artifact)
                gi = lbl2idx(artifact.label(ai));
                if isempty(gi), continue; end
                li = find(vis==gi,1);
                if isempty(li), continue; end
                rect_outline(artifact.starts(ai), artifact.ends(ai), ...
                             li-0.5, li+0.5, [0.85 0.07 0.07], 2.5);
            end
            for si = 1:numel(SEL)
                [li1,li2] = sel2local(SEL(si),vis,n_vis);
                if isnan(li1), continue; end
                rect_outline(SEL(si).t_start, SEL(si).t_end, ...
                             li1-0.5, li2+0.5, [0.25 0.25 0.25], 2.0);
            end

        % ── TIMECOURSE ───────────────────────────────────────────────────
        else
            set(lbl_cmap,'Visible','off');
            set(dd_cmap, 'Visible','off');
            
            for ai = 1:height(artifact)
                gi = lbl2idx(artifact.label(ai));
                if isempty(gi), continue; end
                li = find(vis==gi,1);
                if isempty(li), continue; end
                rect_fill(artifact.starts(ai), artifact.ends(ai), ...
                          li-0.48, li+0.48, [1 0.67 0.67], [0.80 0.05 0.05], 1.8);
            end
            for si = 1:numel(SEL)
                [li1,li2] = sel2local(SEL(si),vis,n_vis);
                if isnan(li1), continue; end
                rect_fill(SEL(si).t_start, SEL(si).t_end, ...
                          li1-0.48, li2+0.48, [0.78 0.78 0.78], [0.33 0.33 0.33], 1.5);
            end
            for ki = 1:n_vis-1
                yline(ax, ki+0.5, 'Color',[0.79 0.79 0.79], 'LineWidth',0.5);
            end
            nt = numel(time_vec);
            if nt > MAX_TC_PTS
                ds   = floor(nt / MAX_TC_PTS);
                t_d  = time_vec(1:ds:end);
                idx_ = 1:ds:nt;
            else
                t_d  = time_vec;
                idx_ = 1:nt;
            end
            for ki = 1:n_vis
                sig       = double(data_mat(vis(ki), idx_));
                sig_clean = double(data_mat_clean(vis(ki), idx_));
                
                s = std(sig(:));
                if s < eps('single'), s = 1; end
                
                s_clean = std(sig_clean(:));
                if s_clean < eps('single'), s_clean = 1; end
                
                % Scale the raw signal
                sig_n       = (sig       - mean(sig))       ./ (6*s)       * raw_scale_val   + ki;
                % Scale the cleaned signal by its own std so it fills the space similarly
                sig_clean_n = (sig_clean - mean(sig_clean)) ./ (6*s_clean) * clean_scale_val + ki;
                
                plot(ax, t_d, sig_n,       'Color','k', 'LineWidth',0.5);
                plot(ax, t_d, sig_clean_n, 'Color','b', 'LineWidth',0.5);
            end
        end

        % ── Common formatting ─────────────────────────────────────────────
        yticks(ax, 1:n_vis);
        yticklabels(ax, ch_labels(vis));
        ax.TickLabelInterpreter = 'none';
        
        if isempty(custom_ylim)
            ylim(ax, [0.5, n_vis+0.5]);
        else
            ylim(ax, custom_ylim);
        end
        
        if isempty(custom_xlim)
            xlim(ax, [time_vec(1), time_vec(end)]);
        else
            xlim(ax, custom_xlim);
        end
        
        xlabel(ax,'Time (s)');
        ylabel(ax,'Channel');
        ax.YDir    = 'reverse';   % channel 1 at top
        ax.FontSize = 8;
        ax.Layer   = 'top';
        
        % Only format the XAxis mathematically to avoid wiping out manual strings on YAxis
        ax.XAxis.TickLabelFormat = '%.1f';
        ax.XAxis.Exponent = 0;
        
        drawnow limitrate;
        update_selection_info();
    end

    function update_selection_info()
        if isempty(SEL)
            txt_sel_info.String = 'Selection: None';
        else
            dur = SEL(1).t_end - SEL(1).t_start;
            % The .ch_start and .ch_end properties hold the global channel index
            n_ch = abs(SEL(1).ch_end - SEL(1).ch_start) + 1;
            txt_sel_info.String = sprintf('Selection: Duration = %.3f s, Channels selected = %d', dur, n_ch);
        end
    end

    function rect_outline(t0,t1,y0,y1,clr,lw)
        plot(ax,[t0 t1 t1 t0 t0],[y0 y0 y1 y1 y0], ...
            '-','Color',clr,'LineWidth',lw,'HitTest','off');
    end

    function rect_fill(t0,t1,y0,y1,fc,ec,lw)
        patch(ax,[t0 t1 t1 t0],[y0 y0 y1 y1], ...
            fc,'EdgeColor',ec,'LineWidth',lw,'FaceAlpha',0.50,'HitTest','off');
    end

    function [li1,li2] = sel2local(sel,vis,n_vis)
        inr = vis(vis >= sel.ch_start & vis <= sel.ch_end);
        if isempty(inr), li1=NaN; li2=NaN; return; end
        li1 = find(vis==inr(1),  1);
        li2 = find(vis==inr(end),1);
        li1 = max(1,min(n_vis,li1));
        li2 = max(1,min(n_vis,li2));
    end

% ── Key Press / Zoom Callbacks ────────────────────────────────────────────
    function key_press_cb(~, event)
        switch event.Character
            case 'a'
                add_artifact_cb();
            case 'r'
                remove_artifact_cb();
            case 'q'
                zoom_sel_cb();
            case 'w'
                zoom_full_cb();
            case 'm'
                viewmode_cb();
            case 'o'
                load_artifact_cb();
            case 'k'
                save_artifact_cb();
        end
    end

    function zoom_sel_cb(~,~)
        if isempty(SEL), return; end
        vis = get_vis_chans();
        n_vis = numel(vis);
        [li1, li2] = sel2local(SEL(1), vis, n_vis);
        if isnan(li1), return; end
        custom_xlim = [SEL(1).t_start, SEL(1).t_end];
        custom_ylim = [li1 - 0.5, li2 + 0.5];
        update_plot();
    end

    function zoom_full_cb(~,~)
        custom_xlim = [];
        custom_ylim = [];
        update_plot();
    end

% ── View-mode / chunk / colormap callbacks ────────────────────────────────
    function update_viewmode_button()
        if strcmp(viewmode, 'timecourse')
            btn_str = '<html><span style="background-color:#d4edda; color:#007A33; font-size:1.15em;"><b>&nbsp;Timecourse&nbsp;</b></span> // Raster (m)</html>';
        else
            btn_str = '<html>Timecourse // <span style="background-color:#d4edda; color:#007A33; font-size:1.15em;"><b>&nbsp;Raster&nbsp;</b></span> (m)</html>';
        end
        set(btn_viewmode, 'String', btn_str);
    end

    function viewmode_cb(~,~)
        old_vis = get_vis_chans();
        if strcmp(viewmode, 'timecourse')
            viewmode = 'raster';
        else
            viewmode = 'timecourse';
        end
        
        update_viewmode_button();
        custom_xlim = []; custom_ylim = [];
        cur_chunk = best_chunk_for(old_vis);
        update_chunk_dropdown();
        clip_sels_to_vis();
        update_plot();
    end

    function best = best_chunk_for(old_vis)
        npc=n_per_chunk(); nc=n_chunks();
        best=1; bn=-1;
        for ci=1:nc
            s=(ci-1)*npc+1; e=min(s+npc-1,n_chans);
            ov=numel(intersect(old_vis,s:e));
            if ov>bn, bn=ov; best=ci; end
        end
    end

    function clip_sels_to_vis()
        if isempty(SEL), return; end
        vis=get_vis_chans();
        keep=true(1,numel(SEL));
        for si=1:numel(SEL)
            inr=vis(vis>=SEL(si).ch_start & vis<=SEL(si).ch_end);
            if isempty(inr), keep(si)=false;
            else, SEL(si).ch_start=inr(1); SEL(si).ch_end=inr(end); end
        end
        SEL=SEL(keep);
    end

    function chunk_cb(~,~)
        cur_chunk=dd_chunk.Value;
        custom_xlim = []; custom_ylim = [];
        update_plot();
    end

    function cmap_cb(~,~)
        cur_cmap=CMAPS{dd_cmap.Value};
        update_plot();
    end

% ── Mouse callbacks ───────────────────────────────────────────────────────
    function btn_down_cb(~,~)
        cp=ax_coords_clamped();
        if isempty(cp), return; end
        is_dragging=true;
        drag_x0=cp(1); drag_y0=cp(2);
        if isgraphics(rband_h), delete(rband_h); end
        rband_h = patch(ax, ...
            'XData', repmat(drag_x0,1,4), ...
            'YData', repmat(drag_y0,1,4), ...
            'FaceColor','none','EdgeColor',[0.20 0.20 0.20], ...
            'LineWidth',1.5,'LineStyle','--','HitTest','off');
    end

    function btn_motion_cb(~,~)
        if ~is_dragging, return; end
        cp=ax_coords_raw();
        if isempty(cp), return; end
        x0=min(drag_x0,cp(1)); x1=max(drag_x0,cp(1));
        y0=min(drag_y0,cp(2)); y1=max(drag_y0,cp(2));
        if isgraphics(rband_h)
            set(rband_h,'XData',[x0 x1 x1 x0],'YData',[y0 y0 y1 y1]);
        end
    end

    function btn_up_cb(~,~)
        if ~is_dragging, return; end
        is_dragging=false;
        if isgraphics(rband_h), delete(rband_h); end
        rband_h=[];
        cp=ax_coords_raw();
        if isempty(cp), return; end
        t_lo=max(min(drag_x0,cp(1)), time_vec(1));
        t_hi=min(max(drag_x0,cp(1)), time_vec(end));
        if t_hi<=t_lo, return; end
        y_lo=min(drag_y0,cp(2));
        y_hi=max(drag_y0,cp(2));
        vis=get_vis_chans(); n_vis=numel(vis);
        li_lo=max(1,     ceil(y_lo - 0.5));
        li_hi=min(n_vis, floor(y_hi + 0.5));
        if li_lo>li_hi
            li_lo=max(1,min(n_vis,round((y_lo+y_hi)/2)));
            li_hi=li_lo;
        end
        % Replaces prior selection entirely rather than appending
        SEL = struct('t_start',t_lo,'t_end',t_hi, ...
                     'ch_start',vis(li_lo),'ch_end',vis(li_hi));
        update_plot();
    end

    function cp=ax_coords_clamped()
        cp=ax_coords_raw();
        if isempty(cp), return; end
        xl=sort(xlim(ax)); yl=sort(ylim(ax));
        if cp(1)<xl(1)||cp(1)>xl(2)||cp(2)<yl(1)||cp(2)>yl(2), cp=[]; end
    end

    function cp=ax_coords_raw()
        pt=ax.CurrentPoint;
        if isempty(pt), cp=[]; return; end
        cp=[pt(1,1), pt(1,2)];
    end

% ── Add artifact ──────────────────────────────────────────────────────────
    function add_artifact_cb(~,~)
        if isempty(SEL)
            msgbox('No region selected.','Add Artifact','help'); return;
        end
        rows=sels_to_rows(SEL);
        SEL=struct('t_start',{},'t_end',{},'ch_start',{},'ch_end',{});
        if height(rows)==0, update_plot(); return; end
        combine_artifact_tables(rows);
    end

    function rows=sels_to_rows(sels)
        rows=mk_empty_table();
        for si=1:numel(sels)
            s=sels(si);
            for gi=s.ch_start:s.ch_end
                rows=[rows; mk_row(0,s.t_start,s.t_end,ch_labels{gi})]; %#ok<AGROW>
            end
        end
    end

% ── Remove artifact ───────────────────────────────────────────────────────
    function remove_artifact_cb(~,~)
        if isempty(SEL)
            msgbox('No region selected.','Remove Artifact','help'); return;
        end
        if height(artifact)==0
            msgbox('Artifact table is empty.','Remove Artifact','help'); return;
        end
        aff=false(height(artifact),1);
        for ai=1:height(artifact)
            gi=lbl2idx(artifact.label(ai));
            if isempty(gi), continue; end
            for si=1:numel(SEL)
                sel=SEL(si);
                if gi<sel.ch_start||gi>sel.ch_end, continue; end
                if artifact.ends(ai)<=sel.t_start, continue; end
                if artifact.starts(ai)>=sel.t_end, continue; end
                aff(ai)=true; break;
            end
        end
        if ~any(aff)
            msgbox('No overlap with existing artifacts.','Remove Artifact','help'); return;
        end
        aff_idx=find(aff);
        if numel(aff_idx)>1 && is_multi_group(aff_idx)
            btn=questdlg('Remove multiple groups of time x channels?', ...
                'Confirm Removal','Yes','No','No');
            if isempty(btn)||strcmp(btn,'No'), return; end
        end
        new_art=mk_empty_table();
        for ai=1:height(artifact)
            gi=lbl2idx(artifact.label(ai));
            if ~aff(ai)||isempty(gi)
                new_art=[new_art; artifact(ai,:)]; %#ok<AGROW>
                continue;
            end
            ivs=[artifact.starts(ai), artifact.ends(ai)];
            for si=1:numel(SEL)
                sel=SEL(si);
                if gi<sel.ch_start||gi>sel.ch_end, continue; end
                ivs=sub_interval(ivs,sel.t_start,sel.t_end);
                if isempty(ivs), break; end
            end
            for ri=1:size(ivs,1)
                if ivs(ri,2)-ivs(ri,1)>1e-10
                    new_art=[new_art; mk_row(0,ivs(ri,1),ivs(ri,2),ch_labels{gi})]; %#ok<AGROW>
                end
            end
        end
        artifact=sortrows(new_art,{'starts','label'});
        artifact.id=(1:height(artifact))';
        update_plot();
    end

    function out=sub_interval(ivs,rm_s,rm_e)
        out=zeros(0,2);
        for k=1:size(ivs,1)
            a=ivs(k,1); b=ivs(k,2);
            if     rm_e<=a||rm_s>=b,       out(end+1,:)=[a,b];        %#ok<AGROW>
            elseif rm_s<=a&&rm_e>=b,       
            elseif rm_s<=a,                out(end+1,:)=[rm_e,b];     %#ok<AGROW>
            elseif rm_e>=b,                out(end+1,:)=[a,rm_s];     %#ok<AGROW>
            else, out(end+1,:)=[a,rm_s]; out(end+1,:)=[rm_e,b];       %#ok<AGROW>
            end
        end
    end

    function result=is_multi_group(idx)
        n=numel(idx);
        if n<=1, result=false; return; end
        adj=false(n);
        for ii=1:n
            gi_i=lbl2idx(artifact.label(idx(ii)));
            for jj=ii+1:n
                gi_j=lbl2idx(artifact.label(idx(jj)));
                ch_ok=~isempty(gi_i)&&~isempty(gi_j)&&abs(gi_i-gi_j)<=1;
                t_ok = artifact.starts(idx(ii)) < artifact.ends(idx(jj)) && ...
                       artifact.starts(idx(jj)) < artifact.ends(idx(ii));
                if ch_ok&&t_ok, adj(ii,jj)=true; adj(jj,ii)=true; end
            end
        end
        visited=false(n,1); n_comp=0;
        for k=1:n
            if ~visited(k)
                n_comp=n_comp+1;
                if n_comp>1, result=true; return; end
                q=k;
                while ~isempty(q)
                    cur=q(1); q(1)=[];
                    if visited(cur), continue; end
                    visited(cur)=true;
                    q=[q, find(adj(cur,:)&~visited')]; %#ok<AGROW>
                end
            end
        end
        result=n_comp>1;
    end

% ── combine_artifact_tables ───────────────────────────────────────────────
    function combine_artifact_tables(new_rows)
        artifact=[artifact; new_rows];
        u_lbls=unique(artifact.label);
        merged=mk_empty_table();
        for ui=1:numel(u_lbls)
            lbl  =u_lbls(ui);
            sub_t=sortrows(artifact(artifact.label==lbl,:),'starts');
            ms=sub_t.starts(1); me=sub_t.ends(1);
            for ri=2:height(sub_t)
                if sub_t.starts(ri)<=me+1e-10
                    me=max(me,sub_t.ends(ri));
                else
                    merged=[merged; mk_row(0,ms,me,char(lbl))]; %#ok<AGROW>
                    ms=sub_t.starts(ri); me=sub_t.ends(ri);
                end
            end
            merged=[merged; mk_row(0,ms,me,char(lbl))]; %#ok<AGROW>
        end
        merged   =sortrows(merged,{'starts','label'});
        merged.id=(1:height(merged))';
        artifact =merged;
        update_plot();
    end

% ── Load artifact mask ────────────────────────────────────────────────────
    function load_artifact_cb(~,~)
        if height(artifact)>0
            btn=questdlg( ...
                'Artifact table is not empty. Add loaded table to current artifacts?', ...
                'Load Artifact Mask','Yes','No','Yes');
            if isempty(btn)||strcmp(btn,'No'), return; end
        end
        annot_dir=fullfile('Y:\DBS','derivatives',['sub-' op.sub],'annot');
        [fname,fdir]=uigetfile( ...
            {'*artifact*.tsv','Artifact TSV (*artifact*.tsv)'; ...
             '*.tsv',         'All TSV (*.tsv)'}, ...
            'Load Artifact Mask', annot_dir);
        if isequal(fname,0), return; end
        
        % Subject mismatch check
        tok = regexp(fname, '^sub-([^_]+)_', 'tokens');
        if ~isempty(tok)
            file_sub = tok{1}{1};
            if ~strcmp(file_sub, op.sub)
                ans_btn = questdlg(sprintf('Subject mismatch!\nLoaded file subject: %s\nCurrent workspace subject: %s\n\nProceed anyway?', file_sub, op.sub), 'Subject Mismatch', 'Proceed', 'Cancel', 'Cancel');
                if isempty(ans_btn) || strcmp(ans_btn, 'Cancel')
                    return;
                end
            end
        end
        try
            al=readtable(fullfile(fdir,fname), ...
                'FileType','text','Delimiter','\t','TextType','string');
        catch ME
            errordlg(sprintf('Cannot read file:\n%s',ME.message),'Load Error');
            return;
        end
        probs=validate_art_table(al);
        if ~isempty(probs)
%             errordlg(['Validation failed:' newline strjoin(probs,newline)], ...
%                 'Invalid Artifact Table');
%             return;
        end
        req={'starts','ends','duration','label'};
        xtra=setdiff(al.Properties.VariableNames,req);
        for k=1:numel(xtra), al.(xtra{k})=[]; end
        al.label=string(al.label);
        al.id   =zeros(height(al),1,'double');
        al=al(:,{'id','starts','ends','duration','label'});
        combine_artifact_tables(al);
    end

    function probs=validate_art_table(T)
        probs={};
        if height(T)==0
            probs{end+1}='  * Table has zero rows.'; return;
        end
        req_cols={'starts','ends','duration','label'};
        for ci=1:numel(req_cols)
            col=req_cols{ci};
            if ~ismember(col,T.Properties.VariableNames)
                probs{end+1}=sprintf('  * Missing column: ''%s''.',col);
            else
                v=T.(col);
                if ismember(col,{'starts','ends','duration'})&&~isnumeric(v)
                    probs{end+1}=sprintf('  * ''%s'' must be numeric (got %s).',col,class(v));
                end
                if strcmp(col,'label')&&~(isstring(v)||iscell(v))
                    probs{end+1}=sprintf('  * ''label'' must be string/cell (got %s).',class(v));
                end
            end
        end
        if ~isempty(probs), return; end
        if any(abs((T.ends-T.starts)-T.duration)>1e-9)
            probs{end+1}='  * duration != ends-starts for some rows.';
        end
        if any(T.duration<=0|isnan(T.duration))
            probs{end+1}='  * Some durations are <= 0 or NaN.';
        end
        ls=string(T.label);
        bad_lbl=~ismember(ls,string(ch_labels));
        if any(bad_lbl)
            ul=unique(ls(bad_lbl));
            probs{end+1}=sprintf('  * %d label(s) not in FieldTrip object: %s', ...
                numel(ul),strjoin(ul,', '));
        end
        bad_t=T.starts<time_vec(1)|T.ends>time_vec(end);
        if any(bad_t)
            probs{end+1}=sprintf('  * %d row(s) outside time range [%.4f, %.4f] s.', ...
                sum(bad_t),time_vec(1),time_vec(end));
        end
    end

% ── Save artifact mask ────────────────────────────────────────────────────
    function save_artifact_cb(~,~)
        annot_dir   =fullfile('Y:\DBS','derivatives',['sub-' op.sub],'annot');
        default_name=sprintf('sub-%s_ses-intraop_task-smsl_artifact-manual.tsv',op.sub);
        [fname,fdir]=uiputfile({'*.tsv','Tab-separated values (*.tsv)'}, ...
            'Save Artifact Mask',fullfile(annot_dir,default_name));
        if isequal(fname,0), return; end
        try
            writetable(artifact,fullfile(fdir,fname), ...
                'FileType','text','Delimiter','\t');
            msgbox(sprintf('Saved:\n%s',fullfile(fdir,fname)),'Saved');
        catch ME
            errordlg(sprintf('Save failed:\n%s',ME.message),'Save Error');
        end
    end

% ── Table utilities ───────────────────────────────────────────────────────
    function T=mk_empty_table()
        T=table(zeros(0,1,'double'),zeros(0,1,'double'), ...
                zeros(0,1,'double'),zeros(0,1,'double'),strings(0,1), ...
                'VariableNames',{'id','starts','ends','duration','label'});
    end

    function row=mk_row(id_,t0_,t1_,lbl_char)
        row=table(double(id_),double(t0_),double(t1_),double(t1_-t0_), ...
                  string(lbl_char), ...
                  'VariableNames',{'id','starts','ends','duration','label'});
    end

end

%% claude/gemini prompts:
% create a matlab function ‘annotate_manual_ephys_artifacts’ that does the following.
% i have a fieldtrip variable stored in a file with filepath formatted as: 
% Y:\DBS\derivatives\sub-[SUBJECT]\fieldtrip\sub-[SUBJECT]_ses-intraop_task-smsl_ft-raw_trial.mat
% 
% function should take ‘op’ structure. if op.sub ([SUBJECT] above)  is not supplied, make a popup, prefilled with ‘DM1005’, where user can fill it in. 
% 
% open the fieldtrip file.within D.trial{1}, rows are electrodes, columns are timepoints. look up file formatting in fieldtrip to understand. before loading, display the filepath of the fieldtirp file and its size, and the time loading started. Once it’s loaded, display the time it took to load it. 
% 
% when it’s loaded, create a gui which displays the timecourses of a set of channels. there should be 2 main viewmodes: timecourse and raster. in both of these, x axis is time. rows should display activity of a set of channels. in the raster, color = magnitude, y axis = channel, x axis = time. default to ‘parula’ colormap; include a dropdown to choose from 15 different popular colormaps. in the ‘timecourse’ version, each row shows the timecourse of a channel as black on white background; within that row, y axis shows magnitude of that channel at each timepoint. 
% 
% use the ‘labels’ field of the fieldtrip object to label the rows corresponding to each channel. use ‘time’ field from the fieldtrip variable to label x axis. 
% 
% include parameter op.n_chans_raster (default to 40) and op.n_chans_timecourse (default to 20) which determine how many channels to include on the screen at once. 
% 
% The user should be able to select groups of [time x channel] rectangles. in raster mode, they should then be able to click and drag a portion of the raster, to select rectangular groups of coordinates (channel x timepoints). these should stay visibly selected with a gray border after the user has made a selection, so that the user can highlight multiple groups of coordinates. this should work basically the same for timecourses, except that portions of timecourse plots across 1 or more channels will get highlighted at once. When a group is selected in raster mode, it should be surrounded by a gray box. When selected in timecourse mode, the times x channels should be highlighted in light gray. 
% 
% when the gui is first opened, create a table variable called ‘artifact’ with the following columns:
% -id - double -  just a number indicating the row of the table [1 to nrows]
% -starts - double - time of the start of the artifactual window in global time coordinates [GTC] - seconds since midnight on the day of the experiment
% -ends - double - end of the artifact window, also in GTC
% -duration - double - starts minus ends
% -label - string - channel name - must correspond to a label in the ‘label’ field in the fieldtrip object
% 
% The ultimate output of this GUI is intended to be a .tsv table in this format. 
% 
% include a button ‘add selected artifact’. when this is clicked, then all grey selections should turn red and stay red unless they are removed. additionally, add all selected [times x channels] to the artifact table. This should add one row per channel selected; the starts, ends, and duration values in this row should indicate the time selected. however, if any of these [time x channels] are contiguous with a row already in the table, combine the two into a single row in the artifact table. once the rows have been added to the artifact table, sort the table - first by ‘starts’ then by ‘label’ to break ties. do this combination of artifact tables and updating of the plot with a subfunction ‘combine_artifact_tables’, which we will also use later. 
% 
% include a button for ‘remove selected artifact’. The user should be able to highlight [time x channel]s that have already been added to the artifact table (as part of the grey rectangle they are selecting). When ‘remove selected artifact’ is clicked, then all selected [time x channels] should be removed from the artifact table, and the red outline/highlight around them should be removed. if this would remove more than one non-contiguous groups of [time x channels], bring up a popup dialogue box asking “Remove multiple groups of time x channels?” with ‘yes’ and ‘no’ options. Do the removal if ‘yes’ is selected. If ‘no’ is selected, then don’t do the removal, but keep the gray selection box/highlight where it is. 
% 
% in the gui, include a dropdown, which lists chunks of trials [chunks sized at op.n_chans_raster or op.n_chans_timecourse]. when the user selects a chunk of trials, switch the display that chunk of channels. in the listing of channels in dropdown, list the first and last channel (e.g. “ecog_101 - dbs_52”). 
% 
% when switching between raster and timecourse mode, make sure to update the red outlines/highlights based on the current contents of the artifact table. also keep the gray ‘curent selection’ box where it is on the same [time x channel]s. The currently-viewed channels will likely not be the same, due to the different number of channels per view, so pick the channel group that overlaps the most with the previous view. some selected channels in the previous view may not be visible anymore, so remove those from the selected [time x channel]s. 
% 
% the gui should have an option ‘load artifact mask’. when this is pressed, if the artifact table is currently non-empty - if any [time x channel]s are highlighted in red - display a dialogue box saying “Artifact table is not empty. Add loaded table to current selection?” with ‘yes’ and ‘no’ options. this ‘load artifact mask’ option should open a dialogue to load a file. start by trying to look in the following folder: 
% Y:\DBS\derivatives\sub-[SUBJECT]\annot\
% 
% This should look for files with ‘artifact’ in the name which end with ‘.tsv’. First load this into matabl as a variable called ‘artifact_loaded’. It should have the same columns as described above in the ‘artifact’ table. Then, give an error dialogue box if any of the following are true (and display the problem) [do not output an actual matlab error, just display the dialogue box and delete the ‘artifact_loaded’ variable]:
% -table has zero rows
% -missing any of the 4 column variables, or they are an unexpected class
% -durations are not equal to starts minus ends
% -durations are zero or less or are nans
% -any of the ‘label’s do not match a label in the fieldtrip object
% -any of the time windows exist outside of the time windows indicated by the fieldtrip ‘time’ field [meaning they are outside the time range of what we have loaded from the fieldtrip file]
% 
% If there are additional columns, remove them from the table. If the table passes the checks, then add its columns to the current ‘artifact’ variable, via the ‘combine_artifact_tables’ subfunction described above, which should also update the plot. if no artifacts have been added in the current work session [nothing has been highlighted in red], this should function the same, because the loaded artifact table will be added to the zero-row artifact table. then delete the ‘artifact_loaded’ variable, because its info should be copied to the ‘artifact’ variable. 
% 
% Include a button ‘save artifact mask’. When this is clicked, open a file browser dialogue box. start in the same folder we load artifact tables from. the default file savename is:
% sub-[SUBJECT]_ses-intraop_task-smsl_artifact-manual.tsv
% 
% this save subfunction should always warn about overwriting - though this should already be included if it’s a normal windows file-saving dialogue box. 
% 
% put all buttons, fields, and menus stacked on the left side; rasters/timecourses to the right.


% output a modified version of this script [not word doc] with these changes:
% -disable to ability to select multiple boxes at once. once a selection is made, erase the previous [gray] selections.
% -allow a keyboard shortcut - when user presses “a”, the selected grey box becomes an artifact box. also change the label on the ‘add artifact’ button to “Add artifact (a)” to indicate this.
% -add keyboard shortcut “r” for remove selected artifact; update the button to add “ (r)" to the end of the button label.
% -always start in ‘timecourse’ view mode, not raster
% -change the expected end of the fieldtip file string from '_ses-intraop_task-smsl_ft-raw_trial.mat' to 'ses-intraop_task-smsl_ft-raw.mat'
% -add a button ‘zoom selection’ and ‘zoom full’. when ‘zoom selection’ is clicked, change the time we are looking at and the channels we are looking at to only the selected [time x channel]s.. ‘zoom full’ should zoom
% ---include keyboard shortcut ‘=’ for zoom selection, and shortcut ‘-’ for zoom full. add these shortcut keys to the button labels.
% 
% -when trying to load load an artifact table, add a check: look for a string at the beginning of the artifact table name which will be ‘sub-[SUBJECT]’. if [SUBJECT] isn’t the same as what we currently have loaded for op.sub, show both of them to the user in a dialogue box, and give option to proceed or to not load artifact mask.
% -add 2 fillable fields on the side of the gui that display the values of  op.n_chans_timecourse and  op.n_chans_raster. the user should be able to edit these values, then click an ‘update’ button next to them which changes these values. this should immediately change the number of channels currently being viewed, and also update what is shown in the dropdown menus to selecting chunks of channels.
% -change how the values of the raster are mapped to colors: they should always be relative to values within the channel itself, so that extreme values in one channel don’t make values in other channels all appear to be zero

% make these modifications to the artifact annotation script at the bottom:
% -instead of just 1 trace per channel, I want there to generally be 2 overlaid traces. the first trace is the raw data, as before. the second trace - ‘cleaned data’ - will be a version of this raw data that has gone through a process of high pass filtering and cleaned of artifacts. the HPF and cleaning will be entirely performed by an external cleaning function, ‘hpf_and_instantaneous_artifact_mask.m’. do not make this cleaning function, it already exists.
% -the cleaning function takes (arg 1) the fieldtrip structure (generally called something like ‘D’ or “D_raw’) which the provided GUI script already loads. the cleaning function also takes (arg 2) an optional cfg configuration structure; it can be called without providing this cfg, in which case the cleaning function sets defaults for all parameters listed in the cfg structure.
% -the cleaning function has 1 outputs: cleaned data ‘D_cleaned’ (out 1) and config structure ‘cfg_out’ (out 2). by getting cfg_out, we can see what were set as defaults in cfg if we didn’t provide specifications. 
% -when the gui is started and the raw fieldtrip data is loaded, run the cleaning function, using the loaded raw fieldtrip data as the first input, and no cfg structure input. name the first output of the cleaning D_cleaned and the second output cleaning_func_cfg_out. then, for each channel, plot the trace of the raw data (which the old version of the gui script already did) in black and overlay it with the cleaned version of that trace in blue. add a legend to the left-side control panel of the gui indicating colors and raw vs. cleaned
% -add a sub-panel to the lower part of the left side panel in the gui. this contains a field for each of the parameters of the cleaning function. it also contains a button ‘Update cleaned traces’. when the gui is first started and the cleaning function is run, get the second output of that function (cleaning_func_cfg_out) and use it to pre-populate the fields for each cfg param, so the user knows what defaults were used. the user can then edit these fields and click ‘Update’ button, which should re-run the cleaning function with the new cfg parameters, get rid of the previous cleaned traces, and replace them with hte newly computed cleaned traces (leave the raw traces as-is). 
% -the cfg field params are: spike_dur, iqr_thresh
% 
% that’s working. make the following further modifications:
% -for each channel’s cleaned trace, scale it so that it occupies more of the vertical space available on that row. don’t change the raw traces. the reason for doing this scaling is that after high pass filtering, the cleaned traces look very flat and it’s hard to see deviations in y value in them. 
% -after clicking the ‘update cleaned traces’ button, pop up a temporary box saying ‘Updating cleaned traces’ until they are updated and replotted. include a stopwatch timer in that box to show how long it’s taking to update them. 
% -a third parameter expected to be in the cfg structure called ‘f_c’; include a field in the gui for updating this, like the other cfg parameters
% -change the visible GUI labels associated with the fields for updating cfg params, because what these parameters is not transparent. use this mapping: spike_dur = ‘Expected spike dur (s)’..... iqr_thr = ‘Outlier IQR threshold’ ……. f_c = ‘High pass cutoff (Hz)’
% ….
% -when first listing the cfg params, include, somewhere, comments with these descriptions for them. also add tooltips so that when hovering over the field or the field label in the GUI, these descriptions pop up:
% spike_dur % estimated duration of a spike artifact in seconds, from spike onset to peak
% iqr_thr  % threshold to identify outliers (e.g. outlier > 75th percentile + iqr_thr*interquartile range)
% f_c % Cutoff frequency for high-pass filter
% 
% make the following edits to this newest version:
% -where it describes the blue/black traces, all of that text is currently blue. fix this by making it so that only “Blue = cleaned” is blue, the rest is black. 
% -add text at the bottom of the right section of gui (under the bottom trace) that says the duration of the currently selected gray box and how many channels are selected
% -in the left panel, add control for each of ‘Raw scaling’ and ‘Cleaned scaling’. These control the magnitude of scaling of each of the traces, for effectively scaling the y axes in a trace-specifc manner. These should display the current two values of the scaling, and have up and down arrows for each of them. Raw scaling will always start at 1. Cleaned scaling will be whatever you decided to set it at each time after running the cleaning function and updating the cleaned traces. For how much the up and down arrows increment, pick a sensible increment - the user should be able to click a few times and make the traces in question look significantly bigger or smaller. 
% -change yticklabels - spell out all digits plus one decimal - not scientific notation
% -in the popup box that appears during cleaning, keep the timer but get rid of the progress bar
