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

%% Calculate inst BR and plot
fractBlinks = raw2fractBlinks(rawBlinks);
instBR = calcInstBR(fractBlinks, sampleRate);
plot(axesH, instBR, 'k');


%% Plot at most 60 seconds

maxX = min(sampleRate*60, length(instBR));
xlim([0, maxX]);
ylim([0, max(instBR)]);


%% Label plot

if nargin < 4 || isempty(titleText)
	title('Instantaneous Blink Rate');
else
	title({'Instantaneous Blink Rate',titleText{:}},'Interpreter','none'); 
end
xlabel('Time (sec)')
ylabel('Blink Rate (blinks/min)')

% set x ticks:
xticks = 0:(5*sampleRate):(length(instBR));
xticklabels = xticks./sampleRate;
set(axesH, 'XTick', xticks, 'XTickLabel', xticklabels);
