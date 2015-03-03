function [selection, value] = twoRadioDlg(options)
%
% Two radio buttons in a dialog box.
%
% Written by Carolyn Ranti, modifying Mathworks's listdlg.m as template

%TODO - also pass in parameters such as fontsize, fontname, etc, to have
%this dialog box match the rest of the GUI?

% TODO - fix local var stuff left over from using listdlg as a template


radioStrings = options(:,1);
radioValues = options(:,2);

dbox = dialog('Position',[100 100 300 150],...
    'visible','off',...
    'Name','Select data format',...
    'closerequestfcn','delete(gcbf)');
          
radioGroup = uibuttongroup(dbox,...
    'Units','normalized',...
    'Position',[0 .2 1 .8]);

% Create 2 radio buttons in the button group.
u0 = uicontrol('Style','radiobutton',...
    'String', radioStrings{1},...
    'Units','normalized',...
    'pos',[.1 .5 .9 .5],...
    'parent',radioGroup,...
    'HandleVisibility','off');
u1 = uicontrol('Style','radiobutton',...
    'String',radioStrings{2},...
    'Units','normalized',...
    'pos',[.1 0 .9 .5],...
    'parent',radioGroup,...
    'HandleVisibility','off');

ok_btn = uicontrol(dbox,'Style','pushbutton',...
                   'String','OK',... 
                   'Units','normalized',...
                   'Position',[0 0 .5 .2],... [ffs+fus ffs+fus btn_wid uh],... 'Tag','ok_btn',...
                   'Callback',{@doOK,radioGroup});

cancel_btn = uicontrol(dbox,'Style','pushbutton',...
                       'String','Cancel',... 
                       'Units','normalized',...
                       'Position',[.5 0 .5 .2],... [ffs+2*fus+btn_wid ffs+fus btn_wid uh],... 'Tag','cancel_btn',...
                       'Callback',{@doCancel,radioGroup});

% Make ok_btn the default button.
% setdefaultbutton(dbox, ok_btn);

% Initialize some button group properties.
set(radioGroup,'SelectedObject',[]);  % No selection
set(radioGroup,'Visible','on');

%make sure we are on screen
movegui(dbox)
set(dbox, 'Visible','on'); drawnow;

%
try
    uiwait(dbox);
catch
    if ishghandle(dbox)
        delete(dbox)
    end
end

%
if isappdata(0,'TwoRadioDialogAppData__')
    ad = getappdata(0,'TwoRadioDialogAppData__');
    selection = ad.selection;
    value = ad.value;
    rmappdata(0,'TwoRadioDialogAppData__')
else
    % figure was deleted
    selection = [];
    value = 0;
end


%% OK callback
function doOK(ok_btn, evd, radioGroup)
if (~isappdata(0, 'TwoRadioDialogAppData__'))
    selectionStr = get(get(radioGroup,'SelectedObject'),'String');
    ad.value = 1;
    ad.selection = radioValues{strcmpi(selectionStr,radioStrings)};
    setappdata(0,'TwoRadioDialogAppData__',ad);
    delete(gcbf);
end
end

%% Cancel callback
function doCancel(cancel_btn, evd, radioGroup)
    ad.value = 0;
    ad.selection = [];
    setappdata(0,'TwoRadioDialogAppData__',ad)
    delete(gcbf);
end

end

