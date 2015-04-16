function cbCheckSaveMat(hObj, ~, gd)
% Callback function for blinkGUI.m
% Check box: save mat file
%
% gd is an instance of BlinkGuiData


try
    gd.output.saveMat = get(hObj,'Value');
    
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
