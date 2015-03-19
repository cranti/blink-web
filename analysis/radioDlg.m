function [selection, value] = radioDlg(options, dlgName)
%
% Two radio buttons in a dialog box.
%
% Written by Carolyn Ranti, modifying Mathworks's listdlg.m as template

%%
if nargin<2
    dlgName ='';
end
% What each radio button should display
radioStrings = options(:,1);

% What the value of the output should be for each button
radioValues = options(:,2);


%% Figure out positioning
% TODO - this size calculation could be a little less hacky
numOpts = size(options,1);

radioOptH = 50;
radioH = numOpts*radioOptH;
buttonH = 40;
boxH = buttonH + radioH;

boxW = 300;

dboxPos = getnicedialoglocation([0 0 boxW boxH],'pixels');

%%
dbox = dialog('Position',dboxPos,...
    'visible','off',...
    'Name',dlgName,...
    'closerequestfcn','delete(gcbf)');

radioGroup = uibuttongroup(dbox,...
    'Units','pixels',...
    'Position',[0 buttonH boxW radioH]);

% Create radio buttons in the button group.
for ii = 1:numOpts

    uicontrol('Style','radiobutton',...
        'String', radioStrings{ii},...
        'UserData', radioValues{ii},...
        'Units','normalized',...
        'pos', [.1 (numOpts-ii)/numOpts .9 1/numOpts],...
        'parent',radioGroup,...
        'HandleVisibility','off');
end


uicontrol(dbox,'Style','pushbutton',...
                   'String','OK',... 
                   'Units','normalized',...
                   'Position',[0 0 .5 buttonH/boxH],...
                   'Callback',{@doOK, radioGroup});

uicontrol(dbox,'Style','pushbutton',...
                       'String','Cancel',... 
                       'Units','normalized',...
                       'Position',[.5 0 .5 buttonH/boxH],...
                       'Callback',{@doCancel});

% Make ok button the default?

% Initialize some properties
set(radioGroup,'SelectedObject',[]);  % No selection
set(radioGroup,'Visible','on');

%make sure we are on screen
movegui(dbox)
set(dbox, 'Visible','on'); 
drawnow;

%
try
    uiwait(dbox);
catch
    if ishghandle(dbox)
        delete(dbox)
    end
end

%
if isappdata(0,'RadioDlgAppData')
    ad = getappdata(0,'RadioDlgAppData');
    selection = ad.selection;
    value = ad.value;
    rmappdata(0,'RadioDlgAppData')
else
    % figure was deleted
    selection = '';
    value = 0;
end


%% OK callback
function doOK(~, ~, radioGroup)
    
    OKad.selection = get(get(radioGroup,'SelectedObject'),'UserData');
    OKad.value = 1;
    
    setappdata(0,'RadioDlgAppData', OKad);
    delete(gcbf);
end

%% Cancel callback
function doCancel(varargin)
    CANCELad.selection = '';
    CANCELad.value = 0;
    setappdata(0,'RadioDlgAppData', CANCELad);
    delete(gcbf);
end

end

