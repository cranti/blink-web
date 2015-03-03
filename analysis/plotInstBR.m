function plotInstBR(rawBlinks, sampleRate, axesH, titleText)
%PLOTINSTBR - 
%
% Plot instantaneous blink rate in an axis (axesH) given raw blink data
% (rawBlinks) and a sample rate (sampleRate).
% Optional input

% Carolyn Ranti
% 2.24.2015

fractBlinks = raw2fractBlinks(rawBlinks);
instBR = calcInstBR(fractBlinks, sampleRate);

if nargin==2 || isempty(axesH)
    figure()
    axesH = gca;
end
hold(axesH,'on');

plot(axesH, instBR, 'k');
if nargin == 3 || isempty(axesH)
	title('Instantaneous Blink Rate');
else
	title({'Instantaneous Blink Rate',titleText{:}}); %todo - does this work?
end
xlabel('Sample #')
ylabel('Blink Rate (blinks/min)')