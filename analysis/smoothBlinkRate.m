function smoothedBlinkData = smoothBlinkRate(fractBlinks, sampleRate, Y)
%SMOOTHBLINKRATE
% Convert blink data from a group of participants to smoothed
% instantaneous blink rate.
%
% Calculate the instantaneous blink rate of a group (in blinks/min), using
% fractional blink data (fractBlinks: rows = subjects, columns = samples)
% and the number of samples per minute. Then, smooth with a Gaussian window
% provided by the user (Y). Smoothed instantaneous blink rate of the group
% is output in a vector with the same number of columns as the input.
%
%
% INPUTS:
%   blinkInput - n x f matrix (n = subjects, f = frames) with fractional
%       blink data
%   sampleRate - Hz (i.e. # frames/second)
%   Y - Window to use for convolution of the group's blink rate
%
% OUTPUTS:
%   smoothedBlinkRate - 1 x f vector with the group's smoothed
%       instantaneous blink rate in each frame.
%
% See also CALCINSTBR

% Carolyn Ranti
% 2.18.15


% calculate instantaneous blink rate (blink/min)
instBR = calcInstBR(fractBlinks, sampleRate);

% convolve with Y
smoothedBlinkData = conv2_mirrored(instBR, Y);