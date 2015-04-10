function [Y, optW] = convWindow(blinkInput, smoothType, W,  hWaitBar)
%CONVWINDOW - Return a gaussian window to convolve with blink data. Window
%has a mean of 0 and a standard deviation 
%
% INPUTS:
%   Blink data  Matrix or vector of blink data. This can be binary data or
%               fractional blink data, as long as blink frames are
%               indicated by positive values and non-blink frames are
%               indicated by values <=0 or NaNs.
%   smoothType  Optional. 'sskernel' (default). Specifies
%               the way that the kernel bandwidth is selected. Currently
%               only one option -- leaving syntax in for future versions.
%   W           Optional. A range of values for sskernel to test in order
%               to find the optimum bandwidth size. Default value that 
%               sskernel sets is: 
%                   W = logspace(log10(2*dx),log10((x_max - x_min)),50).
%               This parameter is only used if smoothType is 'sskernel'
%   hWaitBar    Optional. Handle to a wait bar to update with progress.
%               Just passes the handle to sskernel, which changes only bar
%               (NOT the message)
%
% OUTPUT:
%   Y           Gaussian window with mean=0, standard deviation=optW
%   optW        Standard deviation of Y
%
% Uses sskernel to find the optimum bandwidth for the data
%
% See also SSKERNEL

% Carolyn Ranti
% Updated 2.18.15


if nargin<2 || isempty(smoothType)
    smoothType = 'sskernel';
end

if nargin<3 || isempty(W)
    W = [];
end
    
if nargin<4 || isempty(hWaitBar)
    hWaitBar = [];
end

% find col indices of all positive entries -- formerly findBlinkIndices()
[~,blinkInds] = find(blinkInput>0);
    
switch lower(smoothType)
    case 'sskernel'
        % find optimum bandwidth (i.e. stdev of gaussian), passing in range
        % for W and the handle to the waitbar if they are provided
        optW = sskernel(blinkInds, W, hWaitBar); 
    otherwise
        error('Unknown value for smoothType: %s',smoothType);
end


%% gaussian window to convolve with data
xrange = -4*optW:1:4*optW;
% xrange must have an odd number of values for smoothing to work
if mod(length(xrange),2)==0 
    xrange = [xrange, max(xrange)+1];
end
    
Y = normpdf(xrange, 0, optW); 