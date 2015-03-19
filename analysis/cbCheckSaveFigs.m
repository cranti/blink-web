% Callback function for blinkGUI.m
% check box: save figures
%
% gd is an instance of BlinkGuiData


function cbCheckSaveFigs(hObj, ~, gd)

    gd.output.saveFigs = get(hObj,'Value');
    
    % enable the dropdown fig format menu, if this is checked
    if gd.output.saveFigs
       set(gd.handles.hFigFormat, 'Enable', 'on');
    else
       set(gd.handles.hFigFormat, 'Enable', 'off');
    end
    
    if gd.output.saveCsv || gd.output.saveFigs || gd.output.saveMat
        set(gd.handles.hOutputFile, 'Enable', 'on');
        set(gd.handles.hChooseOutputDir, 'Enable', 'on');
    else
        set(gd.handles.hOutputFile, 'Enable', 'off');
        set(gd.handles.hChooseOutputDir, 'Enable', 'off');
    end
    
end
