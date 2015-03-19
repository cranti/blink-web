% Call back function for blinkGUI.m
% Toggle between analyses and switch input panels/plotted data as
% appropriate
%
% gd is an instance of BlinkGuiData

function cbAnalysisToggle(~, ~, gd, name)

%color settings
toggleOnColor = 'black';
toggleOffColor = [120 120 120] ./256;


% Permutation testing ON
if strcmpi(name, 'perm')
    
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
    
    %Plot data if it exists
    cla(gd.handles.hPlotAxes, 'reset');
    if ~isempty(gd.blinkPermInputs.rawBlinks) && ~isempty(gd.blinkPermInputs.sampleRate)
        plotInstBR(gd.blinkPermInputs.rawBlinks, gd.blinkPermInputs.sampleRate, gd.handles.hPlotAxes, gd.blinkPermInputs.plotTitle);
    end
    
% PSTH ON
elseif strcmpi(name, 'psth')
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
    
    %Plot data if it exists
    cla(gd.handles.hPlotAxes, 'reset');
    if ~isempty(gd.blinkPsthInputs.targetEvents) || ~isempty(gd.blinkPsthInputs.refEvents)
        % Plot both target data AND reference data
        plotTargetAndRef(gd.blinkPsthInputs, gd.handles.hPlotAxes);
    end
    
end

end
