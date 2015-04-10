function blinkPSTHFigures(prefix, results, figFormat, axesH)
%BLINKPSTHFIGURES - Plot the results from blinkPSTH.m
%
% Inputs:
%   prefix      Prefix for name of file saved. Can include a path, if you
%               don't want to save in current directory.
%   results     Results struct from blinkPSTH.m
%   figFormat   Optional. Format for figures. Must be one of the following:
%               'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'
%   axesH       Optional. Vector with 2 axes handles where results will be
%               plotted. If this is not passed in, or if any of the handles
%               are NaN, new figures are created as needed.
%
% If figFormat is empty, results will be plotted, but the figures will
% not be saved.
%
% See also BLINKPSTH

% Carolyn Ranti
% 3.19.2015


%%
narginchk(2,4);

if nargin == 2
    figFormat = '';
end

if ~isempty(figFormat)
    assert(sum(strcmp(figFormat,{'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'}))==1,'Invalid figure format.');
end

if nargin < 4 || length(axesH)~=2
    axesH = [NaN NaN];
end

try 
    xValues = (1:length(results.psth)) - (length(results.psth)+1)/2;
    numPerms = results.permTest.numPerms;
    
    %% Figure 1 - bar graph with 5th and 95th percentiles plotted
    
    if isnan(axesH(1))
        figure();
        ax1 = gca;
    else
        ax1 = axesH(1);
    end
    hold(ax1,'on');
    
    % bar graph
    bar(ax1, xValues, results.psth, 'w');
    
    %start legend text:
    legendText = {'Peri-stimulus time histogram'};
    titleText = {'Peri-stimulus time histogram'};
    
    if numPerms > 0
        plot(ax1, xValues, results.permTest.lowPrctile, 'b');
        legendText{end+1} = sprintf('%.2f percentile', results.permTest.lowPrctileLevel);
        
        plot(ax1, xValues, results.permTest.highPrctile, 'r');
        legendText{end+1} = sprintf('%.2f percentile', results.permTest.highPrctileLevel);
        
        %add to title
        titleText{end+1} = sprintf('Number of Permutations=%i', numPerms);
    end
    
    xlim([min(xValues)-1, max(xValues)+1]);
    
    %add a vertical line at the event time
    yrange = ylim(ax1);
    plot(ax1, [0 0], yrange, '--k');
    
    %label plot
    legend(ax1, legendText);
    title(ax1, titleText);
    xlabel(ax1, 'Event offset (samples)');
    ylabel(ax1, 'Average Blink Count');
    
    hold(ax1,'off');
    
    %% Figure 2 - plot results minus the mean from the permutation test
    
    %only do this plot if the perm test has a "mean" field
    if ~isempty(results.permTest.mean)
    
        if isnan(axesH(2))
            figure();
            ax2 = gca;
        else
            ax2 = axesH(2);
        end
        hold(ax2,'on');

        % calculate percent change from mean
        rChangeFromMean = (results.psth - results.permTest.mean)./results.permTest.mean;
        lowChangeFromMean = (results.permTest.lowPrctile - results.permTest.mean)./results.permTest.mean;
        highChangeFromMean = (results.permTest.highPrctile - results.permTest.mean)./results.permTest.mean;
        
        % bar graph
        bar(ax2, xValues, rChangeFromMean, 'w');
        plot(ax2, xValues, lowChangeFromMean, 'b');
        plot(ax2, xValues, highChangeFromMean, 'r');
        
        xlim([min(xValues)-1, max(xValues)+1]);
        
        %add a vertical line at the event time
        yrange = ylim(ax2);
        plot(ax2, [0 0], yrange, '--k');
        
        %label plot
        legend(ax2, {'Peri-stimulus time histogram',...
                    sprintf('%.2f percentile', results.permTest.lowPrctileLevel),...
                    sprintf('%.2f percentile', results.permTest.highPrctileLevel)});
        title(ax2, {'PSTH: Percent Change From Mean',sprintf('Number of Permutations=%i',numPerms)});
        xlabel(ax2, 'Event offset (samples)');
        ylabel(ax2, '% Change From Mean');

        hold(ax2,'off');
    end
    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting PSTH results.');
    err = addCause(err,ME);
    throw(err);
end


%% Save figures

try
    if ~isempty(figFormat)
        saveas(ax1,[prefix,'PSTH.',figFormat]);
        saveas(ax2,[prefix,'PSTHchangeFromMean.',figFormat]);
    end
catch ME
    err = MException('BlinkGUI:plotting', 'Error saving PSTH figures.');
    err = addCause(err, ME);
    throw(err);
end