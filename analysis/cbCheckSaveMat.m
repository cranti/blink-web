% Callback function for blinkGUI.m
% Check box: save mat file
%
% gd is an instance of BlinkGuiData

function cbCheckSaveMat(hObj, ~, gd)

    gd.output.saveMat = get(hObj,'Value');
    
    if gd.output.saveCsv || gd.output.saveFigs || gd.output.saveMat
        set(gd.handles.hOutputFile, 'Enable', 'on');
        set(gd.handles.hChooseOutputDir, 'Enable', 'on');
    else
        set(gd.handles.hOutputFile, 'Enable', 'off');
        set(gd.handles.hChooseOutputDir, 'Enable', 'off');
    end
    
end
