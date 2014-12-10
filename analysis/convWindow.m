% INITIAL DRAFT DONE
% 12.10.14
%
% Return window to convolve with blink data (for smoothing)
%
% TODO:
%   what is the range for W?
%   verify, document

function Y = convWindow(fractBlinks, W)
 
if nargin==1
    W = 1:10; % TODO - determine range for W
end

% find col indices of all positive entries -- formerly findBlinkIndices()
[~,blinkInds] = find(fractBlinks>0);
    
%find optimum bandwidth (optW, a standard deviation of a normal density function)
[optW, ~, W] = sskernel(blinkInds, W); 

% gaussian window to convolve with data
Y = normpdf(-4*optW:1:4*optW, 0, optW); 