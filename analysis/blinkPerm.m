function [results] = blinkPerm(numPerms, rawBlinks, sampleRate, varargin) 
%BLINKPERM Find moments when a group is blinking significantly more or less
%
% INPUT:
%   numPerms    Number of permutations to run for the statistical test
%   rawBlinks   n x f matrix (n = subjects, f = frames) with binary blink
%               data (1 = blink, 0 = no blink, NaN = lost data)
%   sampleRate  Sample rate (in Hz) 
%
% Optional name/value parameters
%   'smoothType'    'sskernel' (default). Bandwidth of the Gaussian kernel
%                   is optimized (see also 'W'). Currently no other options
%                   for smoothType - leaving this for future versions
%   'W'             Bandwidth (standard deviation) for Gauss density
%                   function used to smooth data. This can be a single 
%                   value or a vector of values that will be tested.
%   'lowPrctile'    Low percentile to test for significant blink inhibition
%                   (used in permutation testing). Default 2.5
%   'highPrctile'   High percentile to test for significant blink inhibition
%                   (used in permutation testing). Default 97.5
%   'hWaitBar'      Handle to a waitbar to update user with progress
%
%
% OUTPUT:
%   results		Struct with the following fields:
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
%       optW - Optimal W parameter used to smooth data
%       inputs - struct with information about the input variables
%           (number of individuals in rawBlinks, length of data, number of
%           permutations, sample rate)
%
% The smoothed instantaneous blink rate of a group of individuals is 
% compared to the 5th and 95th percentile of a permutation test, in order
% to identify moments when the group blink rate is significantly higher or 
% lower. Smoothed instantaneous blink rate is calculated by convolving the 
% average blink rate in each frame with a Gaussian kernel. The kernel size
% is determined using SSKERNEL
%
% In the permutation testing procedure, each subject's data is circularly
% shifted by a random amount before calculating the smoothed blink rate.
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
% SEE ALSO: SMOOTHBLINKRATE, SSKERNEL

% Carolyn Ranti
% 2.27.2015

%% Optional inputs

% Parse optional inputs and check
assert(mod(length(varargin),2)==0, 'Error - odd number of optional parameters (must be name, value pairs)');

%defaults
smoothType = 'sskernel';
W = [];
lowPrctileLevel = 2.5; 
highPrctileLevel = 97.5;
hWaitBar = [];
haswaitbar = 0;

for v = 1:2:length(varargin)
   switch lower(varargin{v})
       case 'smoothtype' %NOTE/TODO: currently, there is only one option for smoothing data (sskernel). Leaving this syntax in here for future edits
           smoothType = varargin{v+1};
           assert(sum(strcmpi(smoothType, {'sskernel'}))==1, 'smoothType must be sskernel');
       case 'w'
           W = varargin{v+1};
           assert(isnumeric(W) || isempty(W), 'W must be empty or a numeric array');
       case 'lowprctile'
           lowPrctileLevel = varargin{v+1};
           if ~isnumeric(lowPrctileLevel) || ~isscalar(lowPrctileLevel) || lowPrctileLevel<0 || lowPrctileLevel>100
               error('lowPrctile must be a numeric value between 0 and 100');
           end
       case 'highprctile'
           highPrctileLevel = varargin{v+1};
           if ~isnumeric(highPrctileLevel) || ~isscalar(highPrctileLevel) || highPrctileLevel<0 || highPrctileLevel>100
               error('highPrctile must be a numeric value between 0 and 100');
           end
       case 'hwaitbar'
           hWaitBar = varargin{v+1};
           %make sure it's a valid handle
           if ishandle(hWaitBar)
               haswaitbar = 1;
           end
   end
end


%% Convert binary blink input to fractional blinks
fractBlinks = raw2fractBlinks(rawBlinks); 

%% Smooth group BR

if haswaitbar
    tstart = tic; 
    waitbar(0, hWaitBar, 'Smoothing Data...');
end

% gaussian window to convolve with data
[Y,optW] = convWindow(fractBlinks, smoothType, W, hWaitBar); 

%smooth data
smoothedBR = smoothBlinkRate(fractBlinks, sampleRate, Y);

%have it take at least 1/2 second (for message to be visible in waitbar)
if haswaitbar
    waitbar(1, hWaitBar);
    while toc(tstart) < .5; end 
end


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

if haswaitbar
    waitbar(0, hWaitBar, 'Running Permutation Test...');
end

for currPerm = 1:numPerms
    
    if haswaitbar
        %Check for Cancel button press
        if getappdata(hWaitBar,'canceling')
            results = struct();
            return
        end
        
        %Update progress bar
        waitbar(double(currPerm)/double(numPerms), hWaitBar);
    end

    %circularly shift data by a random amount
    shiftSizes = round(2*dataLen*rand(numPpl,1) - dataLen);
    for p = 1:numPpl
        shiftedData(p,:) = circshift(fractBlinks(p,:),[0, shiftSizes(p)]);
    end

    %calculate *smoothed* instantaneous BR for the shifted group data
    smoothed_permuted_instBR(currPerm,:) = smoothBlinkRate(shiftedData, sampleRate, Y);
end

if haswaitbar
    tstart = tic;
    waitbar(0, hWaitBar,'Calculating Significance...');
end


%% Calculate low and high percentile BRs, and find sig. increased/decreased blinking moments
lowPrctile = prctile(smoothed_permuted_instBR, lowPrctileLevel);
highPrctile = prctile(smoothed_permuted_instBR, highPrctileLevel);

% significant moments of decreased and increased blinking
decreasedBlinking = find(smoothedBR < lowPrctile);
increasedBlinking = find(smoothedBR > highPrctile);
    
%% Output structure
%results from analyses
results.smoothedBR = smoothedBR;
results.decreasedBlinking = decreasedBlinking;
results.increasedBlinking = increasedBlinking;
results.lowPrctileLevel = lowPrctileLevel;
results.highPrctileLevel = highPrctileLevel;
results.lowPrctile = lowPrctile;
results.highPrctile = highPrctile;
results.optW = optW;

%info about inputs:
results.inputs = struct();
results.inputs.numIndividuals = numPpl;
results.inputs.numFrames = dataLen;
results.inputs.numPerms = numPerms;
results.inputs.sampleRate = sampleRate;
results.inputs.smoothType = smoothType;

if haswaitbar
    while toc(tstart) < .5; end 
    waitbar(1, hWaitBar);
end