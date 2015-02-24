function [results] = blinkPerm(numPerms, rawBlinks, sampleRate, W) 
%BLINKPERM
%
% TODO - document this method
%
% Permutation testing with a group's blink data (fractBlinks) - for the
% number of permutations specified (numPerms), circularly shift each
% subject's data by some random amount and calculate the smoothed blink for
% the group. User must specify the sample rate in Hz (sampleRate).
%
% Calculates the 5th and the 95th percentiles of the permuted data. Moments
% of significant blink inhibition are the frames in which the smoothed
% blink rate of the group is less than the 5th percentile of the permuted
% data. Moments of significantly increased blinking are the frames in which
% the smoothed blink rate of the group is greater than the 95th percentile.
%
% INPUT:
%   numPerms    Number of permutations to run for the statistical test
%   rawBlinks   n x f matrix (n = subjects, f = frames) with binary blink
%               data (1 = blink, 0 = no blink, NaN = lost data)
%   sampleRate  Sample rate (in Hz) 
%   W           Optional -  
% 
% OUTPUT:
%   Struct with the following fields:
%       smoothedBR - 1 x f vector with smoothed instantaneous blink rate
%       	for the group
%       decreasedBlinking - vector with frames in which the smoothed blink
%           rate of the group is less than the 5th percentile found by the
%           permutation testing.
%       increasedBlinking - vector with frames in which the smoothed blink
%           rate of the group is greater than the 95th percentile found by
%           permutation testing.
%       prctile05 - 1 x f vector with the 5th percentile blink rate found
%           by permutation testing.
%       prctile95 - 1 x f vector with the 95th percentile blink rate
%          found by permutation testing.
%       optW - Optimal W parameter found for smoothing kernel by convWindow
%       inputs - struct with information about the input variables
%           (number of individuals in rawBlinks, length of data, number of
%           permutations, sample rate)
%
% SEE ALSO: SMOOTHBLINKRATE

% Carolyn Ranti
% 2.23.2015


%% Convert binary blink input to fractional blinks
fractBlinks = raw2fractBlinks(rawBlinks); 

%% Smooth group BR
% Last input (optional) is a range or value for W (gaussian window to
% convolve with data)
if nargin<4
    [Y,optW] = convWindow(fractBlinks); % gaussian window to convolve with data
else
    [Y,optW] = convWindow(fractBlinks,W); % gaussian window to convolve with data
end
smoothedBR = smoothBlinkRate(fractBlinks, sampleRate, Y);

%% Permutations
dataLen = length(fractBlinks);
numPpl = size(fractBlinks,1);

% Preallocate storage for permutations (# perms x frames) - each row is the
% smoothed instantaneous BR for the group, calculated after each subject is
% circularly shifted by some random amount.
smoothed_permuted_instBR = zeros(numPerms, dataLen);

% Set shiftedData only at the beginning - participants x frames. Each row
% is the data for one subject, circularly shifted by some random amount
shiftedData = zeros(numPpl, dataLen, 'single');

for currPerm = 1:numPerms

    %circularly shift data by a random amount
    shiftSizes = round(2*dataLen*rand(numPpl,1) - dataLen);
    for p = 1:numPpl
        shiftedData(p,:) = circshift(fractBlinks(p,:),[0, shiftSizes(p)]);
    end

    %calculate *smoothed* instantaneous BR for the shifted group data
    smoothed_permuted_instBR(currPerm,:) = smoothBlinkRate(shiftedData, sampleRate, Y);
end

%% Calculate 5th and 95th percentile BRs, and find sig. increased/decreased blinking moments
prctile05 = prctile(smoothed_permuted_instBR, 5);
prctile95 = prctile(smoothed_permuted_instBR, 95);

% significant moments of decreased and increased blinking
decreasedBlinking = find(smoothedBR < prctile05);
increasedBlinking = find(smoothedBR > prctile95);

%% Output structure
%results from analyses
results.smoothedBR = smoothedBR;
results.decreasedBlinking = decreasedBlinking;
results.increasedBlinking = increasedBlinking;
results.prctile05 = prctile05;
results.prctile95 = prctile95;
results.optW = optW;

%inputs:
results.inputs = struct();
results.inputs.numIndividuals = numPpl;
results.inputs.numFrames = dataLen;
results.inputs.numPerms = numPerms;
results.inputs.sampleRate = sampleRate;
