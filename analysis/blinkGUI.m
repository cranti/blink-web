function hMain = blinkGUI()
%BLINKGUI
%
% ReSITE: Relative Salience Identified Through Eyeblinks
%
%FUNCTIONALITY TO ADD
% > PSTH 3 column format -- check that target and reference sets are
%   matched properly (and general sorting things)
% > add 'TooltipString' property to more items
% > toggleBigButtons - prevent user from updating other things in the
%   GUI while analyses are running - TODO: reset inputs, choose output
%   button
%
%LATER
% > DOCUMENTATION
%   - update window with version info, website, etc.
%   - help documentation --> have pdf guide available?
% > GUI ISSUES
%   - uimenu, uitoolbar --> menus and toolbars?
%   - logging: how to set a location for log file?
%   - specs file? 
%   - what to do upon closing the figure? (delete GUIDATA, etc)
% > WINDOWS
%   - path joining -- will need to change some hard-coded things
%   - figure out windows installation instructions/compatibility
% > OTHER
%   - no error checking for the output file prefix
%
%GENERAL NOTES:
% > memory considerations (reset things when user toggles?)
% > think about upper limits for data that we can process -- how many
%   frames? subjects? (think about excel limitations for printing out data)
% > standardize language/terms ("sample" rather than "frame", etc)

% 6.4.2015

%%
DEV = true;

% TODO update these things
about.version = '0.1';
about.releaseDate = datestr(now, 'mm-dd-yyyy'); 


%% Text for TooltipString properties:
%TODO - edit these/add a few more

% # w range (perm)
wTip = 'Range of standard deviations considered for Gaussian kernel';
% include threshold tip (psth)
incThrTip = 'Proportion of the target data around an event that must be valid (i.e. not NaN) in order to include that event in analysis.';

% consecutive frames (perm) TODO
% window size (psth) TODO
% sample start (psth) TODO
% output prefix (both) TODO 

% # permutations (both)
permTip = 'Number of permutations for significance testing';
% significance thresholds (both)
sigTip = 'Percentile of permutations to use as significance threshold';


%% GUI

%Initialize gd (class containing a bunch of default settings)
gd = BlinkGuiData;

%MAIN FIGURE
%Parent figure width and height
W=580;
H=740;

inputPanelPosition = [10, 200, (W-20), 220];

%Color settings
bkgdColor = [215 230 235] ./256;
inputPanelColor = bkgdColor;
buttonColor = [180 250 150] ./ 256;

hMain = figure('name', 'ReSITE',...
    'units','pixels',...
    'position',[100 100 W H],...
    'MenuBar', 'none',...
    'Toolbar','none',...
    'HandleVisibility','callback',... 
    'numbertitle','off',...
    'resize', 'off',...
    'Color',bkgdColor,...
    'CloseRequestFcn',{@cbCloseGUI gd},...
    'Visible', 'off');

% menu item
hAbout = uimenu(hMain, 'Label', 'ReSITE');
uimenu(hAbout, 'Label', 'About',...
    'Callback',{@infoFig about});
uimenu(hAbout, 'Label', 'Preferences',...
    'Callback',@prefFig);
uimenu(hAbout,'Label', 'Help',...
    'Separator','on',...
    'Callback',@helpFig);
uimenu(hAbout, 'Label', 'Quit', ...
    'Callback', '''not working''',...
    'Separator','on',...
    'Accelerator','W');

%
if DEV
    guidata(hMain, gd);
    set(hMain, 'HandleVisibility', 'on');
end

set(get(hMain,'Parent'),... %root object
    'DefaultUicontrolFontName', 'Helvetica',...
    'DefaultUicontrolFontSize', 15,...
    'DefaultUicontrolFontUnits', 'pixels',...
    'DefaultUicontrolFontWeight', 'normal',...
    'DefaultUicontrolHorizontalAlignment', 'left');

%% ELEMENTS FOR BOTH ANALYSES

