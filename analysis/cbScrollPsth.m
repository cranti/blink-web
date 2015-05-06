function cbScrollPsth(~, ~, gd, direction)
%CBSCROLLPSTH - Scroll through the x and y axes of the in-app PSTH plot
%
% INPUTS
%   gd          Instance of BlinkGuiData
%   direction   'left', 'right', 'up', or 'down'


try
    %% Get target/ref data
    
    targetEvents = gd.blinkPsthInputs.targetEvents;
    refEvents = gd.blinkPsthInputs.refEvents;
    if isempty(targetEvents) && isempty(refEvents)
        return
    end
     
    refLens = gd.blinkPsthInputs.refLens;
    targetLens = cellfun(@length, targetEvents); % Calculate targetLens
    
    %% Get plot handle and current size of axes
    h = gd.handles.hPlotAxes;
    xRangeCurr = xlim(h);
    yRangeCurr = ylim(h);
  
    %% Set axis ranges and sort option
 
    % defaults - leave as is
    xRange = xRangeCurr;
    yRange = yRangeCurr;
    sortby = gd.blinkPsthInputs.plotSort;
    
    switch lower(direction)
        % NOTE: if scrolling isn't possible in the specified direction,
        % getPsthPlotSize returns the current axis ranges
         
        case 'left'
            [xRange, yRange] = getPsthPlotSize(targetLens, refLens, xRangeCurr, yRangeCurr, 'left');
            
        case 'right'
            [xRange, yRange] = getPsthPlotSize(targetLens, refLens, xRangeCurr, yRangeCurr, 'right');

        case 'down'
            [xRange, yRange] = getPsthPlotSize(targetLens, refLens, xRangeCurr, yRangeCurr, 'down');

        case 'up'
            [xRange, yRange] = getPsthPlotSize(targetLens, refLens, xRangeCurr, yRangeCurr, 'up');

        %SORTING -- reset y to bottom
        case 'sort_ascend'
            sortby = 'ascend';
            gd.blinkPsthInputs.plotSort = 'ascend';
            %reset yRange to default
            [~, yRange] = getPsthPlotSize(targetLens, refLens);
            
        case 'sort_descend'
            sortby = 'descend';
            gd.blinkPsthInputs.plotSort = 'descend';
            %reset yRange to default
            [~, yRange] = getPsthPlotSize(targetLens, refLens);
            
        case 'sort_orig'
            sortby = 'original';
            gd.blinkPsthInputs.plotSort = 'original';
            %reset yRange to default
            [~, yRange] = getPsthPlotSize(targetLens, refLens);
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

