function cbLoadBlinks(~, ~, gd)
%CBLOADBLINKS - Load blink data from a csv to prepare for blink permutation
%testing (blinkPerm.m)
%
% - Callback function for blinkGUI.m
% - gd is an instance of BlinkGuiData

% 6.4.2015

try    
    %% choose file dialog box: 

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
    options = {'One participant per column','BinaryMat';
                'Three column format','3col'};
    dlg_title = 'Select Format of Blink Data';
    [formatType, value] = radioDlg(options, dlg_title);
    
    %if user cancels or doesn't select an option
    if ~value || isempty(formatType)
        return
    end
    
    %% Get data length if format is 3col
    if strcmpi(formatType,'3col')
        prompt = {'How many samples were collected?'};
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
        
    elseif strcmpi(formatType,'BinaryMat')
        sampleLen = NaN;
    end
    
    %% Get sample rate
    prompt = {'Enter sample rate (samples/sec):'};
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

    %% Read in file
    try
        rawBlinks = readInBlinks(input_file_full, formatType, sampleLen);
    catch ME
        gui_error(ME, gd.guiSettings.error_log);
        return
    end
    
    %Plot title: input file name, sample rate
    plotTitle = {input_file, sprintf('Sample rate: %s Hz',num2str(sampleRate))};
        
    %% save everything to GUIDATA
    gd.blinkPermInputs.sampleRate = sampleRate;
    gd.blinkPermInputs.rawBlinks = rawBlinks;
    gd.blinkPermInputs.plotTitle = plotTitle;
    gd.blinkPermInputs.filename = input_file_full;
    
    %% Plot instantaneous blink rate - sample rate and input file name are in the title
    try
        cla(gd.handles.hPlotAxes,'reset');
        plotInstBR(rawBlinks, sampleRate, gd.handles.hPlotAxes, plotTitle);
    catch ME
        err = MException('BlinkGUI:plotting','Error plotting instantaneous blink rate.');
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