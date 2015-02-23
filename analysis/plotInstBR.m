function plotInstBR(rawBlinks, sampleRate, axesH)

fractBlinks = raw2fractBlinks(rawBlinks);
instBR = calcInstBR(fractBlinks, sampleRate);

if nargin==2
    figure()
    axesH = gca;
end

plot(axesH, instBR, 'k');
hold on
title('Instantaneous Blink Rate')
xlabel('Frame')
ylabel('Blink Rate (blinks/min)')