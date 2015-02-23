function error_msg = blinkPermFigures(dirToSave, results, axesH)
%BLINKPERMFIGURES
%
% Optional argument: axesH as vector with 3 figure handles. If any of them
% are NaN, the function will create a new figure
%
% TODO 
% refine figures (legend placement, better titles, axis labels)
% save figures 

% Carolyn Ranti
% 2.18.2015
    
error_msg = '';
origDir = pwd;

try
    cd(dirToSave)
    results.inputValues.numPerms; %TODO - put in titles
 
    
    
    %Figure - smoothed blink rate + decreased blinking + permBR_5thP
    if nargin==2 || isnan(axesH(1))
        figure();
        axes1 = gca;
    else
        axes1 = axesH(1);
    end
    plot(axes1, results.smoothedBR,'k');
    hold on;
    plot(axes1, results.permBR_5thP,'b');
    plot(axes1, results.decreasedBlinking,zeros(size(results.decreasedBlinking)), 'bo')
    %
    legend(axes1, {'Smoothed Blink Rate','5th percentile','Blink Inhibition'});
    title(axes1, 'Blink Inhibition');
    xlabel(axes1, 'Frame');
    ylabel(axes1, 'Blink Rate (blinks/min)');
    
    
    %Figure - smoothed blink rate + increased blinking + permBR_95thP
    if nargin==2 || isnan(axesH(2))
        figure();
        axes2 = gca;
    else
        axes2 = axesH(2);
    end
    plot(axes2, results.smoothedBR,'k');
    hold on;
    plot(axes2, results.permBR_95thP,'r');
    plot(axes2, results.increasedBlinking,zeros(size(results.increasedBlinking)),'ro')
    %
    legend(axes2, {'Smoothed Blink Rate','95th percentile','Higher Blinking'});
    title(axes2, 'Higher Blinking');
    
    %Figure - smoothed blink rate + decr. blinking + permBR_5thP + incr. blinking + permBR_95thP
    figure()
    plot(results.smoothedBR,'k');
    hold on;
    plot(results.permBR_5thP,'b');
    plot(results.permBR_95thP,'r');
    plot(results.decreasedBlinking,zeros(size(results.decreasedBlinking)),'bo')
    plot(results.increasedBlinking,zeros(size(results.increasedBlinking)),'ro')
    legend({'Smoothed Blink Rate','5th percentile','95th percentile',...
                 'Blink Inhibition','Higher Blinking'});
    title('Blink Rate Modulation');
    
catch ME
    error_msg = ME.message;
    cd(origDir);
end

cd(origDir);