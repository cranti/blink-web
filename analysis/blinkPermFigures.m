function blinkPermFigures(prefix, results, figFormat, axesH)
%BLINKPERMFIGURES - Plot the results from blinkPerm.m
%
% INPUTS
%   prefix      Prefix for name of file saved. Can include a path, if you
%               don't want to save in current directory.
%   results     Results struct from blinkPerm.m
%   figFormat   Format for figures. Must be one of the following:
%               'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'
%   axesH       Optional. Vector with an axes handle where results will be
%               plotted. If this is not passed in, or if the handle is NaN,
%               a new figure is created.
%
% If figFormat is empty, results will be plotted, but the figures will
% not be saved.
% 
% See also BLINKPERM

% Written by Carolyn Ranti
% 2.23.2015


%%
narginchk(3,4);

if ~isempty(figFormat)
    assert(sum(strcmp(figFormat,{'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'}))==1,'Invalid figure format.');
end

if nargin < 4 || length(axesH)~=1
    axesH = NaN;
end

try
    numPerms = results.inputs.numPerms;

    %% Figure 1 - Higher and lower blinking

    if isnan(axesH(1))
        figure();
        ax1 = gca;
    else
        ax1 = axesH(1);
    end
    hold(ax1,'on');
    
    legendText = {'Smoothed Blink Rate',...
                sprintf('%.2f percentile', results.lowPrctileLevel),...
                sprintf('%.2f percentile', results.highPrctileLevel)};

    plot(ax1, results.smoothedBR,'k');
    plot(ax1, results.lowPrctile,'b');
    plot(ax1, results.highPrctile,'r');
    
    if ~isempty(results.decreasedBlinking)
        plot(ax1, results.decreasedBlinking, zeros(size(results.decreasedBlinking)),'bo');
        legendText{end+1} = 'Blink Inhibition Frames';
    end
    
    if ~isempty(results.increasedBlinking)
        plot(ax1, results.increasedBlinking, zeros(size(results.increasedBlinking)),'ro');
        legendText{end+1} = 'Higher Blinking Frames';
    end
    
    legend(ax1, legendText);
    title(ax1, {'Blink Rate Modulation',sprintf('%i Permutations',numPerms)});
    xlabel(ax1, 'Frame');
    ylabel(ax1, 'Blink Rate (blinks/min)');

    hold(ax1,'off');

    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting blink modulation results');
    err = addCause(err,ME);
    throw(err);
end


%% Save figure

try
    if ~isempty(figFormat)
        saveas(ax1,[prefix,'BLINK_MOD.',figFormat]);
    end
catch ME
    err = MException('BlinkGUI:plotting', 'Error saving blink modulation figures.');
    err = addCause(err, ME);
    throw(err);
end
