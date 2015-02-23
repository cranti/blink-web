function results = blinkPSTH(refEvents,refCode,targetEvents,targetCode,lagMax,numPerms,varargin)
%BLINKPSTH - Create a peri-stimulus time histogram using a group's blink
%data.
%
% INPUTS
%   refEvents       Cell vector, containing vectors of reference data.
%           There can be a single set of reference data (i.e. a 1x1 cell)
%           or reference data corresponding to each individual in
%           targetEvents.
%   refCode         Value in refEvents that indicates the occurrence of a
%           reference event.
%   targetEvents    Matrix, with target data. TODO
%   targetCode      Value in targetEvents that indicates the occurrence of
%           a target event. If this variable is empty, then the target data
%           will be treated as a continuous measure. 
%   lagMax          Size of the lag examined on either side of the
%           reference event. The cross correlogram size will be determined
%           by this variable (2*lagMax + 1)
%   numPerms        Number of permutations
%
%
% Optional inputs - name/value pairs
%   'startFrame'        Index to start including data for (default = 1). Must
%               be a positive integer that is <= length of the clip. Can be 
%               used to exclude something from the beginning of your data (e.g.
%               effects from a centering stim prior to the clip).
%   'refEventType'      'allFrames' (default) or 'firstFrameOnly'
%   'targetEventType'   'allFrames' (default) or 'firstFrameOnly'
%
% OUTPUT 
%   A struct with the following fields:
%       TODO
%
% TODO 
% - input checking / error handling
% - verify
% - Document
% - if any vectors are horizontal, swap 'em
% 
% See also: BLINKPSTHSUMMARY, BLINKPSTHFIGURES

% Written by Carolyn Ranti
% 2.23.2015
% Adapted from code written by Jenn Moriuchi, Grace Ann Marrinan, and Sarah Shultz


%% Set up
[numPpl, dataLen] = size(targetEvents);
numRefSets = length(refEvents);

if numRefSets > 1 && numRefSets < numPpl
    error('If more than one reference set is provided, there must be exactly one per individual.')
end

refLen = unique(cellfun(@length, refEvents));
if length(refLen)>1 || refLen ~= dataLen
    error('Target data and reference events must be the same length.')
end

%defaults
startFrame = 1;
refEventType = 'allFrames';
targetEventType = 'allFrames';

% Parse optional inputs and check
for v = 1:2:length(varargin)
   switch varargin{v}
       case 'refEventType'
           refEventType = varargin{v+1};
           assert(sum(strcmpi(refEventType,{'allFrames','firstFrameOnly'}))==1,'refEventType must be either allFrames or firstFrameOnly');
       case 'targetEventType'
           targetEventType = varargin{v+1};
           assert(sum(strcmpi(targetEventType,{'allFrames','firstFrameOnly'}))==1,'targetEventType must be either allFrames or firstFrameOnly');
       case 'startFrame'
           startFrame = varargin{v+1};
           assert(startFrame>0 && startFrame<=dataLen,'startFrame must be positive and less than the length of the data.');
       otherwise        
   end
end

if strcmpi(targetEventType,'firstFrameOnly')
    assert(~isempty(targetCode),'Cannot use continuous measure (i.e. empty targetCode) when targetEventType = firstFrameOnly');
end


%% Find reference events in the sets
allRefFrameSets = getRefFrameSets(refEvents, refCode, refEventType);

%% Convert input data to targets 
allTargetEvents = getTargetEvents(targetEvents, targetCode, targetEventType);

%% Calculate cross-correlogram
results = makePSTH(allRefFrameSets, allTargetEvents, lagMax);

% Add reference events to the results struct
results.RefEvents = RefEvents;

%% Permutation testing
permResults = zeros(numPerms, 2*lagMax+1);
permutedData = allTargetEvents; %initialize permutedData as allTargetEvents -- it's overwritten in each loop
for p = 1:numPerms
    %TODO - circshift data. shift each subject independently, right?
    shiftSizes = round(2*dataLen*rand(numPpl,1) - dataLen);
    for ii = 1:numPpl
        permutedData(ii,:) = circshift(allTargetEvents(ii,:),[0, shiftSizes(ii)]);
    end
    temp = makePSTH(allRefFrameSets, permutedData, lagMax);
    permResults(p,:) = temp.crossCorr;
end

% Add 5th and 95th percentiles to results
results.prctile05 = prctile(permResults,5);
results.prctile95 = prctile(permResults,95);

