function cbRunBlinkPSTH(~, ~, gd)
%CBRUNBLINKPSTH - run blink PSTH analysis. Callback function for blinkGUI.m
%
%

%% Get all of the variables we'll be using out of gd

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
startFrame = gd.blinkPsthInputs.startFrame; 

% Include threshold
inclThresh = str2double(get(gd.handles.hInclThreshEdit, 'String'));

%Reference set lengths
refSetLen = gd.blinkPsthInputs.refSetLen; %TODO - no error checking for this

% What to save
saveMat = gd.output.saveMat;
saveCsv = gd.output.saveCsv;
saveFigs = gd.output.saveFigs;

% Output things
outputDir = gd.output.dir;
outputPrefix = get(gd.handles.hOutputFile,'String'); %TODO - there is currently no error checking here - remove /\. ?
figFormat = gd.output.figFormat;

%% Extra input specs for summary printing
otherInputSpecs.refFilename = gd.blinkPsthInputs.refFilename;
otherInputSpecs.refEventType = gd.blinkPsthInputs.refEventType;
otherInputSpecs.refCode = gd.blinkPsthInputs.refCode;
otherInputSpecs.refSetLen = gd.blinkPsthInputs.refSetLen;

otherInputSpecs.targetFilename = gd.blinkPsthInputs.targetFilename;
otherInputSpecs.targetEventType = gd.blinkPsthInputs.targetEventType;
otherInputSpecs.targetCode = gd.blinkPsthInputs.targetCode;

otherInputSpecs.numPerms = numPerms;

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
if isnan(numPerms) || numPerms <= 0
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
    elseif ~isdir(outputDir)
        error_msgs{end+1} = '\tOutput directory is invalid.';
    end
    
end

% if any of the conditions were not met, create error dialogue with messages and return
if ~isempty(error_msgs)
    dlg_msg = strjoin(error_msgs,'\n');
    errordlg(sprintf(dlg_msg));
    return
end
    
% WARNING ABOUT OVERWRITING FILES
% This should be updated if any of the file naming patterns change
if saveMat || saveCsv || saveFigs
    file1 = [dirFileJoin(outputDir,outputPrefix), 'PSTH.', figFormat];
    file2 = [dirFileJoin(outputDir,outputPrefix), 'PSTHminusMean.', figFormat];
    file3 = [dirFileJoin(outputDir,outputPrefix), 'PSTH.mat'];
    file4 = [dirFileJoin(outputDir,outputPrefix), 'PSTHsummary.csv'];

    if exist(file1, 'file') || exist(file2, 'file') || exist(file3, 'file') || exist(file4, 'file')
        [~, cont] = warndlgCancel({'Output files with this prefix exist in the selected output directory.', 'OK to overwrite?'}, 'Invalid Entry', 'modal', 1);
        if ~cont
            return
        end
    end
end

%% Check advanced settings and revert to defaults if any are invalid

% SIGNIFICANCE THRESHOLDS
if isnan(sigLow) || sigLow>=100 || sigLow<=0
    [~, cont] = warndlgCancel({'Invalid low significance threshold - must be between 0 and 100.', 'Press OK to use default (2.5)'}, 'Invalid Entry', 'modal', 1);
    if ~cont
        return
    end
    set(gd.handles.hSigLowPerm,'String','2.5');
    sigLow = 2.5;
end

if isnan(sigHigh) || sigHigh>=100 || sigHigh<=0
    [~, cont] = warndlgCancel({'Invalid high significance threshold - must be between 0 and 100.', 'Press OK to use default (97.5)'}, 'Invalid Entry', 'modal', 1);
    if ~cont
        return
    end
    set(gd.handles.hSigHighPerm,'String','97.5');
    sigHigh = 97.5;
end

% High significance level must be higher than low
if sigHigh <= sigLow
    [~, cont] = warndlgCancel({'Low significance threshold must be less than high significance threshold.', 'Press OK to use defaults (2.5 and 97.5)'}, 'Invalid Entry', 'modal', 1);
    if ~cont
        return
    end
    set(gd.handles.hSigLowPerm,'String','2.5');
    sigLow = 2.5;
    set(gd.handles.hSigHighPerm,'String','97.5');
    sigHigh = 97.5;
end

