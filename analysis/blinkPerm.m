% INITIAL DRAFT DONE - 11.24.2014
%
% Carolyn Ranti

function [prctile05, prctile95] = blinkPerm(numPerms, fractBlinks, unitsPerMin, Y)

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
    smoothed_permuted_instBR(currPerm,:) = smoothBlinkRate(permutedData, unitsPerMin, Y);
end

% medianBR = median(smoothed_permuted_instBR);
prctile05 = prctile(smoothed_permuted_instBR,5);
prctile95 = prctile(smoothed_permuted_instBR,95);