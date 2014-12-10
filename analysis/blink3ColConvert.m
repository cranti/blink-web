%BLINK3COLCONVERT - Convert 3 column input into a matrix
%
% Inputs: 
% > blinks - 3 column matrix with a list of the start and stop frames for 
% every participant's blinks.
%       Col 1 - Subject identifier. Unique numbers will correspond to a
%       unique row in the output matrix.
%       Col 2 - Blink start time (integers) 
%       Col 3 - Blink stop time (integers)
%
% > sampleLen - length of the clip sampled. This will determine the number
% of columns in the output matrix
%
% Outputs:
% > blinkMat -- n x f matrix with 1s (blink frames) and 0s (non-blinks)
%       n = # subjects (i.e. unique values in col 1 of input)
%       f = # frames (sampleLen)
%
% > subjOrder -- order of subjects, matching the rows of blinkMat
%
%
% NOTES: 
%  - Currently, there is no option to include "lost" frames
%  - If there is a blink start/stop option that is greater than the
%  sampleLen provided, the output matrix will have enough frames to
%  accommodate that blink.
%  - Not a whole lot of error checking - it's up to the user to make sure
%  that starts and stops are integers, starts <= stops, etc.
% 
% Carolyn Ranti
% 12.3.2014 

function [blinkMat,subjOrder] = blink3ColConvert(blinks,sampleLen)

assert(size(blinks,2)==3,'Input error: Blink data must have 3 columns.');

subjOrder = unique(blinks(:,1));

blinkMat = zeros(length(subjOrder), sampleLen);

for ii = 1:size(blinks,1)
    start = blinks(ii,2);
    stop = blinks(ii,3);
    subjRow = (subjOrder == blinks(ii,1));
    blinkMat(subjRow,start:stop) = 1;
end