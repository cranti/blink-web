function cbChangeSmooth(hObj, eventdata, gd)
% Callback function for blinkGUI.m
%
% Toggles between smoothing approaches (advanced blinkPerm option)


smoothType = get(eventdata.NewValue,'UserData'); %handle to 

gd.blinkPermInputs.smoothType = smoothType;
if strcmpi(smoothType,'sskernel')
    set(gd.handles.hWRange, 'Enable', 'on');
else
    set(gd.handles.hWRange, 'Enable', 'off');
end