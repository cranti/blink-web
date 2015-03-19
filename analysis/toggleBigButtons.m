%TODO - check that this still works with class switchover...
function toggleBigButtons(handles, setting)
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