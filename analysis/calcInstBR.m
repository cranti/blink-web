function instBR = calcInstBR(fractBlinks, sampleRate)
%CALCINSTBR Calculate the instantaneous blink rate of a group
%
% INPUT:
%   fractBlinks Fractional blink data in n x f matrix.
%   sampleRate  Sample rate of data in fractBlinks (in Hz) 
%
% OUTPUT:
%   instBR      Instantaneous blink rate
% 
% Calculate instantaneous blink rate of a group of people, using fractional
% blink data (fractBlinks: rows = subjects, columns = samples, e.g. frames)
% and the sample rate (in Hz). Instantaneous blink rate is in blinks/min.
% NaN values are treated as lost data.
%
% Fractional blink data:  A positive number indicates the occurrence of a
% blink at a time point. Fractional blinks take into account the duration
% of the blink over time: if a blink occurs over 4 frames, those 4
% consecutive frames will each have a value of .25 in the matrix.
% Therefore, the sum of a participant's fractional blinks is equal to the
% number of times they blinked.
% The other possible values are 0 (indicating no blink) or NaN (indicating
% lost data)

% Carolyn Ranti
% 2.18.15


samplesPerMin = sampleRate*60;
instBR = samplesPerMin * nanmean(fractBlinks,1);



