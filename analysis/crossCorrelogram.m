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
%           reference event. The cross correlogram size will be determined
%           by this variable (2*lagMax + 1)
%
% Optional inputs - name/value pairs
%   'startFrame'    Index to start including data for (default = 1). Must
%           be a positive integer that is <= length of the clip. Can be 
%           used to exclude something from the beginning of your data (e.g.
%           effects from a centering stim prior to the clip).
%   'refEvent'      'allFrames' (default) or 'firstFrameOnly'
%   'targetEvent'   'allFrames' (default) or 'firstFrameOnly'
%   'autoCrossCorr'  0 (default) or 1.  Should be true if
%           the target individuals are being compared to everyone else in
%           the group (i.e. passing in the same values for refEvents and
%           targetEvents)
%
% OUTPUT 
%   A struct with the following fields:
%
% TODO 
% autocorrelation option? is this something we want to do for blinking?
% input checking / error handling
% verify, document (see orig. script)
%
% 12.3.2014
% Written by Carolyn Ranti
% Adapted from Jenn Moriuchi/Grace Ann Marrinan/Sarah Shultz's code


function output = crossCorrelogram(refEvents,refCode,targetEvents,targetCode,lagMax,varargin)

%% Error checking - TODO

% assert that refEvents and targetEvents are cell vectors
% assert that all vectors in those two are the same length

% if any of the vectors are horizontal, swap them

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
           assert(length(refEventType)==1,'refEvent must be a single value.');
       case 'targetEvent'
           targetEventType = varargin{v+1};
           assert(length(targetEventType)<=1,'targetEvent must be empty or a single value.');
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

RefGroupEvents = cell(numRefSets); % to store reference event frames for each ref group participant.
AllCrossCorr = cell(numIndivs); %store every ind. comparison, averaged by # ref events
IndivCrossCorr = cell(numIndivs); % to store indiv cross-corr, averaged across number of comparisons (i.e. ref group n)

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
    
    % If no reference frames, skip ahead
    if isempty(refFrames)
    	nRefsNoEvents = nRefsNoEvents + 1;
        for targ = 1:numIndivs
            AllCrossCorr{targ}(ref,:) = NaN(1, 2*lagMax + 1);
        end
        continue
    end
    
	refFrames = refFrames(refFrames >= startFrame);
    
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
            thisTarget(1,:) = targetEvents{targ};
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
            
            timeZero = refFrames(eventIndex,1);
            
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

%% Output struct
output = struct();
output.TargetGroupAllCrossCorr = AllCrossCorr;
output.TargetGroupIndivCrossCorr = IndivCrossCorr;
output.TargetGroupAvgCrossCorr = TargetGroupAvgCrossCorr;
output.RefGroupEvents = RefGroupEvents;

output.compareCount = compareCount;
output.nRefsNoEvents = nRefsNoEvents;
output.nTargetPadding = nTargetPadding;

