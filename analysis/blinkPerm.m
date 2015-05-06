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
%                   for smoothType - leaving this for future versions.
%   'W'             Bandwidth (standard deviation) for Gauss density
%                   function used to smooth data. This can be a single 
%                   value or a vector of values that will be tested.
%   'lowPrctile'    Low percentile to test for significant blink inhibition
%                   (used in permutation testing). Default 2.5, value must
%                   be between 0 and 100.
%   'highPrctile'   High percentile to test for significantly increased
%                   blinking (used in permutation testing). Default 97.5,
%                   value must be between 0 and 100.
%   'sigFrameThr'   Number of consecutive samples necessary to consider
%                   lower or higher blinking a significant moment of blink
%                   inhibition or increase in blinking.
%   'hWaitBar'      Handle to a waitbar that updates user with progress
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
%       prctile05 - 1 x f vector with the [low] percentile blink rate found
%           by permutation testing.
%       prctile95 - 1 x f vector with the 95th percentile blink rate
%          found by permutation testing.
%       optW - Bandwidth of the Gaussian kernel used to smooth data
%       inputs - struct with information about the input variables
%           (number of individuals in rawBlinks, length of data, number of
%           permutations, sample rate, frame threshold for significance,
%           smooth type, and significance frame threshold.
%
% The smoothed instantaneous blink rate of a group of individuals is
% compared to the [low] and [high] percentile of a permutation test, in
% order to identify moments when the group blink rate is significantly
% higher or lower. Smoothed instantaneous blink rate is calculated by
% convolving the average blink rate in each frame with a Gaussian kernel.
% The kernel size is determined using SSKERNEL, or 
%
% In the permutation testing procedure, each subject's data is circularly
% shifted by a random amount before calculating the smoothed blink rate.
% Permutation testing with a group's blink data (fractBlinks) - for the
% number of permutations specified (numPerms), circularly shift each
% subject's data by some random amount and calculate the smoothed blink for
% the group. User must specify the sample rate in Hz (sampleRate).
%
% Calculates a low and high percentile of the permuted data (per sample).
% Moments of significant blink inhibition are the frames in which the
% smoothed blink rate of the group is less than the low percentile of the
% permuted data. Moments of significantly increased blinking are the frames
% in which the smoothed blink rate of the group is greater than the high
% percentile. SigFrameThr (optional input) determines the number of
% consecutive frames that are necessary to consider a moment significant.
%
% SEE ALSO: SMOOTHBLINKRATE, SSKERNEL

% Carolyn Ranti
% 4.12.2015

%% Parse optional inputs and check
assert(mod(length(varargin),2)==0, 'Error - odd number of optional parameters (must be name, value pairs)');

%defaults
smoothType = 'sskernel';
W = [];
lowPrctileLevel = 2.5;
highPrctileLevel = 97.5;
sigFrameThr = 1;
hWaitBar = [];
haswaitbar = 0;

for v = 1:2:length(varargin)
    switch lower(varargin{v})
        case 'smoothtype' %NOTE/TODO: currently, there is only one option for smoothing data (sskernel). Leaving this syntax in here for future edits
            smoothType = varargin{v+1};
            assert(sum(strcmpi(smoothType, {'sskernel'}))==1, 'Invalid smoothType');
        case 'w'
            W = varargin{v+1};
            assert(isnumeric(W) || isempty(W), 'W must be empty or a numeric array');
        case 'lowprctile'
            lowPrctileLevel = varargin{v+1};
            if ~isnumeric(lowPrctileLevel) || ~isscalar(lowPrctileLevel) || lowPrctileLevel<=0 || lowPrctileLevel>=100
                error('lowPrctile must be a numeric value between 0 and 100');
            end
        case 'highprctile'
            highPrctileLevel = varargin{v+1};
            if ~isnumeric(highPrctileLevel) || ~isscalar(highPrctileLevel) || highPrctileLevel<=0 || highPrctileLevel>=100
                error('highPrctile must be a numeric value between 0 and 100');
            end
        case 'sigframethr'
            sigFrameThr = varargin{v+1};
            if ~isnumeric(sigFrameThr) || ~isscalar(sigFrameThr) || sigFrameThr<=0
                error('sigFrameThr must be a positive number');
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
[Y, optW] = convWindow(fractBlinks, smoothType, W, hWaitBar); 

%Y (and optW) empty if the operation is canceled by the progress bar
if isempty(Y)
    results = struct();
    return 
end

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
permutedSmoothedBR = zeros(numPerms, dataLen);

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
    shiftSizes = round(dataLen*rand(numPpl,1)); %TODO - check this with Warren
    for p = 1:numPpl
        shiftedData(p,:) = circshift(fractBlinks(p,:), shiftSizes(p), 2); %what to shift, how much to shift it, dimension of shift
    end

    %calculate *smoothed* instantaneous BR for the shifted group data
    permutedSmoothedBR(currPerm,:) = smoothBlinkRate(shiftedData, sampleRate, Y);
end

if haswaitbar
    tstart = tic;
    waitbar(0, hWaitBar,'Calculating Significance...');
end


%% Calculate low and high percentile BRs, and find sig. increased/decreased blinking moments
lowPrctile = prctile(permutedSmoothedBR, lowPrctileLevel, 1);
highPrctile = prctile(permutedSmoothedBR, highPrctileLevel, 1);


%% Find significant moments of decreased and increased blinking
decreasedBlinking = find(smoothedBR < lowPrctile);
increasedBlinking = find(smoothedBR > highPrctile);

% Use threshold (how many consecutive frames to consider a significant
% moment of blink inhibition/increase?), but only if it's >1.
if sigFrameThr>1
    
    db_orig = [decreasedBlinking, decreasedBlinking(end)+2];
    ib_orig = [increasedBlinking, increasedBlinking(end)+2];
    
    % Decreased blinking
    mLen = 1;
    mStart = db_orig(1);
    longMoments = [];
    for ii = 2:length(db_orig)

        thisFrame = db_orig(ii);
        prevFrame = db_orig(ii-1);
        
        if (thisFrame-prevFrame)==1
            mLen = mLen+1;
        else
            if mLen >= sigFrameThr
                longMoments = [longMoments, mStart:prevFrame];
            end
            mLen = 1;
            mStart = thisFrame;
        end
    end
    decreasedBlinking = longMoments;
    
    % Increased blinking
    mLen = 1;
    mStart = ib_orig(1);
    longMoments = [];
    for ii = 2:length(ib_orig)

        thisFrame = ib_orig(ii);
        prevFrame = ib_orig(ii-1);
        
        if (thisFrame-prevFrame)==1
            mLen = mLen+1;
        else
            if mLen >= sigFrameThr
                longMoments = [longMoments, mStart:prevFrame];
            end
            mLen = 1;
            mStart = thisFrame;
        end
    end
    increasedBlinking = longMoments;
end

    
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
results.inputs.dataLen = dataLen;
results.inputs.numPerms = numPerms;
results.inputs.sampleRate = sampleRate;
results.inputs.smoothType = smoothType;
results.inputs.sigFrameThr = sigFrameThr;

if haswaitbar
    while toc(tstart) < .5; end 
    waitbar(1, hWaitBar);
end