%Buttons to toggle between analyses
uicontrol(hMain, 'Tag', 'hPermToggle',...
    'Style', 'toggle', ...
    'String', 'Blink Inhibition',...
    'FontSize', 18,...
    'Position', [0 H-35, W/2, 35],...
    'Callback', {@cbAnalysisToggle gd 'perm'});

uicontrol(hMain, 'Tag', 'hPsthToggle', ...
    'Style', 'toggle', ...
    'String', 'Peri-Stimulus Time Histogram',...
    'FontSize', 18,...
    'Position', [W/2 H-35 W/2 35],...
    'Callback', {@cbAnalysisToggle gd 'psth'});


%% Axes to plot selected data
axes('Parent',hMain, 'Tag', 'hPlotAxes',...
    'Units', 'pixels', ...
    'FontName', 'Helvetica',...
    'FontSize', 12,...
    'HandleVisibility','callback', ...
    'Position',[50 (H-280) (W-100) 200]);

% context menu for Perm plot
hPermAxesMenu = uicontextmenu('Tag', 'hPermAxesMenu');
uimenu(hPermAxesMenu, 'Label', 'Pop out figure', ...
    'Callback', {@cbPopOutGuiPlot gd});

% context menu for PSTH plot
hPsthAxesMenu = uicontextmenu('Tag', 'hPsthAxesMenu');
uimenu(hPsthAxesMenu, 'Label', 'Pop out figure', ...
    'Callback', {@cbPopOutGuiPlot gd});
hYScroll = uimenu(hPsthAxesMenu, 'Label', 'Scroll y axis');
uimenu(hYScroll, 'Label', 'Up',...
    'Callback', {@cbScrollPsth gd 'up'});
uimenu(hYScroll, 'Label', 'Down',...
    'Callback', {@cbScrollPsth gd 'down'});

hSortBy = uimenu(hPsthAxesMenu, 'Label', 'Sort participants');
uimenu(hSortBy, 'Label', 'Original',...
    'Callback', {@cbScrollPsth gd 'sort_orig'});
uimenu(hSortBy, 'Label', 'Ascending order',...
    'Callback', {@cbScrollPsth gd 'sort_ascend'});
uimenu(hSortBy, 'Label', 'Descending order',...
    'Callback', {@cbScrollPsth gd 'sort_descend'});


% Scroll right/left on x axis (callback set in cbAnalysisToggle)
arrowH = 25;
arrowW = 30;
rArrow = makeArrow(arrowW-10, arrowH-10, 'right',[1,1], [.15,.1,.95], [.95 .95 .95]);
lArrow = makeArrow(arrowW-10, arrowH-10, 'left',[1,1], [.15,.1,.95], [.95 .95 .95]);

uicontrol(hMain, 'Tag', 'hScrollRight',...
    'Style', 'pushbutton',... 
    'CData', rArrow,...
    'Position', [W-(arrowW+7) 445 arrowW arrowH]);

uicontrol(hMain, 'Tag', 'hScrollLeft',...
    'Style', 'pushbutton',...
    'CData', lArrow,...
    'Position', [7 445 arrowW arrowH]);

%% BLINK PERM INPUTS

%MAIN INPUT PANEL
hPermInputPanel = uipanel('Parent', hMain, 'Tag', 'hPermInputPanel',...
             'Title','Inputs',...
             'FontSize', 15,...
             'BackgroundColor', inputPanelColor,...
             'Units', 'pixels',...
             'Position', inputPanelPosition);

%LOAD BLINK CSV LABEL
uicontrol(hPermInputPanel,...
    'Style', 'text',...
    'String','Load Data (.csv file)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 150 250 20],...
    'BackgroundColor', inputPanelColor);

