function blinkGUI()

% Add inputs:
%   include threshold (psth advanced)
%   actaully get figure format from pop up

% > have multiple analysis types available in one GUI, and change input
%       fields according to the analysis type (uitoggletool?)
% > output useful error messages from all subfunctions
% > reset anything when new file is loaded?
% > have a window with version info, my name, website, etc.
% > help documentation --> send to website, contact info
% > uimenu, uitoolbar --> have different menus and toolbars?
% > windows path joining... will need to change some hard-coded things
% > logging: how to set a location for log file?
% > specs file? 
% > what to do upon closing the figure? (fclose all, etc)
% > figure out resizing
% > change all "frame" to "sample #" ?

% position dialog boxes in the middle of the GUI
% position the figures next to the GUI?

% something is going wrong with the plotting of blink permutation results

% warnings about no significant blink inhibition (permutation test at
% floor) -- from GUI and in summary file?

% NOTE: input specs have changed slightly: subjects should each have a
% column, and frames should be in rows (better for excel limits).
    % think about excel limits when considering how much data to accept --
    % 1/2 many rows - a few, max of how many subjects?

% > Make it so that can't switch between analyses while it's running!!

%GUIDATA
% > pass in handles to every callback? may be better than getting guidata for
% each
% > make guidata a class? - what happens if a field doesn't exist??
% Use GUIDATA consistently within each function: break vars out into local variables, but don't
% bother to break out handles (because they aren't changing...)


%% Initialize GUIDATA - TODO switch over from using persistent variables

GUIDATA = BlinkGuiData; %class containing a bunch of settings (defaults set in class files)

% GUIDATA = struct();
% 
% %Settings
% GUIDATA.guiSettings.maxPerms = 10000;
% GUIDATA.guiSettings.error_log = '/Users/etl/Desktop/GitCode/blink-web/analysis/testing/blinkGUI_log.txt';
% 
% % From output panel
% GUIDATA.output.dir = '';
% GUIDATA.output.saveCsv = 1;
% GUIDATA.output.saveMat = 1;
% GUIDATA.output.saveFigs = 1;
% GUIDATA.output.figFormat = '';
% 
% % for blinkPerm
% GUIDATA.blinkPermInputs.rawBlinks = [];
% GUIDATA.blinkPermInputs.sampleRate = [];
% GUIDATA.blinkPermInputs.plotTitle = {};
% 
% % for blinkPSTH
% GUIDATA.blinkPsthInputs.targetEvents = {};
% GUIDATA.blinkPsthInputs.refEvents = {};
% GUIDATA.blinkPsthInputs.startFrame = 1;
% % target/ref event information:
% GUIDATA.blinkPsthInputs.targetCode = [];
% GUIDATA.blinkPsthInputs.targetEventType = '';
% GUIDATA.blinkPsthInputs.refCode = [];
% GUIDATA.blinkPsthInputs.refEventType = '';

%% GUI

%MAIN FIGURE
%Parent figure width and height
W=580;
H=740;

inputPanelPosition = [10, 200, (W-20), 230];

%Color settings
bkgdColor = [215 230 235] ./256;
inputPanelColor = bkgdColor; % [230 230 230] ./256;
buttonColor = [180 250 150] ./ 256;

hMain = figure(...
    'units','pixels',...
    'position',[100 100 W H],...
    'MenuBar', 'none',...
    'Toolbar','none',...
    'HandleVisibility','callback',...
    'numbertitle','off',...
    'name', 'Blink Analyses',...
    'resize', 'off',...
    'Color',bkgdColor,...
    'CloseRequestFcn',@CloseGUI,...
    'Visible', 'off');

set(hMain,...
    'DefaultUicontrolFontName', 'Helvetica',... DefaultUicontrolFontName?
    'DefaultUicontrolFontSize', 15,...
    'DefaultUicontrolFontUnits', 'pixels',...
    'DefaultUicontrolHorizontalAlignment', 'left');

%Can I set defaults for input/warning/error dialogs?


%% ELEMENTS FOR BOTH ANALYSES

%Buttons to toggle between analyses
uicontrol(hMain, 'Tag', 'hPermToggle',...
    'Style', 'toggle', ...
    'String', 'Blink Modulation',...
    'FontSize', 18,...
    'Position', [0 H-35, W/2, 35],...
    'Callback', {@AnalysisToggle 'perm'});

uicontrol(hMain, 'Tag', 'hPsthToggle', ...
    'Style', 'toggle', ...
    'String', 'Peri-stimulus time histogram',...
    'FontSize', 18,...
    'Position', [W/2 H-35 W/2 35],...
    'Callback', {@AnalysisToggle 'psth'});

% Axes to plot selected data
axes('Parent',hMain, 'Tag', 'hPlotAxes',...
    'Units', 'pixels', ...
    'HandleVisibility','callback', ...
    'Position',[50 (H-280) (W-100) 200]);

% Button to pop out figure
% TODO - fix this/make it a button press in axis
uicontrol(hMain,...
    'Style', 'pushbutton',...
    'String', 'pop',...
    'Position', [W-50 630 40 40],...
    'Callback', @PopOutGuiPlot);


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
    'String','Load data (.csv file)',...
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
    'Position',[160 145 95 30],...
    'Callback',@LoadBlinks); 

% NUMBER OF PERMUTATIONS
% Label
uicontrol(hPermInputPanel,...
    'Style','text',...
    'String','Number of Permutations:',...
    'FontWeight','bold',...
    'Units','pixels',... 
    'Position',[10 70 190 25],...
    'BackgroundColor',inputPanelColor);

