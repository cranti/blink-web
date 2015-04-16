function cbChangeSmooth(hObj, eventdata, gd)
% Callback function for blinkGUI.m
%
% Toggles between smoothing approaches (advanced blinkPerm option)

try
    smoothType = get(eventdata.NewValue,'UserData'); %handle to
    
    gd.blinkPermInputs.smoothType = smoothType;
    if strcmpi(smoothType,'sskernel')
        set(gd.handles.hWRange, 'Enable', 'on');
    else
        set(gd.handles.hWRange, 'Enable', 'off');
    end
    
    
catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end

end