% Button that brings up menu to select a file, + related dialog boxes
uicontrol(hPermInputPanel, 'Tag', 'hLoadBlinkFile',...
    'Style','pushbutton',...
    'String','Raw Blinks',...
    'Units','pixels',...
    'Position',[180 145 95 30],...
    'Callback', {@cbLoadBlinks gd}); 

% NUMBER OF PERMUTATIONS
% Label
uicontrol(hPermInputPanel,...
    'Style','text',...
    'String','Number of Permutations',...
    'FontWeight','bold',...
    'TooltipString', permTip,...
    'Units','pixels',... 
    'Position',[10 85 190 25],...
    'BackgroundColor',inputPanelColor);

% Editable text box where number of permutations is entered
uicontrol(hPermInputPanel, 'Tag', 'hNumPerms',...
    'Style','edit',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[200 87 60 25]);

% RESET INPUTS button
uicontrol(hPermInputPanel, 'Tag', 'hPermReset',...
    'Style','pushbutton',...
    'String','Reset Inputs',...
    'ForegroundColor', 'white',...
    'FontWeight','bold',...
    'Units','pixels',...
    'BackgroundColor',[250 80 80]./256,...
    'Position',[5 5 100 25],...
    'Callback', {@cbResetPerm gd}); 


%% PERMS ADVANCED OPTIONS PANEL
hPermsAdvPanel = uipanel('Parent',hPermInputPanel, 'Tag', 'hPermsAdvPanel',...
            'Title','Advanced Settings (Optional)',...
            'FontSize', 15,...
            'BackgroundColor',inputPanelColor,...
            'Units', 'pixels',...
            'Position',[300, 5, 250, 200]); 

%Label - smoothing parameter
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Smoothing (Gaussian kernel)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 145 230 25],...
    'BackgroundColor', inputPanelColor);

%W VALUE

%Label - W range
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Bandwidth range ',...
    'TooltipString', wTip,...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 115 120 25],...
    'BackgroundColor', inputPanelColor);

%Edit W range
uicontrol(hPermsAdvPanel, 'Tag', 'hWRange',...
    'Style', 'edit',...
    'String','',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[155 117 70 25]);


%SIGNIFICANCE THRESHOLDS
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Significance Thresholds',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 80 230 20],...
    'BackgroundColor', inputPanelColor);
    
%Label - low significance threshold
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Lower ',...
    'TooltipString', sigTip,...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 45 45 25],...
    'BackgroundColor', inputPanelColor);

%Edit low significance threshold
uicontrol(hPermsAdvPanel, 'Tag', 'hSigLowPerm',...
    'Style', 'edit',...
    'String','2.5',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[77 47 45 25],...
    'BackgroundColor','white');

%Label - high significance threshold
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Upper ',...
    'TooltipString', sigTip,...
    'HorizontalAlignment', 'right',...
    'Units','pixels',...
    'Position',[130 45 45 25],...
    'BackgroundColor',inputPanelColor);
 
%Edit high significance threshold
uicontrol(hPermsAdvPanel, 'Tag', 'hSigHighPerm',...
    'Style', 'edit',...
    'String','97.5',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[180 47 45 25],...
    'BackgroundColor','white');

%CONSECUTIVE FRAMES THRESHOLD
%Label - # of consecutive frames for significance
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Consecutive samples ',...
    'HorizontalAlignment', 'left',... 
    'Units','pixels',...
    'Position',[30 10 155 25],...
    'BackgroundColor',inputPanelColor);

%Edit # of consecutive frames for significance
uicontrol(hPermsAdvPanel, 'Tag', 'hSigFrames',...
    'Style', 'edit',...
    'String', '1',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[180 12 45 25],...
    'BackgroundColor','white');
    


%% BLINK PSTH ITEMS

%MAIN INPUT PANEL
hPsthInputPanel = uipanel('Parent',hMain, 'Tag', 'hPsthInputPanel',...
             'Title','Inputs',...
             'FontSize', 15,...
             'BackgroundColor',inputPanelColor,...
             'Units', 'pixels',...
             'Position', inputPanelPosition,...
             'Visible','off');

