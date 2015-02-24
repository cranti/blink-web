function smoothBR = smoothBlinkRate(fractBlinks, sampleRate, Y)
%SMOOTHBLINKRATE
%
% Calculate the instantaneous blink rate of a group (in blinks/min), using
% fractional blink data (fractBlinks: rows = subjects, columns = samples)
% and the number of samples per minute. Data is smoothed with a kernel 
% provided by the user (Y, recommended Gaussian). Smoothed instantaneous 
% blink rate of the group is output in a vector with the same number of 
% columns as the input.
%
%
% INPUTS:
%   blinkInput	n x f matrix (n = subjects, f = frames) with fractional
%       		blink data
%   sampleRate 	Hz (i.e. # frames/second)
%   Y			Window to use for convolution of the group's blink rate
%
% OUTPUTS:
%   smoothBR 	1xf vector with the group's smoothed instantaneous blink
%		 		rate in each frame
%
% See also RAW2FRACTBLINKS, CALCINSTBR

% Carolyn Ranti
% 2.18.15


% calculate instantaneous blink rate (blink/min)
instBR = calcInstBR(fractBlinks, sampleRate);

% convolve with Y
smoothBR = conv2_mirrored(instBR, Y);