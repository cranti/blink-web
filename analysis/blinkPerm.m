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
%   'lowerPrctile'  Lower percentile cutoff to test for significant blink 
%                   inhibition (w/ permutation testing). Default 2.5, value
%                   must be between 0 and 100.
%   'upperPrctile'  Upper percentile cutoff to test for significantly 
%                   increased blinking (w/ permutation testing). Default
%                   97.5, value must be between 0 and 100.
%   'sigFrameThr'   Number of consecutive samples necessary to consider
%                   lower or higher blinking a significant moment of blink
%                   inhibition or increase in blinking.
%   'hWaitBar'      Handle to a waitbar that updates user with progress
%
%
% OUTPUT:
%   results		Struct with the following sections:
%
%       inputs - struct with information about the input variables
%           numParticipants - number of participants for whom blink data 
%               were collected
%           numSamples - number of samples of blink data collected (i.e., 
%               data length)
%           sampleRate - rate at which blink data were sampled (in Hz)       
%           numPerms - number of permutations used for statistical testing
%           smoothType - the method used to determine optimal bandwidth for
%               the smoothing kernel. Currently, always 'sskernel' - in
%               future versions, may add other options.
%           bandWRange - range of bandwidths considered in optimization of 
%               the Gaussian smoothing kernel
%           lowerPrctileCutoff - lower percentile across all permuted data 
%               that served as significance cutoff for blink inhibition
%           upperPrctileCutoff - upper percentile across all permuted data 
%               that served as significance cutoff for increased blinking
%           numConsecSamples - minimum number of consecutive samples that 
%               must exceed the significance threshold to be considered an 
%               instance of blink inhibition or increased blinking (i.e. 
%               'sigFrameThr' option)
%
%       smoothing - struct with information about data smoothing
%           bandW - the bandwidth of the Gaussian kernel used to smooth 
%               blink data
%
%       sigBlinkMod - samples with significant blink modulation
%           blinkInhib - instances of statistically significant blink
%               inhibition (i.e., sample(s) in which the actual group blink
%               rate was less than lower percentile of permuted data) 
%           incrBlink - instances of statistically significant increased
%               blinking (i.e., sample(s) in which the actual group blink
%               rate was greater than upper percentile of permuted data)
%
%       smoothInstBR - struct with smoothed blink rate in all samples
%           groupBR - smoothed instantaneous blink rate (blinks/minute) 
%               of the group of viewers at each sample
%           lowerPrctilePerm - lower percentile of permuted blink data at
%               each sample
%           upperPrctilePerm - upper percentile of permuted blink data at
%               each sample
%
% TODO - change "level" to "cutoff" (lower and upper)
%
% The smoothed instantaneous blink rate of a group of individuals is
% compared to the [low] and [high] percentile of a permutation test, in
% order to identify moments when the group blink rate is significantly
% higher or lower. Smoothed instantaneous blink rate is calculated by
% convolving the average blink rate in each frame with a Gaussian kernel.
% The kernel size is determined using SSKERNEL.
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
% If the user cancels the operation, results is an empty array.
%
%
% SEE ALSO: SMOOTHBLINKRATE, SSKERNEL

% Carolyn Ranti
% 6.1.2015

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
        case 'lowerprctile'
            lowPrctileLevel = varargin{v+1};
            if ~isnumeric(lowPrctileLevel) || ~isscalar(lowPrctileLevel) || lowPrctileLevel<=0 || lowPrctileLevel>=100
                error('lowerPrctile must be a numeric value between 0 and 100');
            end
        case 'upperprctile'
            highPrctileLevel = varargin{v+1};
            if ~isnumeric(highPrctileLevel) || ~isscalar(highPrctileLevel) || highPrctileLevel<=0 || highPrctileLevel>=100
                error('upperPrctile must be a numeric value between 0 and 100');
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
        otherwise
            error('Unknown input variable: %s',varargin{v});
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
[Y, smoothW] = convWindow(fractBlinks, smoothType, W, hWaitBar); 

%Y (and smoothW) empty if the operation is canceled by the progress bar
if isempty(Y)
    results = [];
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
            results = [];
            return
        end
        
        %Update progress bar
        waitbar(double(currPerm)/double(numPerms), hWaitBar);
    end

    %circularly shift data by a random amount
    shiftSizes = round(dataLen*rand(numPpl,1));
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
decrBlink = find(smoothedBR < lowPrctile);
incrBlink = find(smoothedBR > highPrctile);

% Use threshold (how many consecutive frames to consider a significant
% moment of blink inhibition/increase?), but only if it's >1.
if sigFrameThr>1
    
    db_orig = [decrBlink, decrBlink(end)+2]; %last item is sort of a placeholder 
    ib_orig = [incrBlink, incrBlink(end)+2];
    
    % Decreased blinking
    mLen = 1; %length of DB moment
    mStart = db_orig(1); %first frame of this DB moment
    longMoments = [];
    for ii = 2:length(db_orig)

        thisFrame = db_orig(ii);
        prevFrame = db_orig(ii-1);
        
        if (thisFrame-prevFrame)==1
            mLen = mLen+1;
        elseif (thisFrame-prevFrame)>1
            if mLen >= sigFrameThr
                longMoments = [longMoments, mStart:prevFrame];
            end
            mLen = 1;
            mStart = thisFrame;
        end
    end
    decrBlink = longMoments;
    
    % Increased blinking
    mLen = 1; %length of IB moment
    mStart = ib_orig(1); %first frame of this DB moment
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
    incrBlink = longMoments;
end

    
%% Output structure

%Sections:
results.inputs = struct();
results.smoothing = struct();
results.sigBlinkMod = struct();
results.smoothInstBR = struct();

%Inputs -- all information that the user specified
results.inputs.numParticipants = numPpl;
results.inputs.numSamples = dataLen;
results.inputs.sampleRate = sampleRate;
results.inputs.numPerms = numPerms; 
results.inputs.smoothType = smoothType; 
results.inputs.bandWRange = W;
results.inputs.lowerPrctileCutoff = lowPrctileLevel;
results.inputs.upperPrctileCutoff = highPrctileLevel;
results.inputs.numConsecSamples = sigFrameThr;

%Smoothing
results.smoothing.bandW = smoothW; 

% Samples with significant blink modulation 
results.sigBlinkMod.blinkInhib = decrBlink;
results.sigBlinkMod.incrBlink = incrBlink;

% Smoothed Instantaneous BR (all samples)
results.smoothInstBR.groupBR = smoothedBR;
results.smoothInstBR.lowerPrctilePerm = lowPrctile; 
results.smoothInstBR.upperPrctilePerm = highPrctile; 



if haswaitbar
    while toc(tstart) < .5; end 
    waitbar(1, hWaitBar);
end