% Editable text box where number of permutations is entered
uicontrol(hPermInputPanel, 'Tag', 'hNumPerms',...
    'Style','edit',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[200 72 70 25]);


%% PERMS ADVANCED OPTIONS PANEL
hPermsAdvPanel = uipanel('Parent',hPermInputPanel, 'Tag', 'hPermsAdvPanel',...
            'Title','Advanced Options',...
            'FontSize', 15,...
            'BackgroundColor',inputPanelColor,...
            'Units', 'pixels',...
            'Position',[300, 10, 250, 200]); 

%W VALUE
%Label - smoothing parameter
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Smoothing (Gaussian kernel)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 150 230 25],...
    'BackgroundColor', inputPanelColor);

%Label - W range
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','W Range ',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 120 80 25],...
    'BackgroundColor', inputPanelColor);

%Edit W range
uicontrol(hPermsAdvPanel, 'Tag', 'hWRange',...
    'Style', 'edit',...
    'String','',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[100 122 80 25]);


%SIGNIFICANCE THRESHOLDS
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Significance thresholds (0 - 100)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 45 230 20],...
    'BackgroundColor', inputPanelColor);
    
%Label - low significance threshold
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','Low ',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 15 35 25],...
    'BackgroundColor', inputPanelColor);

%Edit low significance threshold
uicontrol(hPermsAdvPanel, 'Tag', 'hSigLowPerm',...
    'Style', 'edit',...
    'String','2.5',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[67 17 40 25],...
    'BackgroundColor','white');

%Label - high significance threshold
uicontrol(hPermsAdvPanel,...
    'Style', 'text',...
    'String','High ',...
    'HorizontalAlignment', 'right',...
    'Units','pixels',...
    'Position',[130 15 35 25],...
    'BackgroundColor',inputPanelColor);
 
%Edit high significance threshold
uicontrol(hPermsAdvPanel, 'Tag', 'hSigHighPerm',...
    'Style', 'edit',...
    'String','97.5',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[170 17 40 25],...
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
    'String','Load data (.csv files)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 180 250 20],...
    'BackgroundColor', inputPanelColor);


% LOAD TARGET EVENTS
% Button that brings up menu to select a file, + related dialog boxes
uicontrol(hPsthInputPanel, 'Tag', 'hLoadTargetEvents',...
    'Style','pushbutton',...
    'String','Target Events',...
    'Units','pixels',...
    'Position',[14 150 120 30],...
    'Callback',@LoadTargetData); 

%LOAD REFERENCE EVENTS
% Button that brings up menu to select a file, + related dialog boxes
uicontrol(hPsthInputPanel, 'Tag', 'hLoadRefEvents',...
    'Style','pushbutton',...
    'String','Reference Events',...
    'Units','pixels',...
    'Position',[139 150 130 30],...
    'Callback',@LoadRefData); 
         
%LAG SIZE
uicontrol(hPsthInputPanel,...
    'Style', 'text',...
    'String','Window Size (# samples)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 100 250 20],...
    'BackgroundColor', inputPanelColor);
    
%Label - Before
uicontrol(hPsthInputPanel,...
    'Style', 'text',...
    'String','Before event ',...
    'HorizontalAlignment', 'right',...
    'Units','pixels',...
    'Position',[14 65 95 25],...
    'BackgroundColor', inputPanelColor);

%Label - After
uicontrol(hPsthInputPanel,...
    'Style', 'text',...
    'String','After event ',...
    'HorizontalAlignment', 'right',...
    'Units','pixels',...
    'Position',[140 65 95 25],...
    'BackgroundColor',inputPanelColor);

%Edit window size before event
uicontrol(hPsthInputPanel,  'Tag', 'hLagBefore',...
    'Style', 'edit',...
    'String','',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[115 67 30 25],...
    'BackgroundColor','white');

%Edit window size after event
uicontrol(hPsthInputPanel, 'Tag', 'hLagAfter',...
    'Style', 'edit',...
    'String','',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[241 67 30 25],...
    'BackgroundColor','white');


% NUMBER OF PERMUTATIONS
% Label
uicontrol(hPsthInputPanel,...
    'Style','text',...
    'Units','pixels',... 
    'Position',[10 15 190 25],...
    'FontWeight','bold',...
    'String','Number of Permutations:',...
    'BackgroundColor',inputPanelColor);

% Editable text box where number of permutations is entered
uicontrol(hPsthInputPanel, 'Tag', 'hNumPermsPsth',...
    'Style','edit',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[200 17 70 25]);

         
%% PSTH ADVANCED OPTIONS PANEL
hPsthAdvPanel = uipanel('Parent',hPsthInputPanel, 'Tag', 'hPsthAdvPanel',...
            'Title','Advanced Options',...
            'FontSize', 15,...
            'BackgroundColor',inputPanelColor,...
            'Units', 'pixels',...
            'Position',[300, 10, 250, 200]); 

%PSTH settings
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','PSTH settings',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 150 120 25],...
    'BackgroundColor', inputPanelColor);

%label for start frame
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Start frame',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 120 100 25],...
    'BackgroundColor', inputPanelColor);

%Edit start frame
uicontrol(hPsthAdvPanel, 'Tag', 'hStartFrameEdit',...
    'Style', 'edit',...
    'String','',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[115 122 45 25]);

%label for include threshold
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Include threshold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 85 150 25],...
    'BackgroundColor', inputPanelColor);

%Edit include threshold
uicontrol(hPsthAdvPanel, 'Tag', 'hInclThreshEdit',...
    'Style', 'edit',...
    'String','',...
    'HorizontalAlignment', 'center',...
    'BackgroundColor','white',...
    'Units','pixels',...
    'Position',[150 87 45 25]);


