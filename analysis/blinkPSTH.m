function results = blinkPSTH(refEvents, targetEvents, lagSize, numPerms, eventSpecs)
%BLINKPSTH - Create a peri-stimulus time histogram using a group's blink
%data.
%
% TODO - document this method
% Splitting out functions -- will need to change the summary function, and maybe pass in 
% some parameters about the input specs?
% TODO - allow user to specify percentile (will need to change labels and things in summary fxn, figures, etc)
%
% INPUTS
%   refEvents       Cell vector, containing vectors of reference data.
%                   There can be a single set of reference data (i.e. 1x1 cell)
%                   or one set of reference data for each individual in
%                   targetEvents.
%   targetEvents    Cell vector, containing vectors of target data.
%   lagSize         Vector with two numbers indicating the size of the lag examined 
%                   on either side of a reference event. The first number indicates
%                   the number of samples examined prior to an event, and the 2nd 
%                   number indicates the number of samples examined after an event. 
%                   The size of the PSTH is sum(lagSize)+1
%   numPerms        Number of permutations
%   eventSpecs      Optional struct with information about how the target and 
%                   reference data were calculated
%
%
% OUTPUT 
%   Struct with the following fields: (TODO finish this)
%       psth - Peri-stimulus time histogram
%       nRefsNoEvents - Number of reference sets that had no events.
%       nTargetPadding - Number of events in which it was necessary to pad 
%           the target data on either side of the event. TODO
%       RefEvents - 
%       prctile05 - 1 x f vector with the 95th percentile blink rate found
%           by permutation testing.
%       prctile95 - 1 x f vector with the 5th percentile blink rate found
%           by permutation testing.
% 
%       inputs - struct with information about the input variables:
%           numIndividuals - number of individuals in targetEvents
%           dataLen - length of data
%           numPerms - number of permutations
%           refEventType - reference event type
%           refCode - reference code
%           targetEventType - target event type
%           targetCode - target code
%           startFrame - start frame
% 
% SEE ALSO: BLINKPSTHSUMMARY, BLINKPSTHFIGURES

% Written by Carolyn Ranti
% 2.27.2015
% Adapted from code written by Jenn Moriuchi, Grace Ann Marrinan, and Sarah Shultz


%% Set up
[numPpl, dataLen] = size(targetEvents);
numRefSets = length(refEvents);

if numRefSets > 1 && numRefSets ~= numPpl
    error('If more than one reference set is provided, there must be exactly one per individual.')
end

%TODO - each reference set must match only the corresponding target data
%(they can all be different lengths from each other) - fix this error check
% TODO - also, change the input format for the target data to match
% reference events (cell with vectors)
% TODO - readInTargetData
refLen = unique(cellfun(@length, refEvents));
if length(refLen)>1 || refLen ~= dataLen
    error('Target data and reference events must be the same length.')
end

assert(length(lagSize)==2), 'LagSize must be a vector with 2 numbers.');
windowSize = sum(lagSize) + 1;


%defaults
startFrame = 1;
refEventType = 'allFrames';

% Parse optional inputs and check
assert(mod(length(varargin),2)==0, 'Error - odd number of optional parameters (must be name, value pairs)');


for v = 1:2:length(varargin)
   switch lower(varargin{v})
       case 'refeventtype'
           refEventType = varargin{v+1};
           assert(sum(strcmpi(refEventType,{'allFrames','firstFrameOnly'}))==1,'refEventType must be either allFrames or firstFrameOnly');
       case 'targeteventtype'
           targetEventType = varargin{v+1};
           assert(sum(strcmpi(targetEventType,{'allFrames','firstFrameOnly'}))==1,'targetEventType must be either allFrames or firstFrameOnly');
       case 'startframe'
           startFrame = varargin{v+1};
           assert(startFrame>0 && startFrame<=dataLen,'startFrame must be positive and less than the length of the data.');
       otherwise
            error('BlinkGUI:input','Unrecognized parameter name %s',varargin{v})  
   end
end


%% Calculate cross-correlogram
results = makePSTH(refEvents, targetEvents, lagSize);

% Add reference events to the results struct
results.RefEvents = RefEvents;

%% Permutation testing
permResults = zeros(numPerms, windowSize);
permutedData = targetEvents; %initialize permutedData as targetEvents -- it's overwritten in each loop
for p = 1:numPerms
    %TODO - circshift data. shift each subject independently, right?
    shiftSizes = round(2*dataLen*rand(numPpl,1) - dataLen);
    for ii = 1:numPpl
        permutedData(ii,:) = circshift(targetEvents(ii,:),[0, shiftSizes(ii)]);
    end
    temp = makePSTH(refEvents, permutedData, lagSize);
    permResults(p,:) = temp.crossCorr;
