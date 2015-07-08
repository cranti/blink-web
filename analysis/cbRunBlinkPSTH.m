function cbRunBlinkPSTH(~, ~, gd)
%CBRUNBLINKPSTH - run blink PSTH analysis. Callback function for blinkGUI.m
%
% Note: no error checking for the output file prefix (remove /\. ?)

% Carolyn Ranti
% 6.5.2015

try
    %% Initialize hWaitBar as non-handle
    hWaitBar = NaN;
    
    %% Get all of the variables we'll be using out of gd (except handles)
    
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
    
    % Start frame - get from guidata
    startFrame = gd.blinkPsthInputs.startFrame;
    
    % Include threshold
    inclThresh = str2double(get(gd.handles.hInclThreshEdit, 'String'));
    
    % Target and reference order
    targetOrder = gd.blinkPsthInputs.targetOrder;
    refOrder = gd.blinkPsthInputs.refOrder;
    
    %Reference set lengths (matched to targetLens)
    refLens = gd.blinkPsthInputs.refLens; %no error checking for this
    
    % What to save
    saveMat = gd.output.saveMat;
    saveCsv = gd.output.saveCsv;
    saveFigs = gd.output.saveFigs;
    
    % Output things
    outputDir = gd.output.dir;
    outputPrefix = get(gd.handles.hOutputFile,'String'); 
    figFormat = gd.output.figFormat;
    
    %GUI settings
    error_log = gd.guiSettings.error_log;
    maxPerms = gd.guiSettings.maxPerms;
    
    %% Check inputs
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
        error_msgs{end+1} = '\tWindow size before and after event must be >=0';
    else %make it an integer
        lagBefore = int32(lagBefore);
        lagAfter = int32(lagAfter);
        set(gd.handles.hLagBefore, 'String', lagBefore);
        set(gd.handles.hLagAfter, 'String', lagAfter);
        lagSize = [lagBefore, lagAfter];
    end
    
    % NUMBER OF PERMUTATIONS
    if isnan(numPerms) || numPerms <= 0
        error_msgs{end+1} = '\tNumber of permutations must be positive.';
    elseif numPerms>maxPerms
        error_msgs{end+1} = sprintf('\tMaximum number of permutations = %i', maxPerms);
    else %make it an integer
        numPerms = int32(numPerms);
        
        %this is a catch to make sure that it isn't rounded down
        %to 0 by int32 conversion
        if numPerms==0
            numPerms=1;
        end
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
    
    
    %% Error checks: matching target and reference sets
    
    numTargets = length(targetEvents);
    numRefSets = length(refEvents);
    
    %Make sure that all target identifiers have matching reference sets:
    if (numRefSets >= numTargets) && ~isempty(setdiff(targetOrder, refOrder)) %note - setdiff returns items in targetOrder that aren't in refOrder
        errordlg('1 or more target sets is not matched to a reference set (by ID)');
        return
        
    %Check: if there aren't enough ref sets (but there's more than 1)
    elseif numRefSets>1 && numRefSets<numTargets
        errordlg('Event set mismatch: there must be EITHER one reference set OR one reference set per target set');
        return
    end
    
    %Remove ref sets that aren't in target events (by ID)
    if numRefSets > numTargets
        
        % find the index of refOrder #s that are also in targetOrder
        [~, itarg, iref] = intersect(targetOrder, refOrder);
        
        %limit target events to the intersection (this is to ensure the
        %same order)
        targetEvents = targetEvents(itarg);
        targetOrder = targetOrder(itarg);
        
        %limit refEvents and refOrder to these values
        refEvents = refEvents(iref);
        refOrder = refOrder(iref); %this should be equal to targetOrder
        refLens = refLens(iref);
    end
    
    
    %Check ref lens here, rather than in blinkPSTH
    targetLens = cellfun(@length, targetEvents);
    if length(refLens) == 1
        if ~sum(targetLens == refLens)
            errordlg('Mismatch between length of target event sets and length of reference event set.');
            return
        end
    else
        if (isrow(refLens) && ~isrow(targetLens)) || (~isrow(refLens) && isrow(targetLens))
            refLens = refLens';
        end
        if ~isequal(targetLens, refLens)
            errordlg('Mismatch between length of target event sets and length of reference event sets.');
            return
        end
    end
           
    %% Warning -- chance to opt out
    
    % Window size
    minTargSize = min(cellfun(@length, targetEvents));
    if (lagBefore+lagAfter+1)>minTargSize
        [~, cont] =  warndlgCancel({'PSTH size is larger than one or more of target data sets', 'Press OK to continue with these values'}, 'Warning', 'modal', 1);
        if ~cont
            return
        end