%SIGNIFICANCE THRESHOLDS
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Significance thresholds (0 - 100)',...
    'FontWeight', 'bold',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[10 45 230 20],...
    'BackgroundColor', inputPanelColor);
    
%Label - low significance threshold
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','Low ',...
    'HorizontalAlignment', 'left',...
    'Units','pixels',...
    'Position',[30 15 35 25],...
    'BackgroundColor', inputPanelColor);

%Edit low significance threshold
uicontrol(hPsthAdvPanel, 'Tag', 'hSigLowPsth',...
    'Style', 'edit',...
    'String','2.5',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[67 17 40 25],...
    'BackgroundColor','white');

%Label - high significance threshold
uicontrol(hPsthAdvPanel,...
    'Style', 'text',...
    'String','High ',...
    'HorizontalAlignment', 'right',...
    'Units','pixels',...
    'Position',[130 15 35 25],...
    'BackgroundColor',inputPanelColor);
 
%Edit high significance threshold
uicontrol(hPsthAdvPanel, 'Tag', 'hSigHighPsth',...
    'Style', 'edit',...
    'String','97.5',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[170 17 40 25],...
    'BackgroundColor','white');


%% OUTPUT PANEL
hOutputPanel = uipanel('Parent',hMain,...
     'Title','Outputs',...
     'FontSize', 15,...
     'BackgroundColor',bkgdColor,...
     'Units','pixels',...
     'Position',[10, 55, (W-20), 140]);

%Label for checkboxes
uicontrol(hOutputPanel,...
    'Style', 'text',...
    'String', 'Files to save:',...
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
    'Callback',@CheckSaveCsv);

%check box - save figures
uicontrol(hOutputPanel,...
    'Style', 'checkbox',...
    'string', 'Figures',...
    'BackgroundColor', bkgdColor,...
    'Value', 1,...
    'Units', 'pixels',...
    'Position', [260 85 80 30],...
    'Callback',@CheckSaveFigs);

hFigFormat = uicontrol(hOutputPanel, 'Tag', 'hFigFormat',...
    'Style', 'popup',...
    'String', 'jpg|pdf|eps|fig|png|tif|bmp',...
    'Position', [335 82 80 30],...
    'Callback', @ChooseFigFormat);

%check box - save mat file
uicontrol(hOutputPanel,...
    'Style', 'checkbox',...
    'string', '.mat file',...
    'BackgroundColor', bkgdColor,...
    'Value', 1,...
    'Units', 'pixels',...
    'Position', [430 85 100 30],...
    'Callback', @CheckSaveMat);

         
%TYPE NAME OF OUTPUT FILE - TODO change to file prefix in code
%Label for edit box where output filename can be entered
uicontrol(hOutputPanel,...
    'Style','text',...
    'Units','pixels',...
    'Position',[10 50 160 25],...
    'FontWeight','bold',...
    'String','Prefix for output files:',...
    'BackgroundColor',bkgdColor);

%Editable text box where output filename is entered
uicontrol(hOutputPanel, 'Tag', 'hOutputFile',...
    'Style','edit',...
    'String','',...
    'HorizontalAlignment','center',...
    'BackgroundColor', 'white',...
    'Units','pixels',...
    'Position',[210 50 200 30]);

%Output directory
uicontrol(hOutputPanel, 'Tag', 'hChooseOutputDir',...
    'Style','pushbutton',...
    'String','Choose output directory',...
    'Units','pixels',...
    'Position',[10 10 180 30],...
    'Callback', @ChooseOutputDir);

% Label where output directory is displayed
uicontrol(hOutputPanel, 'Tag', 'hListOutputFile',...
    'Style','text',...
    'HorizontalAlignment', 'center',...
    'Units','pixels',...
    'Position',[210 15 320 20],...
    'String','none selected',...
    'FontAngle','italic');


%% ANALYZE BUTTON
%Button to run the analysis
hGoButton = uicontrol(hMain, 'Tag', 'hGoButton',...
    'Style','pushbutton',...
    'String','Run Analysis',...
    'FontWeight','bold',...
    'BackgroundColor', buttonColor,...
    'Units','pixels',...
    'Position',[(W/2-60) 15 120 30],...
    'FontSize',16);

%% Create handles structure and save it to GUIDATA

GUIDATA.setHandles(hMain); % creates handles structure + placeholder for a progress bar
% GUIDATA.handles = guihandles(hMain);
% GUIDATA.handles.hWaitBar = []; %add a placeholder for progress bar
guidata(hMain, GUIDATA);

%% Initialize: 

%SET DEFAULT ANALYSIS - 'perm' or 'psth'
AnalysisToggle(hGoButton,[],'perm');
%SET DEFAULT FIG FORMAT
ChooseFigFormat(hFigFormat);

%Make GUI visible
set(hMain,'Visible', 'on');

%% Utility functions

%join a directory and a filename -- TODO look at how other systems
%define pathnames. May want this in a separate file, actually
function fullpath = dirFileJoin(dirname, filename)
    if strcmp(dirname(end),'/')
        fullpath = [dirname,filename];
    else
        fullpath = [dirname,'/',filename];
    end
end

%create an error dialogue window, and log the error if there is a log file 
function gui_error(hObj,ME)
    
    gd = guidata(hObj);
    error_log = gd.guiSettings.error_log;
    
    w = errordlg(ME.message, 'Error', 'modal');
    
    fid = fopen(error_log,'a');
    if fid<=0
        warndlg('Error log file not found!')
    else
        fprintf(fid,'%s\t',datestr(now));
        fprintf(fid,'%s\n',ME.message);
        
        %PRINT THE STACK
        if ~isempty(ME.cause) %if there is a cause, print that stack
            stack = ME.cause{1}.stack;
            fprintf(fid,'Cause:\t%s\n',ME.cause{1}.message);
        else %otherwise, the stack from the exception
            stack = ME.stack;
        end
     
        for i = 1:length(stack)
            fprintf(fid, '\tLine %i\t%s\t%s\n', stack(i).line, stack(i).name, stack(i).file);
        end
        
        fprintf(fid,'\n');
        fclose(fid);
    end
    
    %wait for the user to close the error
    uiwait(w);
