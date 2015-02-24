function [Y, optW] = convWindow(blinkInput, W)
%CONVWINDOW - Return a gaussian window to convolve with blink data (in 
% order to smooth)
%
% INPUTS:
%   Blink data  Matrix or vector of blink data. This can be binary data or
%               fractional blink data, as long as blink frames are
%               indicated by positive values and non-blink frames are
%               indicated by values <=0 or NaNs.
%   W           Optional. A range of values for sskernel to test in order
%               to find the optimum bandwidth size. Default value that 
%               sskernel sets is: 
%                   W = logspace(log10(2*dx),log10((x_max - x_min)),50).
%
% OUTPUT:
%   Y
%   optW
%
% TODO - finish 
% Uses sskernel to find the optimum bandwidth for the data
% * This script is the timing bottleneck for permutation testing
%
% See also SSKERNEL

% Carolyn Ranti
% Updated 2.18.15


% find col indices of all positive entries -- formerly findBlinkIndices()
[~,blinkInds] = find(blinkInput>0);
    
%find optimum bandwidth (optW, a standard deviation of a normal density
%function), passing in range for W if provided.
if nargin==1 || isempty(W)
    [optW, ~, ~] = sskernel(blinkInds); 
else
    [optW, ~, ~] = sskernel(blinkInds, W); 
end

% gaussian window to convolve with data
xrange = -4*optW:1:4*optW;
% xrange must have an odd number of values for smoothing to work
if mod(length(xrange),2)==0 
    xrange = [xrange, max(xrange)+1];
end
    
Y = normpdf(xrange, 0, optW); 