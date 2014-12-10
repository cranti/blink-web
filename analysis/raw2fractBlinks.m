%RAW2FRACTBLINKS - Convert blink input into n x f matrix with fractional 
% blinks
%
% INPUT
%   n x f matrix with 1s (blink frame), 0s (non-blink frame), and NaNs 
%     (lost data), where n = # subjects and f = # frames
%
% OUTPUT
%   n x f matrix with fractional values in the blink frames, NaNs and 0s
%     unchanged. The fractional values sum to 1 per blink, such that if you
%     sum across a range of frames, the result is the number of blinks in
%     that time. 
%
% NOTES
%   - Consecutive blink frames are considered a single blink. If lost data
%     disrupts the 1s, it will be considered two blinks.
%   - No checking being done for the length of blinks.
%   - Little error checking being done.
%
% Carolyn Ranti
% 12.3.2014


%% 
function fractBlinks = raw2fractBlinks(blinks)

fractBlinks = zeros(size(blinks));

%put NaNs in fractBlinks, then remove from input
fractBlinks(isnan(blinks)) = NaN;
blinks(isnan(blinks)) = 0;

assert(isempty(setdiff(blinks,[1 0])),'Blink data must only contain 1s and 0s');

for r = 1:size(blinks,1)
    
    %find the beginning and end of each blink. padding diff input with a 0
    %on either end takes care of 1st frame start/last frame end cases.
    blinkDiff = diff([0,blinks(r,:),0]);
    blinkStart = find(blinkDiff>0);
    blinkEnd = find(blinkDiff<0)-1;
    
    %sanity check
    assert(length(blinkStart)==length(blinkEnd),'There must be the same number of blink starts and blink ends');
    
    %convert to fractional blinks
    for b = 1:length(blinkStart)
        start = blinkStart(b);
        stop = blinkEnd(b);
        fractBlinks(r, start:stop) = 1/(stop-start+1);
    end
    
end



