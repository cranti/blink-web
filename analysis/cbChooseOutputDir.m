function cbChooseOutputDir(~, ~, gd)
%CBCHOOSEOUTPUTDIR - Choose an output directory.
%
% Opens a dialog box, starting in the current output directory if one has
% been selected. Sets output dir variable in gd (instance of BlinkGuiData),
% and updates the GUI so that output dir is displayed.
%
% Call back function for blinkGUI.m

try
    %opens in current output directory
    outputDir = uigetdir(gd.output.dir, 'Choose a folder where results will be saved');

    if outputDir % if user presses cancel, outputDir = 0

        gd.output.dir = outputDir;

        set(gd.handles.hListOutputFile,'String',outputDir,...
            'FontAngle','normal');

        % If the extent of the directory string is greater than the size of
        % the text box, limit it to 50 characters.
        % (TODO/Future fix - this is hacky)
        ex = get(gd.handles.hListOutputFile, 'Extent');
        pos = get(gd.handles.hListOutputFile, 'Position');

        if ex(3) > pos(3)
            set(gd.handles.hListOutputFile, 'String', ['...', outputDir((end-50):end)]);
        end

    end

catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end

end