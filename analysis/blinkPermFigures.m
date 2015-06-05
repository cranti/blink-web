function blinkPermFigures(prefix, results, figFormat, axesH)
%BLINKPERMFIGURES - Plot the results from blinkPerm.m
%
% INPUTS
%   prefix      Prefix for name of file saved. Can include a path, if you
%               don't want to save in current directory.
%   results     Results struct from blinkPerm.m
%   figFormat   Format for figures. Must be one of the following:
%               'eps', 'fig', 'jpg', 'pdf', 'png', 'tif', 'epsc'
%   axesH       Optional. Vector with an axes handle where results will be
%               plotted. If this is not passed in, or if the handle is NaN,
%               a new figure is created.
%
% If figFormat is empty, results will be plotted, but the figures will
% not be saved.
% 
% See also BLINKPERM

% Written by Carolyn Ranti
% 6.5.2015


%%
narginchk(2,4);

if nargin == 2
    figFormat = '';
end

if nargin < 4 || length(axesH)~=1
    axesH = NaN;
end

try

    %% Figure 1 - Higher and lower blinking

    if isnan(axesH(1))
        figure();
        ax1 = gca;
    else
        ax1 = axesH(1);
    end
    hold(ax1,'on');
    
    
    legendText = {'Group Blink Rate',...
                sprintf('%s Percentile', num2str(results.inputs.lowerPrctileCutoff)),...
                sprintf('%s Percentile', num2str(results.inputs.upperPrctileCutoff))};

    plot(ax1, results.smoothInstBR.groupBR, 'k');
    plot(ax1, results.smoothInstBR.lowerPrctilePerm, 'b');
    plot(ax1, results.smoothInstBR.upperPrctilePerm, 'r');
    
    if ~isempty(results.sigBlinkMod.blinkInhib)
        plot(ax1, results.sigBlinkMod.blinkInhib, zeros(size(results.sigBlinkMod.blinkInhib)),'bo');
        legendText{end+1} = 'Blink Inhibition';
    end
    
    if ~isempty(results.sigBlinkMod.incrBlink)
        plot(ax1, results.sigBlinkMod.incrBlink, zeros(size(results.sigBlinkMod.incrBlink)),'ro');
        legendText{end+1} = 'Increased Blinking';
    end
    
    legend(ax1, legendText);
    title(ax1, {'Blink Rate Modulation',sprintf('%i Permutations',results.inputs.numPerms)});
    xlabel(ax1, 'Sample');
    ylabel(ax1, 'Instantaneous Blink Rate (bpm)');

    hold(ax1,'off');

    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting blink modulation results');
    err = addCause(err,ME);
    throw(err);
end


%% Save figure

try
    if ~isempty(figFormat)
        filename = [prefix,'BLINK_MOD.',figFormat];
        
        %need to specify different "format" vs suffix for eps, so that it
        %prints in color
        if strcmpi(figFormat, 'eps')
            figFormat = 'epsc';
        end
        
        saveas(ax1, filename, figFormat);
    end
catch ME
    err = MException('BlinkGUI:plotting', 'Error saving blink modulation figures.');
    err = addCause(err, ME);
    throw(err);
end
