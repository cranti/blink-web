function toggleBigButtons(handles, setting)
%TOGGLEBIGBUTTONS - Disables or enables the analysis toggle buttons and the
%"run analysis" button in the GUI. Used to prevent users from toggling
%between analyses or starting another analysis while one is in progress
%
% Edited 6/1/2015

switch lower(setting)
    case 'disable'
        enableKey = 'inactive';
    case 'enable'
        enableKey = 'on';
    otherwise
        return
end

%"Go" button
set(handles.hGoButton, 'Enable', enableKey);

%Toggle buttons
set(handles.hPermToggle, 'Enable', enableKey);
set(handles.hPsthToggle, 'Enable', enableKey);

%Reset buttons
set(handles.hPermReset, 'Enable', enableKey);
set(handles.hPsthReset, 'Enable', enableKey);

%Load data
set(handles.hLoadBlinkFile, 'Enable', enableKey);
set(handles.hLoadTargetEvents, 'Enable', enableKey);
set(handles.hLoadRefEvents, 'Enable', enableKey);

%Choose output dir
set(handles.hChooseOutputDir, 'Enable', enableKey);

end