%LOAD DATA LABEL
uicontrol(hPsthInputPanel,...
    'Style', 'text',...
    'String','Load Data (.csv files)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 175 250 20],...
    'BackgroundColor', inputPanelColor);


% LOAD TARGET EVENTS
% Button that brings up menu to select a file, + related dialog boxes
uicontrol(hPsthInputPanel, 'Tag', 'hLoadTargetEvents',...
    'Style','pushbutton',...
    'String','Target Events',...
    'Units','pixels',...
    'Position',[14 140 120 30],...
    'Callback', {@cbLoadTargetData gd}); 

%LOAD REFERENCE EVENTS
% Button that brings up menu to select a file, + related dialog boxes
uicontrol(hPsthInputPanel, 'Tag', 'hLoadRefEvents',...
    'Style','pushbutton',...
    'String','Reference Events',...
    'Units','pixels',...
    'Position',[145 140 140 30],...
    'Callback', {@cbLoadRefData gd}); 
         
%LAG SIZE
uicontrol(hPsthInputPanel,...
    'Style', 'text',...
    'String','Window Size (# of samples)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 110 250 20],...
    'BackgroundColor', inputPanelColor);
    
%Label - Before
uicontrol(hPsthInputPanel,...
    'Style', 'text',...
    'String','Before event ',...
    'HorizontalAlignment', 'right',...
    'Units','pixels',...
    'Position',[14 75 95 25],...
    'BackgroundColor', inputPanelColor);

%Label - After
uicontrol(hPsthInputPanel,...
    'Style', 'text',...
    'String','After event ',...
    'HorizontalAlignment', 'right',...
    'Units','pixels',...
    'Position',[140 75 95 25],...
    'BackgroundColor',inputPanelColor);

%Edit window size before event
uicontrol(hPsthInputPanel,  'Tag', 'hLagBefore',...
    'Style', 'edit',...
    'String','',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[115 77 35 25],...
    'BackgroundColor','white');

%Edit window size after event
uicontrol(hPsthInputPanel, 'Tag', 'hLagAfter',...
    'Style', 'edit',...
    'String','',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[241 77 35 25],...
    'BackgroundColor','white');


% NUMBER OF PERMUTATIONS
% Label
uicontrol(hPsthInputPanel,...
    'Style','text',...
    'String','Number of Permutations',...
    'FontWeight','bold',...
    'TooltipString', permTip,...
    'Units','pixels',... 
    'Position',[10 35 190 25],...
    'BackgroundColor',inputPanelColor);

% Editable text box where number of permutations is entered
uicontrol(hPsthInputPanel, 'Tag', 'hNumPermsPsth',...
    'Style','edit',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[200 37 60 25]);


% RESET INPUTS button
uicontrol(hPsthInputPanel, 'Tag', 'hPsthReset',...
    'Style','pushbutton',...
    'String','Reset Inputs',...
    'ForegroundColor', 'white',...
    'FontWeight','bold',...
    'Units','pixels',...
    'BackgroundColor',[250 80 80]./256,...
    'Position',[5 5 100 25],...
    'Callback', {@cbResetPsth gd}); 
         
%% PSTH ADVANCED OPTIONS PANEL
hPsthAdvPanel = uipanel('Parent',hPsthInputPanel, 'Tag', 'hPsthAdvPanel',...
            'Title','Advanced Settings (Optional)',...
            'FontSize', 15,...
            'BackgroundColor',inputPanelColor,...
            'Units', 'pixels',...
            'Position',[300, 5, 250, 200]); 

%PSTH settings
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','PSTH Settings',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 150 120 25],...
    'BackgroundColor', inputPanelColor);

%label for start frame
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Sample start',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 120 150 25],...
    'BackgroundColor', inputPanelColor);

