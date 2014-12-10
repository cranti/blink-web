%BLINKPERM
%
% Permutation testing w/ a group's blink data (fractBlinks) - for the
% number of permutations specified (numPerms), circularly shift each
% subject's data by some random amount and calculate the smoothed blink for
% the group. User must specify the number of samples per minute
% (samplesPerMin) and the smoothing window for smoothBlinkRate() (Y).
% 
%
% SEE ALSO: SMOOTHBLINKRATE

% Carolyn Ranti
% INITIAL DRAFT DONE - 11.24.2014

function [prctile05, prctile95] = blinkPerm(numPerms, fractBlinks, samplesPerMin, Y)

dataLen = length(fractBlinks);
numPpl = size(fractBlinks,1);

% participant x frames
permutedData = zeros(numPpl, dataLen, 'single');

% permutations x frames
smoothed_permuted_instBR = zeros(numPerms, dataLen);

for currPerm = 1:numPerms
    
    if mod(currPerm,100)==1; 
        disp(currPerm);
    end
    
    %circularly shift data by a random amount
    shiftSizes = round(2*dataLen*rand(numPpl,1) - dataLen);
    for p = 1:numPpl
        permutedData(p,:) = circshift(fractBlinks(p,:),[0, shiftSizes(p)]);
    end
    
    %calculate *smoothed* instantaneous BR for the group
    smoothed_permuted_instBR(currPerm,:) = smoothBlinkRate(permutedData, samplesPerMin, Y);
end

% medianBR = median(smoothed_permuted_instBR);
prctile05 = prctile(smoothed_permuted_instBR,5);
prctile95 = prctile(smoothed_permuted_instBR,95);