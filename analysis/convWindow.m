% INITIAL DRAFT DONE
% 12.1.14
%
% Return window to convolve with blink data (for smoothing)
%
% TODO:
%   what is the range for W?
%   verify, document

function Y = convWindow(fractBlinks)
 
%formerly findBlinkIndices()
[~,blinkInds] = find(fractBlinks>0);
    
%find optimum bandwidth (optW, a standard deviation of a normal density function)
W = 1:10; %TODO - what should I set as range for W?
[optW, ~, W] = sskernel(blinkInds, W); 

% gaussian window to convolve with data
Y = normpdf(-4*optW:1:4*optW, 0, optW); 