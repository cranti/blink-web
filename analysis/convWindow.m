function [Y, optW] = convWindow(blinkInput, W, hWaitBar)
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
%   hWaitBar    Optional. Handle to a wait bar to update with progress.
%               Just passes the handle to sskernel, which changes only bar
%               (NOT the message)
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
    
% find optimum bandwidth (optW, a standard deviation of a normal density
% function), passing in range for W and the handle to the waitbar if they
% are provided
if nargin<2 || isempty(W)
    W = [];
end
if nargin<3 || isempty(hWaitBar)
    hWaitBar = [];
end
optW = sskernel(blinkInds, W, hWaitBar); 


% gaussian window to convolve with data
xrange = -4*optW:1:4*optW;
% xrange must have an odd number of values for smoothing to work
if mod(length(xrange),2)==0 
    xrange = [xrange, max(xrange)+1];
end
    
Y = normpdf(xrange, 0, optW); 