%% Add inputs to results
results.inputs = struct();
results.inputs.numIndividuals = numPpl;
results.inputs.numFrames = dataLen;
results.inputs.numPerms = numPerms;
results.inputs.refEventType = refEventType;
results.inputs.refCode = refCode;
results.inputs.targetEventType = targetEventType;
results.inputs.targetCode = targetCode;
results.inputs.startFrame = startFrame;

end


%% Functions

% Output cell of reference frame sets - each set (row in refEvents) turns into 
% a logical vector (in it's own entry)
function allRefFrameSets = getRefFrameSets(refEvents, refCode, refEventType)
    numRefSets = size(refEvents,1); % each row is a reference set
    allRefFrameSets = cell(numRefSets); % to store reference event frames for each ref group participant.
    
    for ref = 1:numRefSets
        
        refFrames = [];
        if strcmpi(refEventType,'allFrames')
            refFrames = find(refEvents{ref} == refCode); 
        elseif strcmpi(refEventType,'firstFrameOnly')
            temp = diff([0,(refEvents{ref} == refCode)]);
            refFrames = find(temp==1);
        end
        
        refFrames = refFrames(refFrames >= startFrame);

        %store reference events in a cell
        allRefFrameSets{ref} = refFrames; 
    end
end

% Output a matrix of target events (one row/person)
%TODO - check this
function allTargetEvents = getTargetEvents(targetEvents, targetCode, targetEventType)
    numIndivs = size(targetEvents, 1);
    
    % if there is no target code, keep data the same (continuous measure)
    if isempty(targetCode)
        allTargetEvents = targetEvents;
    
    %otherwise, create a matrix with 1 = target event, 0 = no target, NaNs preserved
    else
        allTargetEvents = zeros(size(targetEvents));
        for ii = 1:numIndivs
            if strcmpi(targetEventType,'allFrames')
                thisTarget = (targetEvents(ii,:) == targetCode);
            elseif strcmpi(targetEventType,'firstFrameOnly')
                temp = diff([0, targetEvents{ii} == targetCode]); 
                thisTarget = (temp==1);
            end
            allTargetEvents(targ,:) = thisTarget;
        end
        % Put original NaNs back 
        origNans = isnan(targetEvents);
        allTargetEvents(origNans) = NaN;
    end
end

% Make a peri-stimulus time histogram
% TODO - check and document me
function results = makePSTH(allRefFrameSets, allTargetEvents, lagMax)
    
    numRefSets = length(allRefFrameSets);
    numIndivs = size(allTargetEvents,1);

    % Set counters at 0
    nRefsNoEvents = 0; %number of reference sets with no events
    nTargetPadding = zeros(1,3); %leftFill,rightFill, both

    AllCrossCorr = zeros(numIndivs, 2*lagMax+1);

    if numRefSets == 1
        refFrames = allRefFrameSets{1};  
        if isempty(refFrames)
            error('No reference events.')
        end
    end

    % Loop through target group participants
    for targ = 1:numIndivs 

        % get the target-specific reference set, if applicable.
        if numRefSets>1     
            refFrames = allRefFrameSets{targ};

            % If no reference frames, skip ahead 
            % (this condition has already been checked if there's only one ref. set)
            if isempty(refFrames)
                nRefsNoEvents = nRefsNoEvents + 1;
                AllCrossCorr(targ,:) = NaN(1, 2*lagMax + 1);
                continue
            end
        end

        % get target data
        thisTarget = allTargetEvents(targ,:);

        % Loop through reference frames in the reference set
        tempCrossCorrCounters = zeros(1,(2*lagMax + 1));
        refFrameCount = 0; %counter - how many reference frames were used
        for r = 1:length(refFrames)

            timeZero = refFrames(r);
            
            % Define target window around timeZero.
            target = thisTarget(max(startFrame,(timeZero-lagMax)):min(dataLen,(timeZero+lagMax)));
            
            %Pad, if necessary, with 0s.
            leftFill = []; rightFill = [];
            if (timeZero - lagMax) < startFrame
                leftFill = zeros(1, startFrame - (timeZero-lagMax));
            end
            if (timeZero + lagMax) > dataLen
                rightFill = zeros(1,(timeZero+lagMax)-dataLen);
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
            
            AllCrossCorr(targ,:) = NaN(1, 2*lagMax + 1);
        end
    end %end of target loop

    % Average cross-corr counters across all target group participants. 
    % This is our group average cross-correlation.
    crossCorr = nanmean(AllCrossCorr,1);

    %% results struct
    results = struct();
    results.crossCorr = crossCorr;
    results.nRefsNoEvents = nRefsNoEvents;
    results.nTargetPadding = nTargetPadding;
end