end

% Add 5th and 95th percentiles to results
results.prctile05 = prctile(permResults,5);
results.prctile95 = prctile(permResults,95);

%% Add inputs to results struct
results.inputs = struct();
if nargin<5
    eventSpecs = struct();
end

results.inputs.numIndividuals = numPpl;
results.inputs.numFrames = dataLen;
results.inputs.numPerms = numPerms;

%TODO - for each field, if eventSpecs has it, put in inputs
%TODO - definitely should do some error checking...
results.inputs.refEventType = eventSpecs.refEventType;
results.inputs.refCode = eventSpecs.refCode;
results.inputs.targetEventType = eventSpecs.targetEventType;
results.inputs.targetCode = eventSpecs.targetCode;
results.inputs.startFrame = eventSpecs.startFrame;


end


%% Make a peri-stimulus time histogram
% TODO - check and document me
function results = makePSTH(refEvents, targetEvents, lagSize)
    
    numRefSets = length(refEvents);
    numIndivs = size(targetEvents,1);
    windowSize = sum(lagSize) + 1;

    % Set counters at 0
    nRefsNoEvents = 0; %number of reference sets with no events
    nTargetPadding = zeros(1,3); %leftFill,rightFill, both

    AllCrossCorr = zeros(numIndivs, windowSize);

    if numRefSets == 1
        refFrames = refEvents{1};  
        if isempty(refFrames)
            error('No reference events.')
        end
    end

    % Loop through target group participants
    for targ = 1:numIndivs 

        % get the target-specific reference set, if applicable.
        if numRefSets>1     
            refFrames = refEvents{targ};

            % If no reference frames, skip ahead 
            % (this condition has already been checked if there's only one ref. set)
            if isempty(refFrames)
                nRefsNoEvents = nRefsNoEvents + 1;
                AllCrossCorr(targ,:) = NaN(1, windowSize);
                continue
            end
        end

        % get target data
        thisTarget = targetEvents(targ,:);

        % Loop through reference frames in the reference set
        tempCrossCorrCounters = zeros(1, windowSize);
        refFrameCount = 0; %counter - how many reference frames were used
        for r = 1:length(refFrames)

            timeZero = refFrames(r);
            
            % Define target window around timeZero.
            target = thisTarget(max(startFrame,(timeZero-lagSize(1))):min(dataLen,(timeZero+lagSize(2))));
            
            %Pad, if necessary, with 0s.
            leftFill = []; rightFill = [];
            if (timeZero - lagSize(1)) < startFrame
                leftFill = zeros(1, startFrame - (timeZero-lagSize(1)));
            end
            if (timeZero + lagSize(2)) > dataLen
                rightFill = zeros(1,(timeZero+lagSize(2))-dataLen);
            end
            
            target = [leftFill, target, rightFill];
            
            %Advance padding counters
            if ~isempty(leftFill) %just left
                nTargetPadding(1,1) = nTargetPadding(1,1) + 1;
                if ~isempty(rightFill) %both
                    nTargetPadding(1,2) = nTargetPadding(1,2) + 1;
                    nTargetPadding(1,3) = nTargetPadding(1,3) + 1;
                end
            elseif ~isempty(rightFill) %just right
                nTargetPadding(1,2) = nTargetPadding(1,1) + 1;
            end
            
            % Add cross-corr hits (if there is <20% lost data during target events)
            if sum(isnan(target)) < (.2*length(target))
                refFrameCount = refFrameCount + 1;
                target(find(isnan(target))) = 0;
                tempCrossCorrCounters = tempCrossCorrCounters + target;
            end
        end
        
        % Store cross-corr count for this subject-to-subject comparison, averaged across number of reference events
        if refFrameCount > 0
            AllCrossCorr(targ,:) = tempCrossCorrCounters / refFrameCount;
        else 
            
            AllCrossCorr(targ,:) = NaN(1, windowSize);
        end
    end %end of target loop

    % Average cross-corr counters across all target group participants. 
    % This is our group average cross-correlation.
    crossCorr = nanmean(AllCrossCorr,1);

    %% results struct
    results = struct();
    results.psth = crossCorr;
    results.nRefsNoEvents = nRefsNoEvents;
    results.nTargetPadding = nTargetPadding;
end
