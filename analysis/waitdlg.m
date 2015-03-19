function h = waitdlg(waitStr, varargin)
%WAITDLG - Info dialog box with an option to have a 'cancel' button. 
%
% Note: this acts like Mathworks's waitbar.m, but there is no progress bar.
%
% Usage: 
%   waitdlg(waitStr, property, value, property, value, ...) 
%
%   waitdlg(waitStr, h) - Updates the string in an existing figure with
%                         handle h
%
% Name/value properties
%   'dlgName'           Title for figure
%   'createmode'        'normal' or 'modal'
%   'createCancelBtn'   Handle to a callback function for a cancel button.
%       It will also be called if the figure is closed (so the figure must
%       be closed with delete(h), just like waitbar)
%

% Carolyn Ranti
% 3.16.15


assert(ischar(waitStr), 'waitdlg can only have one line of text');

%% Format wait text 
% right now, just replacing tabs with spaces
numLines = 1;
waitStr = strrep(waitStr, '\t', '    ');

%% Parse optional inputs and check

% if 2 parameters are passed in, assume that 1st is handle to an existing 
% waitdlg & update the string and return
if nargin==2
    h = varargin{1};
    if ishandle(h)
        set(h, waitStr);
    end
    return
end

assert(mod(length(varargin),2)==0, 'Error - odd number of optional parameters (must be name, value pairs)');

%default
dlgName = 'Wait';
createmode = 'normal';
cancelBtnCreated = 0;

for v = 1:2:length(varargin)
   switch lower(varargin{v})
       case 'name'
           dlgName = varargin{v+1};
       case 'createmode'
           createmode = varargin{v+1};
           assert(sum(strcmpi(createmode,{'normal', 'modal'}))==1, 'createmode must be either normal or modal');
       case 'createcancelbtn'
           cancelFcn = varargin{v+1};
           cancelBtnCreated = 1;
           %NOTE: no error checking for cancel function
   end
end




%% Figure out positioning

if cancelBtnCreated
    buttonH = 30;
else
    buttonH = 10; %this is for padding at the bottom
end

msgH = numLines*40;
topPad = 20;

boxH = buttonH + msgH + topPad;
boxW = 300;

dboxPos = getnicedialoglocation([0 0 boxW boxH],'pixels');

%%
h = dialog('Position',dboxPos,...
    'visible','off',...
    'Name', dlgName,...
    'WindowStyle', createmode);

% Add textbox to dialog
uicontrol(h, 'Style', 'text',...
    'String', waitStr,...
    'HorizontalAlignment', 'center',...
    'Units','normalized',...
    'Position',[.1 buttonH/boxH .8 msgH/boxH]);

% button at the bottom
if cancelBtnCreated
    uicontrol(h,'Style','pushbutton',...
           'String','Cancel',... 
           'Units','normalized',... 
           'Position', [1/3 0 1/3 buttonH/boxH],... 
           'Callback',cancelFcn); 

    %set close request function for the entire figure: 
    set(h,'CloseRequestFcn',cancelFcn);    
end

                   
%make sure we are on screen
movegui(h)
set(h, 'Visible','on'); 
drawnow;

end