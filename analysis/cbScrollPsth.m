function cbScrollPsth(~, ~, gd, direction)
%CBSCROLLPSTH - Scroll through the x and y axes of the in-app PSTH plot
%
% INPUTS
%   gd          Instance of BlinkGuiData
%   direction   'left', 'right', 'up', or 'down'


try
    %% Get things out of guidata
    targetEvents = gd.blinkPsthInputs.targetEvents;
    refEvents = gd.blinkPsthInputs.refEvents;
    
    if isempty(targetEvents) && isempty(refEvents)
        return
    end
    
    %% Get plot axes
    h = gd.handles.hPlotAxes;
    
    %current xranges:
    xRangeCurr = xlim(h);
    yRangeCurr = ylim(h); %figure out...
    
    % GET the psth plot size out of GUIDATA? or just maintain same value here
    % and in plotTargetAndRef
    xPlotSize = 200;
    yPlotSize = 10;
    
    %% Possible X range
    
    %possible xrange:
    if ~isempty(targetEvents)
        maxX = max(cellfun(@length,targetEvents));
    elseif ~isempty(refEvents)
        maxX = max(refSetLen);
    end
    xRangePoss = [0 maxX];
    
    
    %% Possible Y range
    
    %possible xrange:
    if ~isempty(targetEvents)
        maxY = length(targetEvents)+.5;
    elseif ~isempty(refEvents)
        maxY = length(refEvents)+.5;
    end
    yRangePoss = [.5 maxY];
    
    %%
    
    % defaults - leave as is
    xRange = xRangeCurr;
    yRange = yRangeCurr;
    sortby = gd.blinkPsthInputs.plotSort;
    
    switch lower(direction)
        case 'left'
            if min(xRangeCurr) <= min(xRangePoss)
                return
            end
            
            newMin = max(min(xRangeCurr)-xPlotSize, min(xRangePoss));
            newMax = min(newMin+xPlotSize, max(xRangePoss));
            xRange = [newMin, newMax];
            
        case 'right'
            if max(xRangeCurr) >= max(xRangePoss)
                return
            end
            
            xRange = [max(xRangeCurr), max(xRangeCurr) + xPlotSize];
            
        case 'down'
            
            if min(yRangeCurr) <= min(yRangePoss)
                return
            end
            
            newMin = max(min(yRangeCurr)-yPlotSize, min(yRangePoss));
            newMax = min(newMin+yPlotSize, max(yRangePoss));
            yRange = [newMin, newMax];
            
        case 'up'
            if max(yRangeCurr) >= max(yRangePoss)
                return
            end
            
            yRange = [max(yRangeCurr), max(yRangeCurr) + yPlotSize];
            
            %SORTING -- reset y to bottom
        case 'sort_ascend'
            sortby = 'ascend';
            gd.blinkPsthInputs.plotSort = 'ascend';
            yRange = [.5 .5+yPlotSize];
            
        case 'sort_descend'
            sortby = 'descend';
            gd.blinkPsthInputs.plotSort = 'descend';
            yRange = [.5 .5+yPlotSize];
            
        case 'sort_orig'
            sortby = 'original';
            gd.blinkPsthInputs.plotSort = 'original';
            yRange = [.5 .5+yPlotSize];
    end
    
    cla(gd.handles.hPlotAxes, 'reset');
    plotTargetAndRef(gd.blinkPsthInputs, h, ...
        'xrange', xRange,...
        'yrange', yRange,...
        'sortby', sortby);
    
    
catch ME % Catch and log any errors that weren't dealt with
    err = MException('BlinkGUI:unknown', 'Unknown error');
    err = addCause(err, ME);
    gui_error(err, gd.guiSettings.error_log);
    return
end