end

function toggleBigButtons(handles, setting)
   switch lower(setting)
       case 'disable'
           set(handles.hGoButton, 'Enable', 'inactive');
           set(handles.hPermToggle, 'Enable', 'inactive');
           set(handles.hPsthToggle, 'Enable', 'inactive');
       case 'enable'
           set(handles.hGoButton, 'Enable', 'on');
           set(handles.hPermToggle, 'Enable', 'on');
           set(handles.hPsthToggle, 'Enable', 'on');
   end
end


%% Callback functions: BOTH ANALYSES

%for the toggle buttons
function AnalysisToggle(hObj, ~, name)
    gd = guidata(hObj);
    
    %color settings
    toggleOnColor = 'black'; %[175 0 0] ./256;
    toggleOffColor = [120 120 120] ./256;
    
    
    % Permutation testing ON
    if strcmpi(name, 'perm')
        
        %set perm toggle on, psth toggle off
        set(gd.handles.hPermToggle, 'Value', 1,...
            'FontWeight', 'bold',...
            'ForegroundColor', toggleOnColor);
        set(gd.handles.hPsthToggle, 'Value', 0, ...
            'FontWeight', 'normal',...
            'ForegroundColor', toggleOffColor);
        
        %Toggle the panels
        set(gd.handles.hPermInputPanel, 'Visible', 'on');
        set(gd.handles.hPsthInputPanel, 'Visible', 'off');
        
        %set button callback
        set(gd.handles.hGoButton, 'Callback', @RunBlinkPerm);
        
        %Plot data if it exists 
        cla(gd.handles.hPlotAxes, 'reset');
        if ~isempty(gd.blinkPermInputs.rawBlinks) && ~isempty(gd.blinkPermInputs.sampleRate)
           plotInstBR(gd.blinkPermInputs.rawBlinks, gd.blinkPermInputs.sampleRate, gd.handles.hPlotAxes, gd.blinkPermInputs.plotTitle);
        end
        
    % PSTH ON
    elseif strcmpi(name, 'psth')
        %set perm toggle on, psth toggle off
        set(gd.handles.hPsthToggle, 'Value', 1,...
            'FontWeight', 'bold',...
            'ForegroundColor', toggleOnColor);
        set(gd.handles.hPermToggle, 'Value', 0, ...
            'FontWeight', 'normal',...
            'ForegroundColor', toggleOffColor);
        
        %Toggle the panels
        set(gd.handles.hPsthInputPanel, 'Visible', 'on');
        set(gd.handles.hPermInputPanel, 'Visible', 'off');
        
        %set button callback
        set(gd.handles.hGoButton, 'Callback', @RunBlinkPSTH);
        
        %Plot data if it exists 
        cla(gd.handles.hPlotAxes, 'reset');
        if ~isempty(gd.blinkPsthInputs.targetEvents) || ~isempty(gd.blinkPsthInputs.refEvents)
           %TODO plot the data 
        end
        
    end

end

%pop out whatever is plotted in the GUI 
%TODO - need to make this resizable somehow
function PopOutGuiPlot(hObj, varargin)
    gd = guidata(hObj);
    %TODO - fix positioning
    h = figure('Position', [50 50 800 400]);
    a = copyobj(gd.handles.hPlotAxes, h);
    set(a, 'Position', [50 50 710 300]);
end

%choose output directory
function ChooseOutputDir(hObj, varargin)
    gd = guidata(hObj);
    
    outputDir = uigetdir('','Choose a folder where results will be saved');
    if outputDir ~= 0
        set(gd.handles.hListOutputFile,'String',outputDir,...
            'FontAngle','normal');
        
        ex = get(gd.handles.hListOutputFile, 'Extent');
        pos = get(gd.handles.hListOutputFile, 'Position');
        
        if ex(3) > pos(3)
            set(gd.handles.hListOutputFile, 'String', ['...', outputDir((end-40):end)]);
        end
        
        %save new output dir to guidata
        gd.output.dir = outputDir;
        guidata(hObj, gd);
    end
    
end

%check box: save csv file
function CheckSaveCsv(hObj,varargin)
    
    gd = guidata(hObj);
    gd.output.saveCsv = get(hObj,'Value');
    
    if gd.output.saveCsv || gd.output.saveFigs || gd.output.saveMat
        set(gd.handles.hOutputFile, 'Enable', 'on');
        set(gd.handles.hChooseOutputDir, 'Enable', 'on');
    else
        set(gd.handles.hOutputFile, 'Enable', 'off');
        set(gd.handles.hChooseOutputDir, 'Enable', 'off');
    end
    
    guidata(hObj, gd);
end

%check box: save figures
function CheckSaveFigs(hObj,varargin)
    
    gd = guidata(hObj);
    gd.output.saveFigs = get(hObj,'Value');
    
    if gd.output.saveFigs
       set(gd.handles.hFigFormat, 'Enable', 'on');
    else
       set(gd.handles.hFigFormat, 'Enable', 'off');
    end
    
    if gd.output.saveCsv || gd.output.saveFigs || gd.output.saveMat
        set(gd.handles.hOutputFile, 'Enable', 'on');
        set(gd.handles.hChooseOutputDir, 'Enable', 'on');
    else
        set(gd.handles.hOutputFile, 'Enable', 'off');
        set(gd.handles.hChooseOutputDir, 'Enable', 'off');
    end
    
    guidata(hObj, gd);
