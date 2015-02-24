function blinkPSTHFigures(dirToSave, results, figFormat, axesH)
%BLINKPSTHFIGURES - Plot the results from blinkPSTH.m
%
% Inputs:
%   dirToSave   Path to directory where figures will be saved.
%   results     Results struct from blinkPSTH.m
%   figFormat   Format for figures. Must be one of the following:
%               'bmp', 'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'
%   axesH       Optional. Axis handle where results will be plotted.
%               If this is not passed in, a new figure is created.
%
% If figFormat is empty, results will be plotted, but the figures will
% not be saved.
%
% See also BLINKPSTH

% Carolyn Ranti
% 2.23.2015

narginchk(3,4);

if ~isempty(figFormat)
    assert(sum(strcmp(figFormat,{'bmp', 'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'}))==1,'Invalid figure format.');
end

try 
    xValues = length(results.crossCorr) - (length(results.crossCorr)+1)/2;
    numPerms = results.inputs.numPerms;
    
    %% Figure - bar graph with 5th and 95th percentiles plotted
    if nargin == 4
        figure();
        axesH = gca;
    end
    hold(axesH,'on');
    
    % bar graph
    bar(axesH, xValues, results.crossCorr, 'k');
    plot(axesH, xValues, results.prctile05, 'b');
    plot(axesH, xValues, results.prctile95, 'r');
    
    legend(axesH, {'Peri-stimulus time histogram','5th percentile','95th percentile'});
    title(axesH, {'Peri-stimulus time histogram',sprintf('Number of Permutations=%i',numPerms)});
    xlabel(axesH, 'Event offset (frames)');
    ylabel(axesH, 'Blink rate (blinks/min)');
    
    hold(axesH,'off');
    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting peri-stimulus time histogram.');
    err = addCause(err,ME);
    throw(err);
end

%% 
try
    if ~isempty(figFormat)
        origDir = pwd;
        cd(dirToSave);
        saveas(axesH,['PSTH.',figFormat]);
        cd(origDir);
    end
catch
    cd(origDir);

    err = MException('BlinkGUI:plotting', 'Error saving peri-stimulus time histogram figures.');
    err = addCause(err,ME);
    throw(err);
end