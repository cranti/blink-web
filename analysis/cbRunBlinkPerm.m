function cbRunBlinkPerm(~, ~, gd)
%CBRUNPERM - run blink permutation testing. Callback function for blinkGUI.m
%
%

try
    %% Get all variables that we'll be using out of gd/gui

    % Raw blink data
    rawBlinks = gd.blinkPermInputs.rawBlinks;

    % Sample rate
    sampleRate = gd.blinkPermInputs.sampleRate;

    % Number of permutations
    numPerms = str2double(get(gd.handles.hNumPerms, 'String'));

    % Significance thresholds
    sigHigh = str2double(get(gd.handles.hSigHighPerm,'String'));
    sigLow = str2double(get(gd.handles.hSigLowPerm,'String'));
    sigFrames = str2double(get(gd.handles.hSigFrames, 'String'));

    % W range to try in sskernel
    wString = get(gd.handles.hWRange, 'String');

    % What to save
    saveMat = gd.output.saveMat;
    saveCsv = gd.output.saveCsv;
    saveFigs = gd.output.saveFigs;

    % Output things
    outputDir = gd.output.dir;
    outputPrefix = get(gd.handles.hOutputFile,'String'); %TODO - there is currently no error checking here - remove /\. ?
    figFormat = gd.output.figFormat;
    input_file = gd.blinkPermInputs.filename;


    %% Check inputs
    error_msgs = {};

    % RAW BLINK DATA & SAMPLE RATE (loaded in the same process)
    if isempty(rawBlinks) || isempty(sampleRate)
        error_msgs{end+1} = '\tNo data was loaded.';
    end

    % NUMBER OF PERMUTATIONS
    if isnan(numPerms) || numPerms<=0
        error_msgs{end+1} = '\tNumber of permutations must be a positive number';
    elseif numPerms > gd.guiSettings.maxPerms
        error_msgs{end+1} = sprintf('\tMaximum number of permutations= %i',gd.guiSettings.maxPerms);
    else
        numPerms = int32(numPerms);
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
    if isempty(wString)
        wRange = [];
    else

        wWarning = 0; %boolean -- true if something goes wrong

        wStrSplit = strsplit(wString, ':');

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
            [~, cont] = warndlgCancel({'Invalid W range: must be a numeric value or range of values (e.g. 1:10 or 1:2:10)','Press OK to use default (none).'}, 'Invalid Entry', 'modal', 1);
            if ~cont
                return
            end

            set(gd.handles.hWRange, 'String', '');
            wRange = [];

        % Otherwise, set up W range
        elseif length(Wvalues)==1
            wRange = Wvalues;
        elseif length(Wvalues)==2
            wRange = Wvalues(1):Wvalues(2);
        elseif length(Wvalues)==3
            wRange = Wvalues(1):Wvalues(2):Wvalues(3);
        end
    end


    % SIGNIFICANCE THRESHOLDS
    if isnan(sigLow) || sigLow>=100 || sigLow<=0
        [~, cont] = warndlgCancel({'Invalid lower significance threshold.', 'Press OK to use default (2.5)'}, 'Invalid Entry', 'modal', 1);
        if ~cont
            return
        end
        set(gd.handles.hSigLowPerm,'String','2.5');
        sigLow = 2.5;
    end

    if isnan(sigHigh) || sigHigh>=100 || sigHigh<=0
        [~, cont] = warndlgCancel({'Invalid upper significance threshold.', 'Press OK to use default (97.5)'}, 'Invalid Entry', 'modal', 1);
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
            'lowPrctile', sigLow,...
            'highPrctile', sigHigh,...
            'sigFrameThr', sigFrames,...
            'W', wRange,...
            'hWaitBar', hWaitBar);
    catch ME 
        cleanUp(gd, hWaitBar)
        gui_error(ME, gd.guiSettings.error_log);
        return
    end

    % if analysis is canceled, exit
    if isempty(results)
        cleanUp(gd, hWaitBar)
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

        if saveFigs
            thingsSaved = thingsSaved + 1;
            waitbar(thingsSaved/thingsToSave, hWaitBar);
        end
    catch ME
        gui_error(ME, gd.guiSettings.error_log);
    end



    %% summary file
    if saveCsv

        % output csv summary file
        try
            blinkPermSummary(dirFilePrefix, results, input_file);
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
            %add input file name to the results struct
            results.inputs.filename = input_file;
            
            % full path for a mat file:
            matfile_name = sprintf('%sBLINK_MOD.mat', dirFilePrefix);
            save(matfile_name, 'results');
        catch ME
            gui_error(ME, gd.guiSettings.error_log);
        end

        thingsSaved = thingsSaved + 1;
        waitbar(thingsSaved/thingsToSave, hWaitBar);
    end

    %% Delete progress bar, enable big buttons
    cleanUp(gd, hWaitBar)

    %% Warn user if low percentile is at floor
    if sum(results.lowPrctile > 0) == 0
        warndlg('Lower percentile of permutation testing is at floor (0).');
    end


catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end

end

%% Deal with the wait bar, re-enable the big buttons
function cleanUp(gd, hWaitBar)
    toggleBigButtons(gd.handles, 'enable');
    delete(hWaitBar);
    gd.setWaitBar([]);
end