function cbScrollPerm(~, ~, gd, direction)

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