% START FRAME
% NOTE: startFrame was checked in cbLoadRefData. Here, I'm just checking
% that it's equal to the string that is currently in the GUI. If they are
% not equal, give the user a warning and change the GUI to reflect the
% value used.
startFrameInGui = int32(str2double(get(gd.handles.hStartFrameEdit, 'String')));
if ~isequal(startFrame, startFrameInGui)
    warnMsg = {'Start frame has been changed since reference events were loaded.', ...
        'To change the start frame, press CANCEL and reload reference data with desired setting.',...
        sprintf('Press OK to use the previously set value (%i).', startFrame)};
    
    [~, cont] = warndlgCancel(warnMsg, 'Warning', 'modal', 1);
    if ~cont
        return
    end
    set(gd.handles.hStartFrameEdit,'String',startFrame);
end

if isnan(startFrame) || startFrame <=0
    [~, cont] = warndlg({'Invalid start frame - must be positive integer.','Press OK to use default (1).'}, 'Warning', 'modal', 1);
    if ~cont
        return
    end
    set(gd.handles.hStartFrameEdit, 'String', '1');
    startFrame = 1;
else
    startFrame = int32(startFrame);
end

% INCLUDE THRESHOLD
if isnan(inclThresh) || inclThresh <0 || inclThresh>1
    [~, cont] = warndlgCancel({'Invalid include threshold - must be between 0 and 1.','Press OK to use default (0.2).'}, 'Warning', 'modal', 1);
    if ~cont
        return
    end
    set(gd.handles.hInclThreshEdit, 'String', '0.2');
    inclThresh = .2;
end

%% Create a waitbar to update user with progress
hWaitBar = waitbar(0, '', ...
    'Name','PSTH',...
    'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
setappdata(hWaitBar, 'canceling', 0)

%save handle for waitbar in GUIDATA
gd.setWaitBar(hWaitBar);

% Disable buttons to run analyses or toggle between them
toggleBigButtons(gd.handles, 'disable');

%% run the analysis

try
    results = blinkPSTH(refEvents, gd.blinkPsthInputs.targetEvents, lagSize, numPerms,...
        'startFrame', startFrame,...
        'inclThresh', inclThresh,...
        'lowPrctile', sigLow,...
        'highPrctile', sigHigh,...
        'refSetLen', refSetLen,...
        'hWaitBar', hWaitBar);
    
catch ME
    cleanUp(gd, hWaitBar);
    gui_error(ME, gd.guiSettings.error_log);
    return
end

% check if user canceled
if isempty(results)
    cleanUp(gd, hWaitBar)
    return
end


%%  create figures
thingsSaved = 0;
thingsToSave = saveFigs + saveCsv + saveMat;

if thingsToSave>0
    waitbar(0, hWaitBar, 'Saving output...');
    dirFilePrefix = dirFileJoin(outputDir, outputPrefix);
else
    dirFilePrefix = '';
end

if ~saveFigs
    figFormat = ''; %if figFormat is empty, figures will not be saved
end

try
    blinkPSTHFigures(dirFilePrefix, results, figFormat); % %TODO - update this script
catch ME
    gui_error(ME, gd.guiSettings.error_log);
end

if saveFigs
    thingsSaved = thingsSaved + 1;
    waitbar(thingsSaved/thingsToSave, hWaitBar);
end

%% summary file
if saveCsv
    
    % output csv summary file
    try
        blinkPSTHSummary(dirFilePrefix, results, otherInputSpecs);
    catch ME
        gui_error(ME, gd.guiSettings.error_log);
    end
    
    thingsSaved = thingsSaved + 1;
    waitbar(thingsSaved/thingsToSave, hWaitBar);
end

%% save mat file
if saveMat
    
    % save .mat file in the outputDir
    try
        % full path for a mat file:
        matfile_name = sprintf('%sPSTH.mat', dirFilePrefix);
        
        %put the other input specs into results, so that they get saved
        results.otherInputSpecs = otherInputSpecs;
        
        save(matfile_name, 'results');
    catch ME
        err = MException('BlinkGUI:output','Error saving PSTH mat file.');
        err = addCause(err, ME);
        gui_error(err, gd.guiSettings.error_log);
    end
    
    thingsSaved = thingsSaved + 1;
    waitbar(thingsSaved/thingsToSave, hWaitBar);
end

%% Delete progress bar, re-enable big buttons
cleanUp(gd, hWaitBar)

end

%TODO - use this format in other functions with waitbars
function cleanUp(gd, hWaitBar)
    delete(hWaitBar);
    gd.setWaitBar([]);
    toggleBigButtons(gd.handles, 'enable');
end
