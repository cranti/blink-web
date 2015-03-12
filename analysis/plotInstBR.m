function plotInstBR(rawBlinks, sampleRate, axesH, titleText)
%PLOTINSTBR - 
%
% Plot instantaneous blink rate in an axis (axesH) given raw blink data
% (rawBlinks) and a sample rate (sampleRate).
% Optional input

% Carolyn Ranti
% 2.24.2015



if nargin<3 || isempty(axesH)
    figure()
    axesH = gca;
end
hold(axesH,'on');

%Calculate inst BR and plot
fractBlinks = raw2fractBlinks(rawBlinks);
instBR = calcInstBR(fractBlinks, sampleRate);
plot(axesH, instBR, 'k');

%Label plot
if nargin < 4 || isempty(titleText)
	title('Instantaneous Blink Rate');
else
	title({'Instantaneous Blink Rate',titleText{:}},'Interpreter','none'); 
end
xlabel('Sample #')
ylabel('Blink Rate (blinks/min)')