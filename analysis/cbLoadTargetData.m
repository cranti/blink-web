function cbLoadTargetData(~, ~, gd)
%CBLOADTARGETDATA - Load target data for blink PSTH analysis (blinkPSTH.m).
%
% - Callback function for blinkGUI.m
% - gd is an instance of BlinkGuiData

try
    %% Choose a file
    [input_file, PathName] = uigetfile('*.csv','Choose a csv file with target data');
    if input_file == 0
        return
    end
    input_file_full = dirFileJoin(PathName, input_file);
    
    
    %% Dialog box: get file type before loading file
    options = {'One set per column','SetPerCol';
        'Three column format','3col'};
    [formatType, value] = radioDlg(options, 'Select Format of Target Data');
    
    %if user cancels
    if ~value
        return
    end
    
    if strcmpi(formatType, 'SetPerCol')
        %% Get target code
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
        
        %% Get targetEventType with radio dlg box
        %Dialog box: get file type before loading file
        options = {'All frames', 'allFrames';
            'First frame only', 'firstFrameOnly';
            'Middle frame only', 'middleFrameOnly';
            'Last frame only', 'lastFrameOnly'};
        [targetEventType, value] = radioDlg(options, 'Select Target Event Type');
        
        %if user cancels
        if ~value
            return
        end
        
        %% Create a waitbar to let user know that something is happening
        
        hWaitBar = waitbar(0, 'Reading in data...',...
            'Name', 'Please Wait',...
            'CreateCancelBtn', 'setappdata(gcbf,''canceling'',1)');
        
        setappdata(hWaitBar, 'canceling', 0);
        
        %to make sure it's on the screen for at least .5 seconds
        tstart = tic;
        
        %save handle for waitbar in GUIDATA
        gd.setWaitBar(hWaitBar);
        
        % Disable buttons to run analyses or toggle between them
        toggleBigButtons(gd.handles, 'disable');
        
        
        %% Actually read in the data/convert it
        try
            [rawTargetData, targetOrder] = readInPsthEvents(input_file_full, 'SetPerCol', hWaitBar);
            
            %if the user canceled
            if isempty(rawTargetData)
                cleanUp(gd, hWaitBar, tstart);
                return
            end
            
            targetEvents = getTargetEvents(rawTargetData, targetCode, targetEventType);
            
        catch ME
            cleanUp(gd, hWaitBar, tstart);
            gui_error(ME, gd.guiSettings.error_log);
            return
        end
        cleanUp(gd, hWaitBar, tstart);
        
        %% for GUIDATA
        targetTitle = sprintf('%s, Event code=%i', input_file, targetCode);
        
        
    elseif strcmpi(formatType, '3col')
        %% Get data length
        prompt = {'How long are the target sets?'};
        dlg_title = 'Data Length';
        num_lines = 1;
        answer = inputdlg(prompt, dlg_title, num_lines);
        
        %if user cancels or doesn't enter anything
        if isempty(answer)
            return
        end
        
        sampleLen = str2double(answer{1});
        if isnan(sampleLen) || sampleLen<=0
            errordlg('Data length must be a positive number.');
            return
        end
        
        %% Get targetEventType with radio dlg box
        options = {'All frames', 'allFrames';
            'First frame only', 'firstFrameOnly';
            'Middle frame only', 'middleFrameOnly';
            'Last frame only', 'lastFrameOnly'};
        [targetEventType, value] = radioDlg(options, 'Select Target Event Type');
        
        %if user cancels
        if ~value
            return
        end
        
        %% Actually read in data
        try
            [rawTargetData, targetOrder] = readInPsthEvents(input_file_full, '3col', sampleLen);
            targetEvents = getTargetEvents(rawTargetData, 1, targetEventType);
        catch ME
            gui_error(ME, gd.guiSettings.error_log);
            return
        end
        
        %% things to save in GUI data - NaN if the target data is in 3 column format
        targetCode = NaN;
        targetTitle = input_file;
    end
    
    %% Save things to GUIDATA
    gd.blinkPsthInputs.targetEvents = targetEvents;
    gd.blinkPsthInputs.targetOrder = targetOrder;
    gd.blinkPsthInputs.targetCode = targetCode;
    gd.blinkPsthInputs.targetEventType = targetEventType;
    gd.blinkPsthInputs.targetFilename = input_file_full;
    gd.blinkPsthInputs.targetTitle = targetTitle;
    
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

%% Clean up - delete wait dialog, enable big buttons
function cleanUp(gd, hWaitDlg, tstart)
    %make sure dlg is on screen for at least .5 seconds
    while toc(tstart) < .5; end

    toggleBigButtons(gd.handles, 'enable');
    delete(hWaitDlg);
    gd.setWaitBar([]);
end
