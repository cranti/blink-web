function cbCheckSaveFigs(hObj, ~, gd)
% Callback function for blinkGUI.m
% check box: save figures
%
% gd is an instance of BlinkGuiData


try
    gd.output.saveFigs = get(hObj,'Value');
    
    % enable the dropdown fig format menu, if this is checked
    if gd.output.saveFigs
       set(gd.handles.hFigFormat, 'Enable', 'on');
    else
       set(gd.handles.hFigFormat, 'Enable', 'off');
    end
    
    
    %Enable/disable the file prefix box and the choose output dir button
    if gd.output.saveCsv || gd.output.saveFigs || gd.output.saveMat
        set(gd.handles.hOutputFile, 'Enable', 'on');
        set(gd.handles.hChooseOutputDir, 'Enable', 'on');
    else
        set(gd.handles.hOutputFile, 'Enable', 'off');
        set(gd.handles.hChooseOutputDir, 'Enable', 'off');
    end
    
catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end
    
end
