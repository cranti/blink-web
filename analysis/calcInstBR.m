%CALCINSTBR
% 
% Calculate instantaneous blink rate of a group of people, using fractional
% blink data (fractBlinks: rows = subjects, columns = samples, e.g. frames)
% and the number of samples per minute. 
% Blink rate is in blinks/min. Treats NaNs as lost data.
%
% Carolyn Ranti
% 11.24.2014

function instBR = calcInstBR(fractBlinks, samplesPerMin)

instBR = samplesPerMin * nanmean(fractBlinks,1);