%     elseif (lagBefore > minTargSize/2) || (lagAfter > minTargSize/2)
%         [~, cont] = warndlgCancel({'The window size before or after event may be too large relative to the length of your data.', 'Press OK to continue with these values'}, 'Warning', 'modal', 1);
%         if ~cont
%             return
%         end
    end
    
    %% Check advanced settings and revert to defaults if any are invalid
    
    % SIGNIFICANCE THRESHOLDS
    if isnan(sigLow) || sigLow>=100 || sigLow<=0
        [~, cont] = warndlgCancel({'Invalid lower significance threshold - must be between 0 and 100.', 'Press OK to use default (2.5)'}, 'Invalid Entry', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hSigLowPerm,'String','2.5');
        sigLow = 2.5;
    end
    
    if isnan(sigHigh) || sigHigh>=100 || sigHigh<=0
        [~, cont] = warndlgCancel({'Invalid upper significance threshold - must be between 0 and 100.', 'Press OK to use default (97.5)'}, 'Invalid Entry', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hSigHighPerm,'String','97.5');
        sigHigh = 97.5;
    end
    
    % High significance level must be higher than low
    if sigHigh <= sigLow
        [~, cont] = warndlgCancel({'Lower significance threshold must be less than upper significance threshold.', 'Press OK to use defaults (2.5 and 97.5)'}, 'Invalid Entry', 'modal', 1);
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
        warnMsg = {'Sample start has been changed since reference events were loaded.', ...
            'To change the sample start, press CANCEL and reload reference data with desired setting.',...
            sprintf('Press OK to use the previously set value (%i).', startFrame)};
        
        [~, cont] = warndlgCancel(warnMsg, 'Warning', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hStartFrameEdit,'String',startFrame);
    end
    
    % INCLUDE THRESHOLD
    if isnan(inclThresh) || inclThresh <=0 || inclThresh>1
        [~, cont] = warndlgCancel({'Invalid include threshold - must be between 0 and 1.','Press OK to use default (0.2).'}, 'Warning', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hInclThreshEdit, 'String', '0.2');
        inclThresh = .2;
    end
    
    
    %% Warning - chance to opt out
    
    % OVERWRITING FILES
    % This should be updated if any of the file naming patterns change
    if saveMat || saveCsv || saveFigs
        file1 = [dirFileJoin(outputDir,outputPrefix), 'PSTH.', figFormat];
        file2 = [dirFileJoin(outputDir,outputPrefix), 'PSTHchangeFromMean.', figFormat];
        file3 = [dirFileJoin(outputDir,outputPrefix), 'PSTH.mat'];
        file4 = [dirFileJoin(outputDir,outputPrefix), 'PSTHsummary.csv'];
        
        if exist(file1, 'file') || exist(file2, 'file') || exist(file3, 'file') || exist(file4, 'file')
            [~, cont] = warndlgCancel({'Output files with this prefix exist in the selected output directory.', 'OK to overwrite?'}, 'Invalid Entry', 'modal', 1);
            if ~cont
                return
            end
        end
    end
    

    %% Extra input specs for summary printing
    otherInputSpecs.refFilename = gd.blinkPsthInputs.refFilename;
    otherInputSpecs.refEventType = gd.blinkPsthInputs.refEventType;
    otherInputSpecs.refCode = gd.blinkPsthInputs.refCode;
    otherInputSpecs.refOrder = refOrder; %pulled out when matching targ & ref sets
    
    otherInputSpecs.targetFilename = gd.blinkPsthInputs.targetFilename;
    otherInputSpecs.targetEventType = gd.blinkPsthInputs.targetEventType;
    otherInputSpecs.targetCode = gd.blinkPsthInputs.targetCode;
    otherInputSpecs.targetOrder = targetOrder; %pulled out when matching targ & ref sets
    
    
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
        results = blinkPSTH(refEvents, targetEvents, lagSize, numPerms,...
            'startFrame', startFrame,...
            'inclThresh', inclThresh,...
            'lowPrctile', sigLow,...
            'highPrctile', sigHigh,...
            'refLens', refLens,...
            'hWaitBar', hWaitBar);
        
    catch ME
        cleanUp(gd, hWaitBar);
        gui_error(ME, error_log);
        return
    end
    
    % check if user canceled
    if isempty(results)
        cleanUp(gd, hWaitBar)
        return
    end
    
    %% Modify results struct in prep for output scripts
    results = blinkPermMatConvert(results, otherInputSpecs);
    
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
        blinkPSTHFigures(dirFilePrefix, results, figFormat);
    catch ME
        gui_error(ME, error_log);
    end
    
    if saveFigs
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end
    
    %% summary file
    if saveCsv
        
        % output csv summary file
        try
            blinkPSTHSummary(dirFilePrefix, results);
        catch ME
            gui_error(ME, error_log);
        end
        
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end
    
    %% save mat file
    if saveMat
        
        try
            % full path for a mat file:
            matfile_name = sprintf('%sPSTH.mat', dirFilePrefix);
            
            % save the results struct
            save(matfile_name, 'results');
            
        catch ME
            err = MException('BlinkGUI:output','Error saving PSTH mat file.');
            err = addCause(err, ME);
            gui_error(err, error_log);
        end
        
        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end
    
    %% Delete progress bar, re-enable big buttons
    cleanUp(gd, hWaitBar)
    
    
% Catch and log any errors that weren't dealt with
catch ME
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, error_log);
    cleanUp(gd, hWaitBar)
    return
end

end

% Deal with the wait bar, re-enable the big buttons
function cleanUp(gd, hWaitBar)
    toggleBigButtons(gd.handles, 'enable');
    if ishandle(hWaitBar)
        delete(hWaitBar);
    end
    gd.setWaitBar([]);
end