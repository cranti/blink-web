function cbScrollPerm(~, ~, gd, direction)
%CBSCROLLPERM - Scroll through the x and y axes of the in-app Blink Inhibition plot
%
% INPUTS
%   gd          Instance of BlinkGuiData
%   direction   'left', 'right', 'up', or 'down'

try
    %% Get things out of guidata
    rawBlinks = gd.blinkPermInputs.rawBlinks;
    sampleRate = gd.blinkPermInputs.sampleRate;
    
    if isempty(rawBlinks)
        return
    end
    
    %% Get plot axes
    h = gd.handles.hPlotAxes;
    
    %current xranges:
    xRangeCurr = xlim(h);
    
    % Get this out of GUIDATA? or just maintain same value here and in
    % plotInstBR?
    xPlotSize = 60*sampleRate;
    
    %% Possible X range
    xRangePoss = [0, size(rawBlinks,2)];
    
    %%
    switch lower(direction)
        case 'left'
            if xRangeCurr(1) == xRangePoss(1)
                return
            end
            
            if xRangeCurr(1) > xRangePoss(1)
                newMin = max(xRangeCurr(1)-xPlotSize, 0);
                newMax = min(newMin+xPlotSize, xRangePoss(2));
                xRange = [newMin, newMax];
                xlim(h,xRange);
            end
            
        case 'right'
            if xRangeCurr(2) == xRangePoss(2)
                return
            end
            
            if xRangeCurr(2) < xRangePoss(2)
                xRange = [xRangeCurr(2), xRangeCurr(2) + xPlotSize];
                xlim(h,xRange);
            end
            
    end
    
    
catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end