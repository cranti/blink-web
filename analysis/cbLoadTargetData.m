function cbLoadTargetData(~, ~, gd)
%CBLOADTARGETDATA - Load target data for blink PSTH analysis (blinkPSTH.m).
%
% - Callback function for blinkGUI.m
% - gd is an instance of BlinkGuiData

% 6.5.2015 - sped up readInPsthEvents, removing waitbar!

try
    %% Choose a file (dialog box)
    
    %if there's a "last directory" saved in guidata, cd to it    
    origDir = pwd;
    lastDir = gd.guiSettings.lastDir;
    if isdir(lastDir)
        cd(lastDir)
    end
    
    %pick a file, then cd back to original directory
    [input_file, PathName] = uigetfile('*.csv','Choose a csv file with target data');
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
    dlg_title = 'Select Format of Target Data';
    [formatType, value] = radioDlg(options, dlg_title);
    
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
        options = {'All samples', 'allSamples';
            'First sample only', 'firstSampleOnly';
            'Middle sample only', 'middleSampleOnly';
            'Last sample only', 'lastSampleOnly'};
        [targetEventType, value] = radioDlg(options, 'Select Target Event Type');
        
        %if user cancels
        if ~value
            return
        end
      
        %% Actually read in the data/convert it
        try
            [rawTargetData, targetOrder] = readInPsthEvents(input_file_full, 'SetPerCol');
            targetEvents = getTargetEvents(rawTargetData, targetCode, targetEventType);
            
        catch ME
            gui_error(ME, gd.guiSettings.error_log);
            return
        end
        
        %% for GUIDATA
        targetTitle = sprintf('%s, Event code=%i', input_file, targetCode);
        
    elseif strcmpi(formatType, '3col')
        %% Get data length
        prompt = {'How many samples are in each target set?'};
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
        options = {'All samples', 'allSamples';
            'First sample only', 'firstSampleOnly';
            'Middle sample only', 'middleSampleOnly';
            'Last sample only', 'lastSampleOnly'};
        dlg_title = 'Select Target Event Type';
        [targetEventType, value] = radioDlg(options, dlg_title);
        
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
        
        %% For GUIDATA - NaN if the target data is in 3 column format
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