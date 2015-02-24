function instBR = calcInstBR(fractBlinks, sampleRate)
%CALCINSTBR Calculate the instantaneous blink rate of a group
%
% INPUT:
%   fractBlinks Fractional blink data in n x f matrix (TODO - finish doc)
%   sampleRate  Sample rate of data in fractBlinks (in Hz) 
%
% OUTPUT:
%   instBR      Instantaneous blink rate
% 
% Calculate instantaneous blink rate of a group of people, using fractional
% blink data (fractBlinks: rows = subjects, columns = samples, e.g. frames)
% and the sample rate (in Hz). Instantaneous blink rate is in blinks/min.
% NaN values are treated as lost data.

% Carolyn Ranti
% 2.18.15


samplesPerMin = sampleRate*60;
instBR = samplesPerMin * nanmean(fractBlinks,1);



