function cbRunBlinkPerm(~, ~, gd)
%CBRUNPERM - run blink permutation testing. Callback function for blinkGUI.m
%
% Note: no error checking for the output file prefix (remove /\. ?)

% Carolyn Ranti
% 6.5.2015

try
    %% Initialize hWaitBar as non-handle
    hWaitBar = NaN;
    
    %% Get all variables that we'll be using out of gd/gui

    % Raw blink data
    rawBlinks = gd.blinkPermInputs.rawBlinks;

    % Sample rate
    sampleRate = gd.blinkPermInputs.sampleRate;

    % Number of permutations
    numPerms = str2double(get(gd.handles.hNumPerms, 'String'));

    % Significance thresholds
    sigUpper = str2double(get(gd.handles.hSigHighPerm,'String'));
    sigLower = str2double(get(gd.handles.hSigLowPerm,'String'));
    sigFrames = str2double(get(gd.handles.hSigFrames, 'String'));

    % W range to try in sskernel
    wRangeStr = get(gd.handles.hWRange, 'String');

    % What to save
    saveMat = gd.output.saveMat;
    saveCsv = gd.output.saveCsv;
    saveFigs = gd.output.saveFigs;

    % Output things
    outputDir = gd.output.dir;
    outputPrefix = get(gd.handles.hOutputFile,'String'); %TODO - there is currently no error checking here - remove /\. ?
    figFormat = gd.output.figFormat;
    input_file = gd.blinkPermInputs.filename;

    % GUI settings
    error_log = gd.guiSettings.error_log;
    maxPerms = gd.guiSettings.maxPerms;
    
    %% Check inputs
    error_msgs = {};

    % RAW BLINK DATA & SAMPLE RATE (loaded in the same process)
    if isempty(rawBlinks) || isempty(sampleRate)
        error_msgs{end+1} = '\tNo data was loaded.';
    end

    % NUMBER OF PERMUTATIONS
    if isnan(numPerms) || numPerms<=0
        error_msgs{end+1} = '\tNumber of permutations must be positive.';
    elseif numPerms > maxPerms
        error_msgs{end+1} = sprintf('\tMaximum number of permutations= %i',gd.guiSettings.maxPerms);
    else
        numPerms = int32(numPerms);
        
        %this is a catch to make sure that it isn't rounded down
        %to 0 by int32 conversion
        if numPerms==0
            numPerms=1;
        end
        set(gd.handles.hNumPerms, 'String', numPerms);
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

    
    %% Check advanced options and revert to defaults if they are invalid


    % W RANGE
    if isempty(wRangeStr)
        wRangeNums = [];
    else

        wWarning = 0; %boolean -- true if something goes wrong

        wStrSplit = strsplit(wRangeStr, ':');

        %if there are more than 3 values (separated by :), it's invalid:
        if length(wStrSplit) > 3
            wWarning = 1; 
        else
            Wvalues = zeros(1,length(wStrSplit));

            for i = 1:length(wStrSplit)
                [temp, status] = str2num(wStrSplit{i});

                if status==0 %not a number
                    wWarning = 1;
                    break
                elseif ~isscalar(temp) %not a scalar
                    wWarning = 1;
                    break

                else
                    Wvalues(i) = temp;
                end
            end  
        end
        
        % If something went wrong, throw warning and revert to default
        if wWarning
            [~, cont] = warndlgCancel({'Invalid W range: must be a positive numeric value or range of values (e.g. 4 or 1:10 or 1:3:10)','Press OK to use default (none).'}, 'Invalid Entry', 'modal', 1);
            if ~cont
                return
            end

            set(gd.handles.hWRange, 'String', '');
            wRangeNums = [];

        % Otherwise, set up W range
        elseif length(Wvalues)==1
            wRangeNums = Wvalues;
        elseif length(Wvalues)==2
            wRangeNums = Wvalues(1):Wvalues(2);
        elseif length(Wvalues)==3
            wRangeNums = Wvalues(1):Wvalues(2):Wvalues(3);
        end
        
        if any(wRangeNums<=0)
            [~, cont] = warndlgCancel({'Invalid W range: must be a positive numeric value or range of values (e.g. 4 or 1:10 or 1:3:10)','Press OK to use default (none).'}, 'Invalid Entry', 'modal', 1);
            if ~cont
                return
            end

            set(gd.handles.hWRange, 'String', '');
            wRangeNums = [];
        end
        
    end


    % SIGNIFICANCE THRESHOLDS
    if isnan(sigLower) || sigLower>=100 || sigLower<=0
        [~, cont] = warndlgCancel({'Invalid lower significance threshold.', 'Press OK to use default (2.5)'}, 'Invalid Entry', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hSigLowPerm,'String','2.5');
        sigLower = 2.5;
    end

    if isnan(sigUpper) || sigUpper>=100 || sigUpper<=0
        [~, cont] = warndlgCancel({'Invalid upper significance threshold.', 'Press OK to use default (97.5)'}, 'Invalid Entry', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hSigHighPerm,'String','97.5');
        sigUpper = 97.5;
    end

    % High significance level must be higher than low
    if sigUpper <= sigLower
        [~, cont] = warndlgCancel({'Lower significance threshold must be less than upper significance threshold.', 'Press OK to use defaults (2.5 and 97.5)'}, 'Invalid Entry', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hSigLowPerm,'String','2.5');
        sigLower = 2.5;
        set(gd.handles.hSigHighPerm,'String','97.5');
        sigUpper = 97.5;
    end

    % Number of frames (significance)
    if isnan(sigFrames) || sigFrames<=0
        [~, cont] = warndlgCancel({'Invalid number of frames (significance threshold).', 'Press OK to use default (1)'}, 'Invalid Entry', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hSigFrames,'String','1');
        sigFrames = 1;
    else
        sigFrames = int32(sigFrames);
         %this is a catch to make sure that it isn't rounded down
        %to 0 by int32 conversion
        if sigFrames==0
            sigFrames=1;
        end
        set(gd.handles.hSigFrames,'String', sigFrames);
    end


    %% Warning - chance to opt out

    % OVERWRITING FILES
    % This should be updated if any of the file naming patterns change
    if saveMat || saveCsv || saveFigs
        file1 = [dirFileJoin(outputDir,outputPrefix), 'BLINK_MOD.', figFormat];
        file2 = [dirFileJoin(outputDir,outputPrefix), 'BLINK_MOD.mat'];
        file3 = [dirFileJoin(outputDir,outputPrefix), 'BLINK_MODsummary.csv'];

        if exist(file1, 'file') || exist(file2, 'file') || exist(file3, 'file')
            [~, cont] = warndlgCancel({'Output files with this prefix exist in the selected output directory.', 'OK to overwrite?'}, 'Invalid Entry', 'modal', 1);
            if ~cont
                return
            end
        end
    end


    %% Create a waitbar to update user with progress
    hWaitBar = waitbar(0, '...', ...
        'Name','Blink Modulation',...
        'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
    setappdata(hWaitBar, 'canceling', 0)

    %save handle for waitbar in GUIDATA
    gd.setWaitBar(hWaitBar);

    % Disable buttons to run analyses or toggle between them
    toggleBigButtons(gd.handles, 'disable');


    %% run the analysis

    try
        results = blinkPerm(numPerms, rawBlinks, sampleRate,...
            'lowerPrctile', sigLower,...
            'upperPrctile', sigUpper,...
            'sigFrameThr', sigFrames,...
            'W', wRangeNums,...
            'hWaitBar', hWaitBar);
    catch ME 
        cleanUp(gd, hWaitBar)
        gui_error(ME, error_log);
        return
    end

    % if analysis is canceled, exit
    if isempty(results)
        cleanUp(gd, hWaitBar)
        return
    end

    %% Modify results struct slightly in prep for output stuff
    results = blinkPermMatConvert(results, input_file, wRangeStr);
    
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

        if saveFigs
            thingsSaved = thingsSaved + 1;
            waitbar(thingsSaved/thingsToSave, hWaitBar);
        end
    catch ME
        gui_error(ME, error_log);
    end



    %% summary file
    if saveCsv

        % output csv summary file
        try
            blinkPermSummary(dirFilePrefix, results);
        catch ME
            gui_error(ME, error_log);
        end

        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end

    %% save mat file
    if saveMat

        % save .mat file in the outputDir
        try
            
            % full path for a mat file:
            matfile_name = sprintf('%sBLINK_MOD.mat', dirFilePrefix);
            save(matfile_name, 'results');
        catch ME
            gui_error(ME, error_log);
        end

        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end

    %% Delete progress bar, enable big buttons
    cleanUp(gd, hWaitBar)

    %% Warn user if low percentile is at floor
    if sum(results.smoothInstBR.lowerPrctilePerm > 0) == 0
        warndlg('Lower percentile of permutation testing is at floor (0).');
    end


catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, error_log);
    cleanUp(gd, hWaitBar)
    return
end

end

%% Deal with the wait bar, re-enable the big buttons
function cleanUp(gd, hWaitBar)
    toggleBigButtons(gd.handles, 'enable');
    if ishandle(hWaitBar)
        delete(hWaitBar);
    end
    gd.setWaitBar([]);
end