function [h, ok] = warndlgCancel(warnStr, dlgName, createmode, cancel)
%WARNDLGCANCEL - Warning dialog box with an option to have a 'cancel'
%button
%
% If 1-3 parameters are passed in, basically acts like MATLAB warning 
% dialog box (but was using Defaultuicontrol properties - TODO fix this!)
%
% If CANCEL is true, also has a 'cancel' button, and outputs true or false
% if the user presses ok or cancel, respectively
%
% Carolyn Ranti
% 3.12.14

% TODO - this may always be modal

narginchk(1,4);

if nargin<2 || isempty(dlgName)
    dlgName = 'Warning';
end

if nargin <3 || isempty(createmode)
    createmode = 'modal';
end

if nargin<4 
    cancel = 0;
end

if cancel
    createmode = 'modal';
end
   

%% Format warning text:
%just replacing tabs with spaces right now

if iscell(warnStr)
    numLines = length(warnStr);
    warnStr = cellfun(@(x) strrep(x, '\t', '    '), warnStr, 'UniformOutput',0);
else
    numLines = 1;
    warnStr = strrep(warnStr, '\t', '    ');
end

%% Figure out positioning

buttonH = 30;
msgH = numLines*40;
topPad = 10;

boxH = buttonH + msgH + topPad;
boxW = 300;

dboxPos = getnicedialoglocation([0 0 boxW boxH],'pixels');

%%
h = dialog('Position',dboxPos,...
    'visible','off',...
    'Name', dlgName,...
    'WindowStyle', createmode,...
    'closerequestfcn','delete(gcbf)');

% Add textbox to dialog
uicontrol(h, 'Style', 'text',...
    'String', warnStr,...
    'Units','normalized',...
    'Position',[.1 buttonH/boxH .8 msgH/boxH]);


if cancel
    OKpos = [0 0 .5 buttonH/boxH];
else
    OKpos = [1/3 0 1/3 buttonH/boxH];
end


% buttons at the bottom
uicontrol(h,'Style','pushbutton',...
       'String','OK',... 
       'Units','normalized',...
       'Position', OKpos,...
       'Callback',{@doOK});

if cancel
    uicontrol(h,'Style','pushbutton',...
           'String','Cancel',... 
           'Units','normalized',...
           'Position',[.5 0 .5 buttonH/boxH],...
           'Callback',{@doCancel});
end
                   
%make sure we are on screen
movegui(h)
set(h, 'Visible','on'); 
drawnow;

%
try
    uiwait(h);
catch
    if ishghandle(h)
        delete(h)
    end
end

%
if isappdata(0,'WarnDlgCancelAppData')
    ok = getappdata(0,'WarnDlgCancelAppData');
    rmappdata(0,'WarnDlgCancelAppData')
else %figure was deleted -- set con to 0
    ok = 0;
end


%% OK callback
function doOK(varargin)
    if (~isappdata(0, 'WarnDlgCancelAppData'))
        setappdata(0,'WarnDlgCancelAppData',1);
        delete(gcbf);
    end
end

%% Cancel callback
function doCancel(varargin)
    setappdata(0,'WarnDlgCancelAppData',0)
    delete(gcbf);
end

end


