function smoothBR = smoothBlinkRate(fractBlinks, sampleRate, Y)
%SMOOTHBLINKRATE Calculate a group's instantaneous blink rate (blinks/min)
%
% INPUT:
%   blinkInput	n x f matrix (n = subjects, f = frames) with fractional
%       		blink data
%   sampleRate 	Hz (i.e. # frames/second)
%   Y			Window to use for convolution of the group's blink rate
%
% OUTPUT:
%   smoothBR 	1xf vector with the group's smoothed instantaneous blink
%		 		rate in each frame
%
% SMOOTHBLINKRATE(FRACTBLINKS, SAMPLERATE, Y) calculates the instantaneous
% blink rate of a group (in blinks/min), using FRACTBLINKS, a matrix of
% fractional blink data (rows = subjects, columns = frames). The sample
% rate of the data must be specified in Hz (frames/sec). Data is smoothed
% using Y, a kernel provided by the user. Gaussian kernel is recommended.
% The smoothed blink rate of the group (in blinks/min) is output in a
% vector with the same number of columns as the input data.
%
% See also RAW2FRACTBLINKS, CALCINSTBR

% Carolyn Ranti
% 2.24.15

% calculate instantaneous blink rate (blink/min)
instBR = calcInstBR(fractBlinks, sampleRate);

% convolve with Y
smoothBR = conv2_mirrored(instBR, Y);