function cbAnalysisToggle(~, ~, gd, name)
% Call back function for blinkGUI.m
%
% Toggle between analyses and switch input panels/plotted data as
% appropriate. 
%
% INPUTS
%   gd      Instance of BlinkGuiData
%   name    Indicates the analysis selected ('perm' or 'psth')


try 
    %color settings
    toggleOnColor = 'black';
    toggleOffColor = [120 120 120] ./256;


    switch lower(name)

        % Permutation testing ON
        case 'perm'

            %set perm toggle on, psth toggle off
            set(gd.handles.hPermToggle, 'Value', 1,...
                'FontWeight', 'bold',...
                'ForegroundColor', toggleOnColor);
            set(gd.handles.hPsthToggle, 'Value', 0, ...
                'FontWeight', 'normal',...
                'ForegroundColor', toggleOffColor);

            %Toggle the panels
            set(gd.handles.hPermInputPanel, 'Visible', 'on');
            set(gd.handles.hPsthInputPanel, 'Visible', 'off');

            %set button callback
            set(gd.handles.hGoButton, 'Callback', {@cbRunBlinkPerm gd});

            %% Plot data if it exists
            cla(gd.handles.hPlotAxes, 'reset');

            set(gd.handles.hPlotAxes, 'uicontextmenu', gd.handles.hPermAxesMenu);
            set(gd.handles.hScrollRight, 'Callback', {@cbScrollPerm gd 'right'});
            set(gd.handles.hScrollLeft, 'Callback', {@cbScrollPerm gd 'left'});

            if ~isempty(gd.blinkPermInputs.rawBlinks) && ~isempty(gd.blinkPermInputs.sampleRate)
                plotInstBR(gd.blinkPermInputs.rawBlinks, gd.blinkPermInputs.sampleRate, gd.handles.hPlotAxes, gd.blinkPermInputs.plotTitle);
            end

        % PSTH ON
        case 'psth'
            %set perm toggle on, psth toggle off
            set(gd.handles.hPsthToggle, 'Value', 1,...
                'FontWeight', 'bold',...
                'ForegroundColor', toggleOnColor);
            set(gd.handles.hPermToggle, 'Value', 0, ...
                'FontWeight', 'normal',...
                'ForegroundColor', toggleOffColor);

            %Toggle the panels
            set(gd.handles.hPsthInputPanel, 'Visible', 'on');
            set(gd.handles.hPermInputPanel, 'Visible', 'off');

            %set button callback
            set(gd.handles.hGoButton, 'Callback', {@cbRunBlinkPSTH gd});

            %% Plot data if it exists
            cla(gd.handles.hPlotAxes, 'reset');

            set(gd.handles.hPlotAxes, 'uicontextmenu', gd.handles.hPsthAxesMenu);
            set(gd.handles.hScrollRight, 'Callback', {@cbScrollPsth gd 'right'});
            set(gd.handles.hScrollLeft, 'Callback', {@cbScrollPsth gd 'left'});

            if ~isempty(gd.blinkPsthInputs.targetEvents) || ~isempty(gd.blinkPsthInputs.refEvents)
                
                % reset the sortby option in gd to original
                sortby = 'original';
                gd.blinkPsthInputs.plotSort = sortby;
                
                 % Plot both target data AND reference data
                plotTargetAndRef(gd.blinkPsthInputs, gd.handles.hPlotAxes,...
                    'sortby', sortby);
            end

    end
        
catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end

end