end

%check box: save mat file
function CheckSaveMat(hObj,varargin)
    
    gd = guidata(hObj);
    gd.output.saveMat = get(hObj,'Value');
    
    if gd.output.saveCsv || gd.output.saveFigs || gd.output.saveMat
        set(gd.handles.hOutputFile, 'Enable', 'on');
        set(gd.handles.hChooseOutputDir, 'Enable', 'on');
    else
        set(gd.handles.hOutputFile, 'Enable', 'off');
        set(gd.handles.hChooseOutputDir, 'Enable', 'off');
    end
    
    guidata(hObj, gd);
end

function ChooseFigFormat(hObj, varargin)
    %'jpg|pdf|eps|fig|png|tif|bmp'
    
    switch get(hObj, 'Value')
        case 1
            figf = 'jpg';
        case 2 
            figf = 'pdf';
        case 3
            figf = 'eps';
        case 4
            figf = 'fig';
        case 5
            figf = 'png';
        case 6
            figf = 'tif';
        case 7
            figf = 'bmp';
        otherwise
            figf = [];
    end
    
    %save fig format in guidata
    gd = guidata(hObj);
    gd.output.figFormat = figf;
    guidata(hObj, gd);
end


%% BLINK PERM
function LoadBlinks(hObj, varargin)
    gd = guidata(hObj);
    
    
    %choose file dialog box: 
    [input_file, PathName] = uigetfile('*.csv','Choose a csv file with blink data');
    if input_file == 0
        return
    end
    input_file_full = dirFileJoin(PathName, input_file);

    %Dialog box: get file type before loading file
    options = {'Binary blink matrix','BinaryMat';
                'Three column format','3col'};
    [formatType, value] = twoRadioDlg(options);
    
    %if user cancels
    if value==0
        return
    end
    
    %Get data length if format is 3col
    if strcmpi(formatType,'3col')
        prompt = {'Enter data length:'};
        dlg_title = '3 Column Format';
        num_lines = 1;
        answer = inputdlg(prompt,dlg_title, num_lines);
        
        %if user cancels or doesn't enter anything
        if isempty(answer)
            return
        end

        sampleLen = str2double(answer{1});
        if isnan(sampleLen) || sampleLen<=0 
            errordlg('Data length must be a positive number.');
            return
        end
        
    elseif strcmpi(formatType,'BinaryMat')
        sampleLen = NaN;
    end
    
    %Get sample rate
    prompt = {'Enter sample rate (frames/sec):'};
    dlg_title = 'Sample Rate';
    num_lines = 1;
    answer = inputdlg(prompt,dlg_title, num_lines);
    
    %if user cancels or doesn't enter anything
    if isempty(answer)
        return
    end

    sampleRate = str2double(answer{1});
    if isnan(sampleRate) || sampleRate<=0
        errordlg('Sample rate must be a positive number.');
        return
    end

    % Read in file
    try
        rawBlinks = readInBlinks(input_file_full, formatType, sampleLen);
    catch ME
        gui_error(hObj,ME);
        return
    end
    
    %Plot instantaneous blink rate - sample rate and input file name are in the title
    try
        cla(gd.handles.hPlotAxes,'reset');
        plotTitle = {input_file, sprintf('Sample rate: %.2f',sampleRate)};
        plotInstBR(rawBlinks, sampleRate, gd.handles.hPlotAxes, plotTitle);
    catch ME
        err = MException('BlinkGUI:plotting','Error plotting instantaneous blink rate.');
        err = addCause(err, ME);
        gui_error(hObj,err);
    end
    
    %save everything to the guidata object:
    gd.blinkPermInputs.sampleRate = sampleRate;
    gd.blinkPermInputs.rawBlinks = rawBlinks;
    gd.blinkPermInputs.plotTitle = plotTitle;
    guidata(hObj, gd);
end

