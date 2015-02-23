%CROSSCORRELOGRAM
%
% INPUTS
%   refEvents       Cell vector, containing vectors of reference data.
%           There can be a single set of reference data (i.e. a 1x1 cell)
%           or reference data corresponding to each individual in
%           targetEvents.
%   refCode         Value in refEvents that indicates the occurrence of a
%           reference event. 
%   targetEvents    Cell vector, containing vectors of target data.
%   targetCode      Value in targetEvents that indicates the occurrence of
%           a target event. If this variable is empty, then the target data
%           will be treated as a continuous measure. 
%   lagMax          Size of the lag examined on either side of the
%           reference event. The cross-correlogram size will be determined
%           by this variable (2*lagMax + 1)
%
% Optional inputs - name/value pairs
%   'startFrame'    Index to start including data for (default = 1). Must
%           be a positive integer that is <= length of the clip. Can be 
%           used to exclude something from the beginning of your data (e.g.
%           effects from a centering stim prior to the clip).
%   'refEvent'      'allFrames' (default) or 'firstFrameOnly'
%   'targetEvent'   'allFrames' (default) or 'firstFrameOnly'
%   'autoCrossCorr'  0 (default) or 1.  Should be true if the target 
%           individuals are being compared to everyone else in the group
%           (i.e. if you're passing in the same values for refEvents and
%           targetEvents)
%
% OUTPUT 
%   output - struct with the following fields:
%       TargetGroupAllCrossCorr - every individual comparison, averaged by
%           # ref events (??TODO - check)
%       TargetGroupIndivCrossCorr - this is a set of each individual cross-
%           correlogram. There is one per target individual, and they are 
%           averaged over the comparisons for that person. (??TODO - check)
%       TargetGroupAvgCrossCorr - this is the overall cross-correlogram, an
%           average count of the number of target events that occur before
%           and after each reference event. The average is weighted by 
%           target individuals (e.g. mean of TargetGroupIndivCrossCorr). (??TODO - check)
%       RefGroupEvents - reference event frames for each reference group 
%           participant.
% 
%   counters - Extra information. Struct with the following fields:
%       compareCount - number of comparisons between a set of reference
%           events and a set of target events.
%       nRefsNoEvents - number of reference event sets that had no
%           qualifying reference events (i.e. after specified startFrame)
%       nTargetPadding - vector with 3 numbers, indicating how many times 
%           padding was necessary around. The values are: 
%               > leftFill - # times had to pad before an event w/ 0s
%               > rightFill - # times had to pad after an event w/ 0s
%               > both - # times had to pad both before and after an event
%
%
% TODO 
% clean up output (both the documentation and possibly what i'm outputting)
% autocorrelation option? is this something we want to do for blinking?
% input checking / error handling
% verify, document (see orig. script)
%
% 12.3.2014
% Written by Carolyn Ranti
% Adapted from code written by Jenn Moriuchi, Grace Ann Marrinan, and Sarah
% Shultz


function [output, counters] = crossCorrelogram(refEvents,refCode,targetEvents,targetCode,lagMax,varargin)

%% Error checking - TODO

assert(min(size(refEvents))==1,'Error in crossCorrelogram: refEvents must be a cell vector.');
assert(min(size(targetEvents))==1,'Error in crossCorrelogram: targetEvents must be a cell vector.');

refEventLen = cellfun(@length,refEvents);
targetEventLen = cellfun(@length,targetEvents);

try
    checkLen = min(refEventLen == targetEventLen);
catch
    error('Error in crossCorrelogram - issue checking input sizes');
end
assert(checkLen==1, 'Error in crossCorrelogram: all items in refEvents and targetEvents must be the same length');

% assert that all vectors in those two are the same length

% if any of the vectors are horizontal, swap them (??)

%% Set up / parse optional inputs
numIndivs = length(targetEvents);
numRefSets = length(refEvents);
clipLength = length(refEvents{1});

%defaults
startFrame = 1;
refEventType = 'allFrames';
targetEventType = 'allFrames';
autoCrossCorr = 0; % if group is being compared to everyone else in group

for v = 1:2:length(varargin)
   switch varargin{v}
       case 'refEvent'
           refEventType = varargin{v+1};
           assert(strcmpi(refEventType,'allFrames')||strcmpi(refEventType,'firstFrameOnly'),'refEvent must be allFrames or firstFrameOnly.');
       case 'targetEvent'
           targetEventType = varargin{v+1};
           assert(strcmpi(targetEventType,'allFrames')||strcmpi(targetEventType,'firstFrameOnly'),'targetEvent must be allFrames or firstFrameOnly.');
       case 'startFrame'
           startFrame = varargin{v+1};
           assert(isint(startFrame) && startFrame>0 && startFrame<=clipLength,'startFrame must be a positive integer that is less than the length of the data.');
       case 'autoCrossCorr'
           autoCrossCorr = varargin{v+1};
           assert(autoCrossCorr==1 || autoCrossCorr ==0,'autoCrossCorr must equal 1 or 0');
       otherwise        
   end
end

if strcmpi(targetEventType,'firstFrameOnly')
    assert(~isempty(targetCode),'Cannot use continuous measure (i.e. empty targetCode) when targetEventType = firstFrameOnly');
end

%% Preallocate, set counters

RefGroupEvents = cell(numRefSets,1); % to store reference event frames for each ref group participant.
AllCrossCorr = cell(numIndivs,1); %store every ind. comparison, averaged by # ref events
IndivCrossCorr = cell(numIndivs,1); % to store indiv cross-corr, averaged across number of comparisons (i.e. ref group n)

%counters
compareCount = 0;
nRefsNoEvents = 0;
nTargetPadding = zeros(1,3); %leftFill,rightFill, both


%% Loop through reference event sets
for ref = 1:numRefSets    
    
    %% Find reference events
    
    refFrames = [];
    if strcmp(refEventType,'allFrames')
        refFrames = find(refEvents{ref} == refCode);
        
    elseif strcmp(refEventType,'firstFrameOnly')
    	temp = diff([0,(refEvents{ref} == refCode)]);
    	refFrames = find(temp==1);
    end
    
    % Filter to reference frames after the specified startFrame
    if ~isempty(refFrames)
        refFrames = refFrames(refFrames >= startFrame);
    end
    
    % If there are no reference frames, skip ahead
    if isempty(refFrames)
    	nRefsNoEvents = nRefsNoEvents + 1; %update counter
        for targ = 1:numIndivs
            AllCrossCorr{targ}(ref,:) = NaN(1, 2*lagMax + 1);
        end
        continue
    end
    
	
    
    %% Calculate cross-correlogram hits
    for targ = 1:numIndivs % Loop through target group participants

        % Check to ensure you do not include auto-cross-correlations
        % (i.e. not comparing one participant to him/herself)
        if autoCrossCorr
            if ref == targ
                AllCrossCorr{targ}(ref,:) = NaN(1, 2*lagMax + 1);
                continue
            end
        end                
        
        tempCrossCorrCounters = zeros(1,(2*lagMax + 1));
        compareCount = compareCount + 1;
        
        % Define target participant data for this comparison. 
        if strcmp(targetEventType,'allFrames')
            thisTarget = targetEvents{targ};
            % if TargetCode is empty, leave values in there. Otherwise, turn it into a logical
            if ~isempty(targetCode)
            	thisTarget = (thisTarget == targetCode);
            end
        elseif strcmp(targetEventType,'firstFrameOnly')
            temp = diff([0, targetEvents{targ} == targetCode]); 
            thisTarget = (temp==1);
        end

        % Loop through reference frames
        refFrameCount = 0; %how many reference frames were used
        for eventIndex = 1:length(refFrames)
            
            timeZero = refFrames(eventIndex);
            
            % Define target window around timeZero.
            target = thisTarget(max(startFrame,(timeZero-lagMax)):min(clipLength,(timeZero+lagMax)));
            
            %Pad, if necessary, with 0s.
            leftFill = []; rightFill = [];
            if (timeZero - lagMax) < startFrame
                leftFill = zeros(1, startFrame - (timeZero-lagMax));
            end
            if (timeZero + lagMax) > clipLength
                rightFill = zeros(1,(timeZero+lagMax)-clipLength);
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
            if sum(isnan(target),2) < (.2*length(target))
                refFrameCount = refFrameCount + 1;
                target(find(isnan(target))) = 0;
                tempCrossCorrCounters = tempCrossCorrCounters + target;
            end
        end
        
        % Store cross-corr count for this subject-to-subject comparison, averaged across number of reference events
        if refFrameCount > 0
        	AllCrossCorr{targ}(ref,:) = tempCrossCorrCounters / refFrameCount;
        else
        	AllCrossCorr{targ}(ref,:) = NaN(1, 2*lagMax + 1);
        end
    end %end of target loop

    %store reference events
    RefGroupEvents{ref} = refFrames; 
end % end of ref loop

% Next, average cross-corr counters across all reference participant
% comparisons, then across all target group participants. This is our group
% average cross-correlation.
tempCrossCorrAvgs = zeros(numIndivs, 2*lagMax+1);
for targ = 1:numIndivs
    tempCrossCorrAvgs(targ,:) = nanmean(AllCrossCorr{targ},1); %store into temp matrix in order to get group average for this clip
    IndivCrossCorr{targ} = tempCrossCorrAvgs(targ,:); %also store cross-corr for an individual across all comparisons for this clip
end

%average everything (weighted by target individual)
TargetGroupAvgCrossCorr = nanmean(tempCrossCorrAvgs,1);


%% Output structs
output = struct();

output.TargetGroupAllCrossCorr = AllCrossCorr;
output.TargetGroupIndivCrossCorr = IndivCrossCorr;
output.TargetGroupAvgCrossCorr = TargetGroupAvgCrossCorr;
output.RefGroupEvents = RefGroupEvents;


counters = struct();
counters.compareCount = compareCount;
counters.nRefsNoEvents = nRefsNoEvents;
counters.nTargetPadding = nTargetPadding;

