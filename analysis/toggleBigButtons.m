function toggleBigButtons(handles, setting)
%TOGGLEBIGBUTTONS - Disables or enables the analysis toggle buttons and the
%"run analysis" button in the GUI. Used to prevent users from toggling
%between analyses or starting another analysis while one is in progress

switch lower(setting)
    case 'disable'
        set(handles.hGoButton, 'Enable', 'inactive');
        set(handles.hPermToggle, 'Enable', 'inactive');
        set(handles.hPsthToggle, 'Enable', 'inactive');
    case 'enable'
        set(handles.hGoButton, 'Enable', 'on');
        set(handles.hPermToggle, 'Enable', 'on');
        set(handles.hPsthToggle, 'Enable', 'on');
end
end