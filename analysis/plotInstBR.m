function plotInstBR(rawBlinks, sampleRate, axesH)
%PLOTINSTBR - Plot instantaneous blink rate in an axis (axesH) given raw
% blink data (rawBlinks) and a sample rate (sampleRate).
%
% Carolyn Ranti

fractBlinks = raw2fractBlinks(rawBlinks);
instBR = calcInstBR(fractBlinks, sampleRate);

if nargin==2
    figure()
    axesH = gca;
end
hold(axesH,'on');

plot(axesH, instBR, 'k');
title('Instantaneous Blink Rate')
xlabel('Frame')
ylabel('Blink Rate (blinks/min)')