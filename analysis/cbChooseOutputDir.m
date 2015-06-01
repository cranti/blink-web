function cbChooseOutputDir(~, ~, gd)
%CBCHOOSEOUTPUTDIR - Choose an output directory.
%
% Opens a dialog box, starting in the current output directory if one has
% been selected. Sets output dir variable in gd (instance of BlinkGuiData),
% and updates the GUI so that output dir is displayed.
%
% Call back function for blinkGUI.m

try
    %if there's a "last directory" saved in guidata, cd to it    
    origDir = pwd;
    lastDir = gd.guiSettings.lastDir;
    if isdir(lastDir)
        cd(lastDir)
    end
    
    % pick a directory, then cd back to original 
    outputDir = uigetdir(gd.output.dir, 'Choose a folder where results will be saved');
    cd(origDir)
    
    % if user canceled, return
    if outputDir == 0
        return
    end

    %save as output directory
    gd.output.dir = outputDir;
    
    %also save the folder as the "last directory"
    gd.guiSettings.lastDir = outputDir;

    %put name of directory in the box:
    set(gd.handles.hListOutputFile,'String',outputDir,...
        'FontAngle','normal');

    % If the extent of the directory string is greater than the size of
    % the text box, cut down the length (5 characters at a time)
    ex = get(gd.handles.hListOutputFile, 'Extent');
    pos = get(gd.handles.hListOutputFile, 'Position');
    numChars = length(outputDir)-4;
    
    while ex(3) > pos(3)
        set(gd.handles.hListOutputFile, 'String', ['...', outputDir((end-numChars):end)]);
        
        ex = get(gd.handles.hListOutputFile, 'Extent');
        pos = get(gd.handles.hListOutputFile, 'Position');
        numChars = numChars - 5; 
    end
    

catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end

end