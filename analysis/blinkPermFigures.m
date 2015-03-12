function blinkPermFigures(prefix, results, figFormat, axesH)
%BLINKPERMFIGURES - Plot the results from blinkPerm.m
%
% INPUTS
%   prefix      Prefix for name of file saved. Can include a path, if you
%               don't want to save in current directory.
%   results     Results struct from blinkPerm.m
%   figFormat   Format for figures. Must be one of the following:
%               'bmp', 'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'
%   axesH       Optional. Vector with an axis handle, specifying where 
%               results will be plotted. If any of them are NaN, a 
%               new figure will be created for that plot.
%
% If figFormat is empty, results will be plotted, but the figures will
% not be saved.
% 
% See also BLINKPERM

% Written by Carolyn Ranti
% 2.23.2015

narginchk(3,4);

if ~isempty(figFormat)
    assert(sum(strcmp(figFormat,{'bmp', 'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'}))==1,'Invalid figure format.');
end

try
    numPerms = results.inputs.numPerms;

    %% Figure 1 - Higher and lower blinking (smoothed blink rate + decr. blinking + permBR_5thP + incr. blinking + permBR_95thP)

    if nargin==3 || isnan(axesH(1))
        figure();
        axes1 = gca;
    else
        axes1 = axesH(1);
    end
    hold(axes1,'on');
    
    legendText = {'Smoothed Blink Rate',...
                sprintf('%.2f percentile', results.lowPrctileLevel),...
                sprintf('%.2f percentile', results.highPrctileLevel)};

    plot(axes1, results.smoothedBR,'k');
    plot(axes1, results.lowPrctile,'b');
    plot(axes1, results.highPrctile,'r');
    if ~isempty(results.decreasedBlinking)
        plot(axes1, results.decreasedBlinking, zeros(size(results.decreasedBlinking)),'bo');
        legendText{end+1} = 'Blink Inhibition';
    end
    if ~isempty(results.increasedBlinking)
        plot(axes1, results.increasedBlinking, zeros(size(results.increasedBlinking)),'ro');
        legendText{end+1} = 'Higher Blinking';
    end
    legend(axes1, legendText);
    title(axes1, {'Blink Rate Modulation',sprintf('Number of Permutations=%i',numPerms)});
    xlabel(axes1, 'Frame');
    ylabel(axes1, 'Blink Rate (blinks/min)');

    hold(axes1,'off');
    
  
%% Figure 2 - Higher blinking (smoothed blink rate + increased blinking + permBR_95thP)

%     if nargin==3 || isnan(axesH(2))
%         figure();
%         axes2 = gca;
%     else
%         axes2 = axesH(2);
%     end
%     hold(axes2,'on');
% 
%     plot(axes2, results.smoothedBR,'k');
%     plot(axes2, results.prctile95,'r');
%     plot(axes2, results.increasedBlinking,zeros(size(results.increasedBlinking)),'ro')
% 
%     legend(axes2, {'Smoothed Blink Rate','95th percentile','Higher Blinking'});
%     title(axes2, {'Higher Blinking',sprintf('Number of Permutations=%i',numPerms)});
%     xlabel(axes2, 'Frame');
%     ylabel(axes2, 'Blink Rate (blinks/min)');
% 
% 
%     hold(axes2,'off');
    
    %% Figure 3 - Blink Inhibition (smoothed blink rate + decreased blinking + permBR_5thP)

%     if nargin==3 || isnan(axesH(3))
%         figure();
%         axes3 = gca;
%     else
%         axes3 = axesH(1);
%     end
%     hold(axes3,'on');
% 
%     plot(axes3, results.smoothedBR,'k');
%     plot(axes3, results.prctile05,'b');
%     plot(axes3, results.decreasedBlinking,zeros(size(results.decreasedBlinking)), 'bo')
% 
%     legend(axes3, {'Smoothed Blink Rate','5th percentile','Blink Inhibition'});
%     title(axes3, {'Blink Inhibition',sprintf('Number of Permutations=%i',numPerms)});
%     xlabel(axes3, 'Frame');
%     ylabel(axes3, 'Blink Rate (blinks/min)');
% 
% 
%     hold(axes3,'off');
    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting blink modulation results');
    err = addCause(err,ME);
    throw(err);
end

%%
try
    if ~isempty(figFormat)
        saveas(axes1,sprintf('%sBlinkRateModulation.%s',prefix,figFormat));
%         saveas(axes2,[prefix, 'HigherBlinking.',figFormat]);
%         saveas(axes3,[prefix, 'LowerBlinking.',figFormat]);
    end
catch ME
    err = MException('BlinkGUI:plotting', 'Error saving blink modulation figures.');
    err = addCause(err,ME);
    throw(err);
end