%Edit start frame
uicontrol(hPsthAdvPanel, 'Tag', 'hStartFrameEdit',...
    'Style', 'edit',...
    'String','1',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[180 122 45 25]);

%INCLUDE THRESHOLD
%label
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Include threshold',...
    'TooltipString', incThrTip,...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 85 150 25],...
    'BackgroundColor', inputPanelColor);

%Edit include threshold
uicontrol(hPsthAdvPanel, 'Tag', 'hInclThreshEdit',...
    'Style', 'edit',...
    'String','0.2',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[180 87 45 25]);

%SIGNIFICANCE THRESHOLDS
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Significance Thresholds',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 50 230 20],...
    'BackgroundColor', inputPanelColor);
    
%Label - low significance threshold
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Lower ',...
    'TooltipString', sigTip,...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 15 45 25],...
    'BackgroundColor', inputPanelColor);

%Edit low significance threshold
uicontrol(hPsthAdvPanel, 'Tag', 'hSigLowPsth',...
    'Style', 'edit',...
    'String','2.5',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[77 17 45 25],...
    'BackgroundColor','white');

%Label - high significance threshold
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Upper ',...
    'TooltipString', sigTip,...
    'HorizontalAlignment', 'right',...
    'Units','pixels',...
    'Position',[130 15 45 25],...
    'BackgroundColor',inputPanelColor);
 
%Edit high significance threshold
uicontrol(hPsthAdvPanel, 'Tag', 'hSigHighPsth',...
    'Style', 'edit',...
    'String','97.5',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[180 17 45 25],...
    'BackgroundColor','white');


%% OUTPUT PANEL (both analyses)
hOutputPanel = uipanel('Parent',hMain,...
     'Title','Outputs',...
     'FontSize', 15,...
     'BackgroundColor',bkgdColor,...
     'Units','pixels',...
     'Position',[10, 55, (W-20), 140]);

%Label for checkboxes
uicontrol(hOutputPanel,...
    'Style', 'text',...
    'String', 'Files to save',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', bkgdColor,...
    'Units', 'pixels',...
    'Position', [10 85 100 25]);

%check box - save summary
uicontrol(hOutputPanel,...
    'Style', 'checkbox',...
    'String', 'Summary csv',...
    'BackgroundColor', bkgdColor,...
    'Value', 1,...
    'Units', 'pixels',...
    'Position', [120 85 120 30],...
    'Callback', {@cbCheckSaveCsv gd});

%check box - save figures
uicontrol(hOutputPanel,...
    'Style', 'checkbox',...
    'string', 'Figures',...
    'BackgroundColor', bkgdColor,...
    'Value', 1,...
    'Units', 'pixels',...
    'Position', [260 85 80 30],...
    'Callback', {@cbCheckSaveFigs gd});

%dropdown - figure format
hFigFormat = uicontrol(hOutputPanel, 'Tag', 'hFigFormat',...
    'Style', 'popup',...
    'String', 'jpg|pdf|eps|fig|png|tif',...
    'Position', [335 82 80 30],...
    'Callback', {@cbChooseFigFormat gd});

%check box - save mat file
uicontrol(hOutputPanel,...
    'Style', 'checkbox',...
    'string', '.mat file',...
    'BackgroundColor', bkgdColor,...
    'Value', 1,...
    'Units', 'pixels',...
    'Position', [430 85 100 30],...
    'Callback', {@cbCheckSaveMat gd});

         
%PREFIX FOR OUTPUT FILES
%Label for edit box where output prefix can be entered
uicontrol(hOutputPanel,...
    'Style','text',...
    'Units','pixels',...
    'Position',[10 50 160 25],...
    'FontWeight','bold',...
    'String','Prefix for output files',...
    'BackgroundColor',bkgdColor);

%Editable text box where output filename is entered
uicontrol(hOutputPanel, 'Tag', 'hOutputFile',...
    'Style','edit',...
    'String','',...
    'HorizontalAlignment','center',...
    'BackgroundColor', 'white',...
    'Units','pixels',...
    'Position',[175 50 200 30]);

