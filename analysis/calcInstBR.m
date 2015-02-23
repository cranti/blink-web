function instBR = calcInstBR(fractBlinks, sampleRate)
%CALCINSTBR
% 
% Calculate instantaneous blink rate of a group of people, using fractional
% blink data (fractBlinks: rows = subjects, columns = samples, e.g. frames)
% and the sample rate (in Hz). Instantaneous blink rate is in blinks/min.
% NaN values are treated as lost data.

% Carolyn Ranti
% 2.18.15


samplesPerMin = sampleRate*60;
instBR = samplesPerMin * nanmean(fractBlinks,1);



