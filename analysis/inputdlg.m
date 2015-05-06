function [answer] = inputdlg(prompt, dlg_title, varargin)
%INPUTDLG - Dialog box with a text prompt, an editable text box, and
%OK/Cancel buttons
%
% - Overwriting MATLAB inputdlg.m for blinkGUI.m
% - If the user clicks the Cancel button or closes the box, the dialog
%   returns an empty cell array
% - NOTE: only writing this to accept ONE single-line prompt, which is all
%   that blinkGUI.m needs
% - Also note that blinkGUI scripts specify num_lines (3rd input), which is
%   no longer necessary/doing anything
%
% Carolyn Ranti
% 4.23.2015

%%
if nargin<2
    dlg_title = '';
end

%% Figure out positioning

topPad = 10; %top padding
labelH = 30; % height for the prompt
textBoxH = 30; %text box height
buttonPad = 10; %padding between text box and button
buttonH = 40; %ok/cancel buttons
boxH = topPad + labelH + textBoxH + buttonPad + buttonH; 
boxW = 250;

dboxPos = getnicedialoglocation([0 0 boxW boxH],'pixels');


%%
dbox = dialog('Position',dboxPos,...
        'visible','off',...
        'Name',dlg_title,...
        'closerequestfcn','delete(gcbf)');

%Text prompt
labelPos = [5, buttonH + textBoxH + buttonPad, boxW-10, labelH];
uicontrol(dbox,...
        'Style', 'text',...
        'String', prompt{1},...
        'Units', 'pixels',...
        'Position', labelPos);

%Editable input box
textBoxPos = [5, buttonH + buttonPad, boxW-10, textBoxH];
textBox = uicontrol(dbox,...
        'Style', 'edit',...
        'Background', 'white',...
        'Units', 'pixels',...
        'Position', textBoxPos);

%OK button
uicontrol(dbox,'Style','pushbutton',...
        'String','OK',... 
        'Units','normalized',...
        'Position',[0 0 .5 buttonH/boxH],...
        'Callback',{@doOK, textBox});

%Cancel button
uicontrol(dbox,'Style','pushbutton',...
        'String','Cancel',... 
        'Units','normalized',...
        'Position',[.5 0 .5 buttonH/boxH],...
        'Callback',{@doCancel});

                   
%make sure we are on screen
movegui(dbox)
set(dbox, 'Visible','on'); 
drawnow;

               
try
    uiwait(dbox);
catch
    if ishghandle(dbox)
        delete(dbox)
    end
end    


%
if isappdata(0,'InputDlgAppData')
    ad = getappdata(0,'InputDlgAppData');
    answer = ad.answer;
    rmappdata(0,'InputDlgAppData')

else % figure was deleted
    answer = {};
end

%% OK callback
function doOK(~, ~, textBox)
    OKad.answer = {get(textBox,'String')};
    setappdata(0,'InputDlgAppData', OKad);
    delete(gcbf);
end

%% Cancel callback
function doCancel(varargin)
    CANCELad.answer = {};
    setappdata(0,'InputDlgAppData', CANCELad);
    delete(gcbf);
end

end