%OUTPUT DIRECTORY
%pushbutton
uicontrol(hOutputPanel, 'Tag', 'hChooseOutputDir',...
    'Style','pushbutton',...
    'String','Output directory',...
    'Units','pixels',...
    'Position',[8 10 140 30],...
    'Callback', {@cbChooseOutputDir gd});

% Label where output directory is displayed
uicontrol(hOutputPanel, 'Tag', 'hListOutputFile',...
    'Style','text',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[175 15 370 20],...
    'String','no directory selected',...
    'FontAngle','italic');


%% ANALYZE BUTTON
%Button to run the analysis
uicontrol(hMain, 'Tag', 'hGoButton',...
    'Style','pushbutton',...
    'String','Run Analysis',...
    'FontWeight','bold',...
    'BackgroundColor', buttonColor,...
    'Units','pixels',...
    'Position',[(W/2-60) 15 120 30],...
    'FontSize',16);

%% Final steps to initialize

% Create handles structure in GUIDATA
gd.setHandles(hMain);

% Set default analysis ('perm' or 'psth')
cbAnalysisToggle([],[], gd, 'perm');

% Set default figure format
cbChooseFigFormat(hFigFormat, [], gd);

% Make GUI visible
drawnow
set(hMain,'Visible', 'on');

%% Callback functions (only called from GUI)

% Pop out whatever is plotted in the embedded axis
function cbPopOutGuiPlot(~, ~, gd)
    try
        h = figure('Position', [50 50 800 400]);
        a = copyobj(gd.handles.hPlotAxes, h);
        set(a, 'units','normalized',...
            'OuterPosition', [0 0 1 1]); % resizes! 
    
    catch ME
        err = MException('BlinkGUI:unknown', 'Unknown error');
        err = addCause(err, ME);
        gui_error(err, gd.guiSettings.error_log);
    end
end

% Reset perm inputs
function cbResetPerm(~, ~, gd)
    try
        %reset perm inputs in guidata
        gd.resetPerm();

        % clear plot
        cla(gd.handles.hPlotAxes, 'reset');

        %reset inputs (hardcoded)
        set(gd.handles.hNumPerms, 'String', '');
        set(gd.handles.hWRange, 'String', '');
        set(gd.handles.hSigLowPerm, 'String', '2.5');
        set(gd.handles.hSigHighPerm, 'String', '97.5');
        set(gd.handles.hSigFrames, 'String', '1');
    
    catch ME
        err = MException('BlinkGUI:unknown', 'Unknown error');
        err = addCause(err, ME);
        gui_error(err, gd.guiSettings.error_log);
    end
end

% Rest psth inputs
function cbResetPsth(~, ~, gd)
    try
        %reset PSTH inputs in guidata
        gd.resetPsth();

        % clear plot
        cla(gd.handles.hPlotAxes, 'reset');

        % reset inputs (hardcoded)
        set(gd.handles.hLagBefore, 'String', '');
        set(gd.handles.hLagAfter, 'String', '');
        set(gd.handles.hNumPermsPsth, 'String', '');
        set(gd.handles.hStartFrameEdit, 'String', '1');
        set(gd.handles.hInclThreshEdit, 'String', '0.2');
        set(gd.handles.hSigLowPsth, 'String', '2.5');
        set(gd.handles.hSigHighPsth, 'String', '97.5');
    
    catch ME
        err = MException('BlinkGUI:unknown', 'Unknown error');
        err = addCause(err, ME);
        gui_error(err, gd.guiSettings.error_log);
    end
end

% What to do on closing
function cbCloseGUI(hObj, ~, gd)
    if ~isempty(gd.handles.hWaitBar)
        delete(gd.handles.hWaitBar);
    end
    
    %delete guidata and hobj
    delete(gd);
    delete(hObj);
end

end