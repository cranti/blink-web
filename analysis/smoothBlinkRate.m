%SMOOTHBLINKRATE
%
% Calculate the instantaneous blink rate of a group (in blinks/min), using
% fractional blink data (fractBlinks: rows = subjects, columns = samples)
% and the number of samples per minute. Then, smooth that blink rate using
% a window provided by user (Y).
%
% TODO: document, verify
%
% Carolyn Ranti
% 11.24.2014

function smoothedBlinkData = smoothBlinkRate(fractBlinks, samplesPerMin, Y)

instBR = calcInstBR(fractBlinks, samplesPerMin); % blink rate in blinks/min
smoothedBlinkData = conv2_mirrored(instBR, Y);