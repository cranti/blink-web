function cbLoadRefData(~, ~, gd)
%CBLOADREFDATA - Load reference data for blink PSTH analysis
% (blinkPSTH.m).
%
% - Callback function for blinkGUI.m
% - gd is an instance of BlinkGuiData

% 6.5.2015 - sped up readInPsthEvents, removing waitbar!

try    
    %% Get start frame from advanced options
    startFrame = str2double(get(gd.handles.hStartFrameEdit, 'String'));
    if isnan(startFrame) || startFrame <=0
        [~, ok] = warndlgCancel({'Invalid sample start - must be a positive integer.','Press OK to use default (1).'},'Invalid entry','modal', 1);
        if ~ok
            return
        end
        startFrame = 1;
    else
        startFrame = int32(startFrame);
        %this is a catch to make sure that start frame isn't rounded down
        %to 0 by int32 conversion
        if startFrame==0
            startFrame=1;
        end
    end
    set(gd.handles.hStartFrameEdit,'String',startFrame);
    
    %NOTE: this is when startFrame is set in gd.blinkPsthInputs -- if the
    %user changes it between loading reference data and running the
    %analysis, it is switched back to this value for consistency
    gd.blinkPsthInputs.startFrame = startFrame;

    %% Choose a file (dialog box)
   
    %if there's a "last directory" saved in guidata, cd to it    
    origDir = pwd;
    lastDir = gd.guiSettings.lastDir;
    if isdir(lastDir)
        cd(lastDir)
    end
    
    %pick a file, then cd back to original directory
    [input_file, PathName] = uigetfile('*.csv','Choose a csv file with blink data');    
    cd(origDir)
    
    %if user canceled, return
    if input_file == 0
        return
    end
    
    input_file_full = dirFileJoin(PathName, input_file);
    
    %save the folder as the "last directory"
    gd.guiSettings.lastDir = PathName;

    %% Dialog box: get file type before loading file
    options = {'One set per column','SetPerCol';
        'Three column format','3col'};
    dlg_title = 'Select Format of Reference Data';
    [formatType, value] = radioDlg(options, dlg_title);

    %if user cancels
    if ~value
        return
    end

    if strcmpi(formatType, 'SetPerCol')
        %% Get reference code
        prompt = {'Enter reference event code:'};
        dlg_title = 'Reference Event Code';
        num_lines = 1;
        answer = inputdlg(prompt, dlg_title, num_lines);

        %if user cancels or doesn't enter anything
        if iscell(answer) && isempty(answer)
            return
        end

        %if reference code is empty or non-numeric
        refCode = str2double(answer{1});
        if isnan(refCode)
            errordlg('Reference code must be numeric.');
            return
        end

        %% Get refEventType with radio dlg box
        %Dialog box: get file type before loading file
        options = {'All samples', 'allSamples';
            'First sample only', 'firstSampleOnly';
            'Middle sample only', 'middleSampleOnly';
            'Last sample only', 'lastSampleOnly'};
        [refEventType, value] = radioDlg(options, 'Select Reference Event Type');

        %if user cancels
        if ~value
            return
        end

        %% Actually read in the data and convert it

        try
            [rawRefData, refOrder] = readInPsthEvents(input_file_full, 'SetPerCol');
            [refEvents, refLens] = getRefEvents(rawRefData, refCode, refEventType, startFrame);

        catch ME
            gui_error(ME, gd.guiSettings.error_log);
            return
        end

        %% for GUIDATA (title for plot)
        refTitle = sprintf('%s, Event code=%i', input_file, refCode);

    elseif strcmpi(formatType, '3col')
        %% Get data length
        prompt = {'How many samples are in each reference set?'};
        dlg_title = 'Data Length';
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

        %% Get refEventType with radio dlg box
        options = {'All samples', 'allSamples';
            'First sample only', 'firstSampleOnly';
            'Middle sample only', 'middleSampleOnly';
            'Last sample only', 'lastSampleOnly'};
        dlg_title = 'Select Reference Event Type';
        [refEventType, value] = radioDlg(options, dlg_title);

        %if user cancels
        if ~value
            return
        end

        %% Actually read in data
        try
            [rawRefData, refOrder] = readInPsthEvents(input_file_full, '3col', sampleLen);
            [refEvents, refLens] = getRefEvents(rawRefData, 1, refEventType, gd.blinkPsthInputs.startFrame);
        catch ME
            gui_error(ME, gd.guiSettings.error_log);
            return
        end

        %% For GUIDATA - NaN if the ref data is in 3 column format
        refCode = NaN;
        refTitle = input_file;
    end

    %% Save things to GUIDATA
    gd.blinkPsthInputs.refLens = refLens;
    gd.blinkPsthInputs.refEvents = refEvents;
    gd.blinkPsthInputs.refOrder = refOrder;
    gd.blinkPsthInputs.refCode = refCode;
    gd.blinkPsthInputs.refEventType = refEventType;
    gd.blinkPsthInputs.refFilename = input_file_full;
    gd.blinkPsthInputs.refTitle = refTitle;

    %% Plot both target data AND reference data
    try
        cla(gd.handles.hPlotAxes, 'reset');
        plotTargetAndRef(gd.blinkPsthInputs, gd.handles.hPlotAxes);
    catch ME
        err = MException('BlinkGUI:plotting','Error plotting target/reference events.');
        err = addCause(err, ME);
        gui_error(err, gd.guiSettings.error_log);
    end
    
catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end   
    
end