% Callback function for blinkGUI.m
% check box: save csv file
%
% gd is an instance of BlinkGuiData

function cbCheckSaveCsv(hObj, ~, gd)
    
    gd.output.saveCsv = get(hObj,'Value');
    
    if gd.output.saveCsv || gd.output.saveFigs || gd.output.saveMat
        set(gd.handles.hOutputFile, 'Enable', 'on');
        set(gd.handles.hChooseOutputDir, 'Enable', 'on');
    else
        set(gd.handles.hOutputFile, 'Enable', 'off');
        set(gd.handles.hChooseOutputDir, 'Enable', 'off');
    end
    
end