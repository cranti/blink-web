function blinkPSTHFigures(dirToSave, results, yText, figFormat, axesH)
%BLINKPSTHFIGURES - Plot the results from blinkPSTH.m
%
% Save figures in the format specified by figFormat (OPTIONS: bmp, eps,
% fig, jpg, pdf, png, tif), in the directory specified by dirToSave.
% If figFormat is empty, figures are not saved.
%
% Optional argument: axesH as vector with an axes handle, where results
% will be plotted. If not passed in, a new figure will be created.
%
% Carolyn Ranti
% 2.23.2015

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
    ylabel(axesH, yText);
    
    hold(axesH,'off');
    
catch
    error('Error plotting peri-stimulus time histogram.');
end

%% 
try
    if ~isempty(figFormat)
        origDir = pwd;
        cd(dirToSave);
        saveas(axesH,['PSTH',figFormat]);
        cd(origDir);
    end
catch
    cd(origDir);
    error('Error saving peri-stimulus time histogram figures.');
end