function RunBlinkPerm(hObj, varargin)

    gd = guidata(hObj);  
    
    % Raw blink data
    rawBlinks = gd.blinkPermInputs.rawBlinks;
    
    % Number of permutations
    numPerms = get(gd.handles.hNumPerms, 'String');
    
    % Significance thresh.s
    sigHigh = str2double(get(gd.handles.hSigHighPerm,'String'));
    sigLow = str2double(get(gd.handles.hSigLowPerm,'String'));
    
    % W range to try in sskernel
    Wrange = get(gd.handles.hWRange, 'String');
    
    % What to save
    saveMat = gd.output.saveMat;
    saveCsv = gd.output.saveCsv;
    saveFigs = gd.output.saveFigs;
    
    % Output things
    outputDir = gd.output.dir;
    outputPrefix = get(gd.handles.hOutputFile,'String'); %TODO - there is currently no error checking here - remove /\. ?
    figFormat = gd.output.figFormat;
    
    %% Check basic inputs
    error_msgs = {};
    
    % RAW BLINK DATA
    % (if it's empty, so is sample rate -- TODO verify this)
    if isempty(rawBlinks)
        error_msgs{end+1} = '\tNo data was loaded.';
    end
    
    % NUMBER OF PERMUTATIONS
    if isempty(numPerms)
        error_msgs{end+1} = '\tNumber of permutations was not specified.';
    elseif isnan(str2double(numPerms))
        error_msgs{end+1} = '\tNumber of permutations must be a number';
    elseif numPerms > gd.guiSettings.maxPerms
        error_msgs{end+1} = sprintf('\tMaximum number of permutations= %i',gd.guiSettings.maxPerms);
    else
        numPerms = int16(str2double(numPerms));
        set(gd.handles.hNumPerms, 'String', numPerms);
    end

    % SIGNIFICANCE THRESHOLDS
    % High significance level must be higher than low
    if sigHigh <= sigLow
        error_msgs{end+1} = '\tLow significance threshold must be less than high significance threshold.';
    elseif sigHigh == sigLow
        w = warndlg('Low and high significance thresholds are equal', 'Warning', 'modal');
        uiwait(w);
    end
        
    % WHAT TO SAVE
    %if user wants to save anything, they must specify an output directory
    if saveMat || saveCsv || saveFigs
        if isempty(outputDir) || isequal(outputDir, 0)
            error_msgs{end+1} = '\tOutput directory was not selected.';
        elseif ~isdir(outputDir)
            error_msgs{end+1} = '\tOutput directory is invalid.';
        end
    end
        
    % REPORT ERRORS: if any of the conditions were not met, create error 
    % dialogue with messages and return
    if ~isempty(error_msgs)
        dlg_msg = strjoin(error_msgs,'\n');
        e = errordlg(sprintf(dlg_msg), 'Input Error', 'modal');
        uiwait(e);
        return
    end
        
    %% Check advanced settings and revert to default if any are invalid
    
    % SIGNIFICANCE THRESHOLDS
    % If significance thresholds are invalid, revert to  defaults
    if isnan(sigLow) || sigLow>=100 || sigLow<=0
       w = warndlg('Invalid low significance threshold: using default (2.5)', 'Invalid Entry', 'modal');
       uiwait(w);
       set(gd.handles.hSigLowPerm,'String','2.5');
       sigLow = 2.5;
    end
    
    if isnan(sigHigh) || sigHigh>=100 || sigHigh<=0
       w = warndlg('Invalid high significance threshold: using default (97.5)', 'Invalid Entry', 'modal');
       uiwait(w);
       set(gd.handles.hSigHighPerm,'String','97.5');
       sigHigh = 97.5;
    end
    
    % W RANGE
    %TODO - definitely need to check this
    if ~isempty(Wrange)
        wWarning = 0; %boolean -- true if something goes wrong
        Ws = strsplit(Wrange, ':');
        Wvalues = [];
        for i = 1:length(Ws)
            [temp, status] = str2num(Ws{i});
            if status==0 %not a number
                wWarning = 1;
                break
            else
                Wvalues(i) = temp;
            end 
            if i>3 %too many values
                wWarning = 1;
                break
            end
        end
        
        % If something went wrong, throw warning and revert to default
        if wWarning
            w = warndlg('Invalid W range: must be a numeric value or range of values (e.g. 1:10 or 1:2:10). Using default (none).', 'Invalid Entry', 'modal');
            uiwait(w);
            
            set(gd.handles.hWRange, 'String', '');
            Wrange = [];
            
        % Otherwise, set up W range
        elseif length(Wvalues)==1
            Wrange = Wvalues;
        elseif length(Wvalues)==2
            Wrange = Wvalues(1):Wvalues(2);
        elseif length(Wvalues)==3
            Wrange = Wvalues(1):Wvalues(2):Wvalues(3);
        end
    end
    
    %% Create a waitbar to update user with progress
    hWaitBar = waitbar(0, '1', ...
        'Name','Blink Modulation',...
        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(hWaitBar, 'canceling', 0)
    
    gd.setWaitBar(hWaitBar);
    guidata(hObj, gd);
    
    % Disable buttons to run analyses or toggle between them
    toggleBigButtons(gd.handles, 'disable'); 
    %% run the analysis
    
    try
        results = blinkPerm(numPerms, rawBlinks, gd.blinkPermInputs.sampleRate,...
                                'lowPrctile', sigLow,...
                                'highPrctile', sigHigh,...
                                'W', Wrange,...
                                'hWaitBar', hWaitBar);
    catch ME %TODO - check that PSTH code is consistent with this
        delete(hWaitBar);
        gd.setWaitBar([]);
        gui_error(hObj,ME);
        toggleBigButtons(gd.handles, 'enable');
        return
    end

    
    %% create figures
    
    thingsSaved = 0;
    thingsToSave = saveFigs + saveCsv + saveMat;
    
    if thingsToSave > 0
        waitbar(0, hWaitBar, 'Saving output...');
        dirFilePrefix = dirFileJoin(outputDir, outputPrefix);
    else
        dirFilePrefix = '';
    end
    
    if ~saveFigs
        figFormat = ''; %if figFormat is empty, figures will not be saved
    end
    
    try
        blinkPermFigures(dirFilePrefix, results, figFormat);
    catch ME
        gui_error(hObj,ME);
    end

    if saveFigs
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end
    
    %% summary file
    if saveCsv
       
        % output csv summary file
        try
            blinkPermSummary(dirFilePrefix, results);
        catch ME
            gui_error(hObj,ME);
        end
        
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end
    
    %% save mat file
    if saveMat
        
        % save .mat file in the outputDir
        try
            % full path for a mat file:
            mat_file_full = sprintf('%sblinkPerm.mat', dirFilePrefix);
            save(mat_file_full, 'results'); %TODO - does this work, to only save part of a struct?
        catch ME
            gui_error(hObj,ME);
        end
        
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end
    
    %% Delete progress bar, enable big buttons
    toggleBigButtons(gd.handles, 'enable');
    delete(hWaitBar);
    gd.setWaitBar([]);
    
    %% Save guidata -- TODO is this necessary?? probably not, now that i'm using handle class...
    guidata(hObj, gd);
    
end

%% BLINK PSTH
function LoadTargetData(hObj, varargin)
    
    gd = guidata(hObj);
    
    [input_file, PathName] = uigetfile('*.csv','Choose a csv file with target data');
    if input_file == 0
        return
    end
    input_file_full = dirFileJoin(PathName, input_file);

    %Get target code
    prompt = {'Enter target event code:'};
    dlg_title = 'Target Event Code';
    num_lines = 1;
    answer = inputdlg(prompt, dlg_title, num_lines);
    
    %if user cancels or doesn't enter anything
    if iscell(answer) && isempty(answer) 
        return
    end
    
    % If target code is empty or non-numeric
    targetCode = str2double(answer{1});
    if isnan(targetCode) 
        errordlg('Target code must be numeric.');
        return
    end

    %TODO get targetEventType with radio dlg box
    targetEventType = 'allFrames';

    try 
        rawTargetData = readInPsthEvents(input_file_full); 
        gd.blinkPsthInputs.targetEvents = getTargetEvents(rawTargetData, targetCode, targetEventType); 
    catch ME
        gui_error(hObj,ME);
        return
    end
    
    %TODO - edit blinkPsth with stuff for PSTH summary file
    gd.blinkPsthInputs.targetCode = targetCode;
    gd.blinkPsthInputs.targetEventType = targetEventType;

    %plot both target data AND reference data
    cla(gd.handles.hPlotAxes, 'reset');
    plotTargetAndRef(gd.blinkPsthInputs.targetEvents, gd.blinkPsthInputs.refEvents, gd.handles.hPlotAxes);
    %TODO - figure out how to have good title for this plot
    
    guidata(hObj, gd);
end

function LoadRefData(hObj, varargin)
    
    gd = guidata(hObj);
    
    
    [input_file, PathName] = uigetfile('*.csv','Choose a csv file with reference data');
    if input_file == 0
        return
    end
    input_file_full = dirFileJoin(PathName, input_file);

    %Get reference code
    prompt = {'Enter reference event code:'};
    dlg_title = 'Reference Event Code';
    num_lines = 1;
    answer = inputdlg(prompt, dlg_title, num_lines);
    
    %if user cancels or doesn't enter anything
    if iscell(answer) && isempty(answer) 
        return
    end
    
    refCode = str2double(answer{1});
    if isnan(refCode)
        errordlg('Reference code must be numeric.');
        return
    end

    %TODO get refEventType with radio dlg box
    refEventType = 'allFrames';

    %TODO - get blinkPsth.startFrame from advanced options
    startFrame = get(gd.handles.hStartFrameEdit, 'String');
    startFrame = str2double(startFrame);
    if isnan(startFrame) || isempty(startFrame) || startFrame <=0
        w = warndlg('TODO - using default for startFrame','Invalid entry','modal');
        uiwait(w);
        startFrame = 1;
        
    end
    gd.blinkPsthInputs.startFrame = startFrame;
    
    try 
        rawRefData = readInPsthEvents(input_file_full); 
        gd.blinkPsthInputs.refEvents = getRefEvents(rawRefData, refCode, targetEventType, gd.blinkPsthInputs.startFrame); 
    catch ME
        gui_error(hObj,ME);
        return
    end

    %TODO - edit blinkPsth with stuff for PSTH summary file
    gd.blinkPsthInputs.refCode = refCode;
    gd.blinkPsthInputs.refEventType = refEventType;

    %plot both target data AND reference data
    cla(gd.handles.hPlotAxes, 'reset');
    plotTargetAndRef(gd.blinkPsthInputs.targetEvents, gd.blinkPsthInputs.refEvents, gd.handles.hPlotAxes);
    %TODO - figure out how to have good title for this plot

    guidata(hObj, gd);
end

function RunBlinkPSTH(hObj, varargin)
    
    gd = guidata(hObj);
    
    %Target and reference events 
    targetEvents = gd.blinkPsthInputs.targetEvents;
    refEvents = gd.blinkPsthInputs.refEvents;
    
    %Window size before and after event
    lagBefore = str2double(get(gd.handles.hLagBefore, 'String'));
    lagAfter = str2double(get(gd.handles.hLagAfter, 'String'));
    
    % Num permutations
    numPerms = str2double(get(gd.handles.hNumPermsPsth,'String'));
    
    % Significance thresholds
    sigLow = str2double(get(gd.handles.hSigLowPsth,'String'));
    sigHigh = str2double(get(gd.handles.hSigHighPsth,'String'));
    
    % Start frame
    startFrame = str2double(get(gd.handles.hStartFrameEdit, 'String'));
    
    % Include threshold
    inclThresh = str2double(get(gd.handles.hInclThreshEdit, 'String'));
    
    % What to save
    saveMat = gd.output.saveMat;
    saveCsv = gd.output.saveCsv;
    saveFigs = gd.output.saveFigs;
    
    % Output things
    outputDir = gd.output.dir;
    outputPrefix = get(gd.handles.hOutputFile,'String'); %TODO - there is currently no error checking here - remove /\. ?
    figFormat = gd.output.figFormat;
    
    %% Check normal settings
    
    error_msgs = {};
    
    % TARGET EVENTS
    if isempty(targetEvents)
        error_msgs{end+1} = '\tNo target events were loaded.';
    end

    % REFERENCE EVENTS
    if isempty(refEvents)
        error_msgs{end+1} = '\tNo reference events were loaded.';
    end
    
    % WINDOW SIZE BEFORE AND AFTER EVENT
    if isnan(lagBefore) || isnan(lagAfter) || lagBefore<0 || lagAfter <0
        error_msgs{end+1} = '\tWindow size before and after event must be positive integers.';
    else %make it an integer
        lagBefore = int32(lagBefore);
        lagAfter = int32(lagAfter);
        set(gd.handles.hLagBefore, 'String', lagBefore);
        set(gd.handles.hLagAfter, 'String', lagAfter);
        lagSize = [lagBefore, lagAfter];
    end
    
    % NUMBER OF PERMUTATIONS
    if isnan(numPerms) || numPerms < 0 
        error_msgs{end+1} = '\tNumber of permutations must be a positive number.';
    elseif numPerms>gd.guiSettings.maxPerms
        error_msgs{end+1} = sprintf('\tMaximum number of permutations= %i',gd.guiSettings.maxPerms);
    else %make it an integer
        numPerms = int32(numPerms);
        set(gd.handles.hNumPermsPsth, 'String', numPerms);
    end

    % WHAT TO SAVE
    % if user wants to save anything, they must specify an output directory
    if saveMat || saveCsv || saveFigs
        if isempty(outputDir) || isequal(outputDir, 0)
            error_msgs{end+1} = '\tOutput directory was not selected.';
        elseif ~isdir(gd.output.dir)
            error_msgs{end+1} = '\tOutput directory is invalid.';
        end
    end
    
    % SIGNIFICANCE 
    % Sig High must be higher than sig low
    if sigHigh <= sigLow
        error_msgs{end+1} = '\tLow significance threshold must be less than high significance threshold.';
    end
    
    % if any of the conditions were not met, create error dialogue with messages and return
    if ~isempty(error_msgs)
        dlg_msg = strjoin(error_msgs,'\n');
        errordlg(sprintf(dlg_msg));
        return
    end
    
    %% Check advanced settings and revert to defaults if any are invalid
    
    % SIGNIFICANCE THRESHOLDS
    % If significance thresholds are invalid, revert to  defaults
    if isnan(sigLow) || sigLow>=100 || sigLow<=0
       w = warndlg('Invalid low significance threshold: using default (2.5)', 'Invalid Entry', 'modal');
       uiwait(w);
       set(gd.handles.hSigLowPsth,'String','2.5');
       sigLow = 2.5;
    end
    if isnan(sigHigh) || sigHigh>=100 || sigHigh<=0
       w = warndlg('Invalid high significance threshold: using default (97.5)', 'Invalid Entry', 'modal');
       uiwait(w);
       set(gd.handles.hSigHighPsth,'String','97.5');
       sigHigh = 97.5;
    end

    % START FRAME
    if isnan(startFrame) || startFrame <=0
        w = warndlg('Invalid start frame - must be positive integer. Using default (1).');
        uiwait(w);
        set(gd.handles.hStartFrameEdit, 'String', '1');
        startFrame = 1;
    else
        startFrame = int32(startFrame);
        set(gd.handles.hStartFrameEdit,'String',startFrame);
    end
    
    % INCLUDE THRESHOLD
    if isnan(inclThresh) || inclThresh <0 || inclThresh>1
        w = warndlg('Invalid include threshold - must be between 0 and 1. Using default (.2).');
        uiwait(w);
        set(gd.handles.hInclThreshEdit, 'String', '0.2');
        inclThresh = .2;
    end
    
    %% Create a waitbar to update user with progress
    hWaitBar = waitbar(0, '1', ...
        'Name','PSTH',...
        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(hWaitBar, 'canceling', 0)
    
    gd.setWaitBar(hWaitBar);

    %% run the analysis
    try
        results = blinkPSTH(refEvents, gd.blinkPsthInputs.targetEvents, lagSize, numPerms,...
                                    'startFrame', startFrame,...
                                    'inclThresh', inclThresh,...
                                    'lowPrctile', sigLow,...
                                    'highPrctile', sigHigh,...
                                    'hWaitBar', hWaitBar);
    catch ME
        delete(hWaitBar);
        gd.setWaitBar([]);
        gui_error(hObj,ME);
        return
    end

    %%  create figures
    
    thingsSaved = 0;
    thingsToSave = saveFigs + saveCsv + saveMat;
    
    if thingsToSave>0
        waitbar(0, hWaitBar, 'Saving output...');
    end
    
    if ~saveFigs
        figFormat = ''; %if figFormat is empty, figures will not be saved
    end
    
    try
%         dirFilePrefix = dirFileJoin(outputDir, outputPrefix);
%         blinkPermFigures(dirFilePrefix, results, figFormat);
        blinkPSTHFigures(outputDir, results, figFormat); % [ax1];
    catch ME 
        gui_error(hObj,ME);
    end
    
    if saveFigs
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end

    %% summary file
    if saveCsv

        % output csv summary file
        try
            blinkPSTHSummary(outputPrefix_full, results);
        catch ME
            gui_error(hObj,ME);
        end  
    
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end 
    
    %% save mat file
    if saveMat
        
        % save .mat file in the outputDir
        try
            % full path for a mat file:
            mat_name = sprintf('%sPSTH.mat', outputPrefix);
            mat_file_full = dirFileJoin(outputDir, mat_name);
            save(mat_file_full, 'results'); %TODO - choose what to save - results + inputs?
        catch ME
            gui_error(hObj,ME);
        end
        
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end
    
    %% Delete progress bar
    delete(hWaitBar);
    gd.setWaitBar([]);
    
    %% Save guidata - TODO i think this is unnecessary?
    guidata(hObj, gd);
end

%%
function CloseGUI(hObj,varargin)
    %TODO - fix this!
    gd = guidata(hObj);
    if ~isempty(gd.handles.hWaitBar)
        delete(gd.handles.hWaitBar);
    end
    
    delete(hObj);
end

end