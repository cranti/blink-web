function [xRange, yRange] = getPsthPlotSize(targetLens, refLens, xRangeCurr, yRangeCurr, scrollDir)
%GETPSTHPLOTSIZE - return size of the plot to show PSTH inputs (target and
%reference data) for blinkGUI.m
%
%
% USAGE: 
%   [xRange, yRange] = getPsthPlotSize(targetLens, refLens)
%       This returns the default PSTH plot size, given lengths of the
%       target and reference event sets, as axis ranges. The default plot
%       size is at most 200 samples (x axis), and at most 10 event sets 
%       (y axis; each set spanning 1 unit around an integer, e.g. the first
%       set is plotted from 0.5-1.5)
%
%           targetLens      Vector with the lengths of each loaded target
%                           set. Pass an empty vector if targets haven't
%                           been loaded. 
%           refLens         Vector with the lengths of each loaded ref set.
%                           Pass an empty vector if refs haven't been
%                           loaded.
%
%   [xRange, yRange] = getPsthPlotSize(targetLens, refLens, xRangeCurr, yRangeCurr, scrollDir)
%       This option changes the current x and y range of the plot in the
%       direction specified by scrollDir. The three additional inputs are:
%
%           xRangeCurr      Current x range of the plot, as [minX, maxX]
%           yRangeCurr      Current y range of the plot, as [minY, maxY]
%           scrollDir       'left', 'right', 'down', or 'up'
%
% 

% Carolyn Ranti
% 4.23.15


%% Plot size: 
xPlotSize = 200; 
yPlotSize = 10;

%% X RANGE
%get maximum x axis size from target events AND reference events (use the
%longest set as the max X)

dataMaxX = [0,0];

if ~isempty(targetLens)
    dataMaxX(1) = max(targetLens);
end

if ~isempty(refLens)
    dataMaxX(2) = max(refLens);
end

dataMaxX = max(dataMaxX);

% POSSIBLE X RANGE:
xRangePoss = [0, dataMaxX];

% DEFAULT X RANGE: 0 to 200 (unless there aren't 200 frames to plot)
xRange = [0, min(dataMaxX, 200)];
    

%% Y RANGE

%if there are target events, plot only the number of target sets (y
%axis limit)
if ~isempty(targetLens)
    dataMaxY = length(targetLens)+.5;

%OTHERWISE, plot all of the reference sets
elseif ~isempty(refLens)
    dataMaxY = length(refLens)+.5;
end
    
% POSSIBLE Y RANGE:
yRangePoss = [.5, dataMaxY];

% DEFAULT Y RANGE: .5 to 10.5 (unless there aren't 10 sets)
yRange = [.5, min(10.5, dataMaxY)];


%% If the last 3 parameters are passed in, see if scrolling is possible.
% If scrolling isn't possible in the specified direction, the current
% ranges are returned

if nargin==5
    xRange = xRangeCurr;
    yRange = yRangeCurr;
    
    switch lower(scrollDir)
        case 'left'
            
            %if we're at the min y already, return the current values
            if min(xRangeCurr) <= min(xRangePoss)
                return
            end
            
            newMin = max(min(xRangeCurr)-xPlotSize, min(xRangePoss));
            newMax = min(newMin+xPlotSize, max(xRangePoss));
            
            xRange = [newMin, newMax];
            
        case 'right'
                
            % if we're at the max x already, return the current values
            if max(xRangeCurr) >= max(xRangePoss)
                return
            end
            
            newMin = max(xRangeCurr);
            newMax = max(xRangeCurr) + xPlotSize;
            
            xRange = [newMin, newMax];

        case 'down'
                        
            % if we're at the min y already, return the current values
            if min(yRangeCurr) <= min(yRangePoss)
                return
            end
            
            newMin = max(min(yRangeCurr)-yPlotSize, min(yRangePoss));
            newMax = min(newMin+yPlotSize, max(yRangePoss));
            
            yRange = [newMin, newMax];
            
        case 'up'
            
            % if we're at the max y already, return the current values
            if max(yRangeCurr) >= max(yRangePoss)
                return
            end
            
            newMax = min(max(yRangeCurr)+yPlotSize, max(yRangePoss));
            newMin = max(newMax-yPlotSize, min(yRangePoss));
            
            yRange = [newMin, newMax];
    end
end