function blinkPermFigures(dirToSave, results, figFormat, axesH)
%BLINKPERMFIGURES - Plot the results from blinkPerm.m
%
% Save figures in the format specified by figFormat (OPTIONS: bmp, eps,
% fig, jpg, pdf, png, tif), in the directory specified by dirToSave.
% If figFormat is empty, figures are not saved.
%
% Optional argument: axesH as vector with 3 axes handles. If any of them
% are NaN, the function will create a new figure
%
% TODO 
% refine figures (legend placement, different line formats)
%
% Carolyn Ranti
% 2.23.2015

narginchk(3,4);

if ~isempty(figFormat)
    assert(sum(strcmp(figFormat,{'bmp', 'eps', 'fig', 'jpg', 'pdf', 'png', 'tif'}))==1,'Invalid figure format.');
end

try
    numPerms = results.inputs.numPerms;
 
    %% Figure 1 - smoothed blink rate + decreased blinking + permBR_5thP
    if nargin==3 || isnan(axesH(1))
        figure();
        axes1 = gca;
    else
        axes1 = axesH(1);
    end
    hold(axes1,'on');
    
    plot(axes1, results.smoothedBR,'k');
    plot(axes1, results.permBR_5thP,'b');
    plot(axes1, results.decreasedBlinking,zeros(size(results.decreasedBlinking)), 'bo')
    
    legend(axes1, {'Smoothed Blink Rate','5th percentile','Blink Inhibition'});
    title(axes1, {'Blink Inhibition',sprintf('Number of Permutations=%i',numPerms)});
    xlabel(axes1, 'Frame');
    ylabel(axes1, 'Blink Rate (blinks/min)');


    hold(axes1,'off');
    
    %% Figure 2 - smoothed blink rate + increased blinking + permBR_95thP
    if nargin==3 || isnan(axesH(2))
        figure();
        axes2 = gca;
    else
        axes2 = axesH(2);
    end
    hold(axes2,'on');
    
    plot(axes2, results.smoothedBR,'k');
    plot(axes2, results.permBR_95thP,'r');
    plot(axes2, results.increasedBlinking,zeros(size(results.increasedBlinking)),'ro')
    
    legend(axes2, {'Smoothed Blink Rate','95th percentile','Higher Blinking'});
    title(axes2, {'Higher Blinking',sprintf('Number of Permutations=%i',numPerms)});
    xlabel(axes2, 'Frame');
    ylabel(axes2, 'Blink Rate (blinks/min)');
    
    
    hold(axes2,'off');
    
    %% Figure 3 - smoothed blink rate + decr. blinking + permBR_5thP + incr. blinking + permBR_95thP
    if nargin==3 || isnan(axesH(3))
        figure();
        axes3 = gca;
    else
        axes3 = axesH(3);
    end
    hold(axes3,'on');
    
    plot(axes3, results.smoothedBR,'k');
    plot(axes3, results.permBR_5thP,'b');
    plot(axes3, results.permBR_95thP,'r');
    plot(axes3, results.decreasedBlinking, zeros(size(results.decreasedBlinking)),'bo')
    plot(axes3, results.increasedBlinking, zeros(size(results.increasedBlinking)),'ro')
    
    legend(axes3, {'Smoothed Blink Rate','5th percentile','95th percentile',...
                 'Blink Inhibition','Higher Blinking'});
    title(axes3, {'Blink Rate Modulation',sprintf('Number of Permutations=%i',numPerms)});
    xlabel(axes3, 'Frame');
    ylabel(axes3, 'Blink Rate (blinks/min)');
    
    hold(axes3,'off');
    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting blink modulation results');
    err = addCause(err,ME);
    throw(err);
    
end

%% 
try
    if ~isempty(figFormat)
        origDir = pwd;
        cd(dirToSave);
        saveas(axes1,['LowerBlinking.',figFormat]);
        saveas(axes2,['HigherBlinking.',figFormat]);
        saveas(axes3,['BlinkRateModulation.',figFormat]);
        cd(origDir);
    end
catch ME
    cd(origDir);
    
    err = MException('BlinkGUI:plotting', 'Error saving blink modulation figures.');
    err = addCause(err,ME);
    throw(err);
end
