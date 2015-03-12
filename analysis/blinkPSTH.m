function results = blinkPSTH(refEvents, targetEvents, lagSize, numPerms, varargin)
%BLINKPSTH - Create a peri-stimulus time histogram using a group's blink
%data.
%
% TODO - document this method, test
%
% INPUTS
%   refEvents       Cell vector, containing row vectors of reference data.
%                   There can be a single set of reference data (i.e. 1x1
%                   cell) or a set of reference data corresponding to each
%                   individual in targetEvents.
%   targetEvents    Cell vector, containing row vectors of target data.
%                   Each individual should have their own entry.
%   lagSize         Vector with two numbers indicating the size of the lag
%                   examined on either side of a reference event. The first
%                   number indicates the number of samples examined prior
%                   to an event, and the 2nd number indicates the number of
%                   samples examined after an event. The size of the PSTH
%                   is sum(lagSize)+1
%   numPerms        Number of permutations. If this is empty or <=0, 
%                   permutation testing is not done.
%
% Optional parameters (pass in as name/value pair):
%   'startFrame'    First frame to start including target and reference
%                   events (e.g. if you want to avoid an artifact from the 
%                   beginning of a movie). Default is 1.
%   'inclThresh'    Threshold for including target data in the PSTH. This
%                   value (0 - 1) indicates the percent of valid data (i.e.
%                   not NaN) around a particular event needed to include
%                   that segment in the analysis. Default is 0.2
%   'lowPrctile'    Low percentile to test for significantly lower blinking
%                   (used in permutation testing). Default is 2.5
%   'highPrctile'   High percentile to test for significantly higher blinking
%                   (used in permutation testing). Default is 97.5
%
%
% OUTPUT
%   Struct with the following fields: 
%       psth - Overall peri-stimulus time histogram. Average of PSTHs
%           calculated for each subject.
%       indivPSTH - Matrix with the PSTH calculated for each person. Each
%           individual is in a separate row.
%       indivTotalRefEventN - Number of total reference events for each
%           individual. If there is only one reference set, this value is 
%           the same for everyone.
%       indivUsedRefEventN - Number of reference sets included in analyses
%           for each individual. This value may differ between individuals
%           even if there is only a single reference set, based on the
%           include threshold setting and the amount of lost data (NaNs)
%           for each individual.
%       nRefSetsNoEvents - Number of reference sets that had no events
%           contributing to the PSTH.
%       nTargetPadding - Number of events in which it was necessary to pad 
%           the target data on either side of the event. This is a vector
%           with 3 values: number of events that needed padding on the
%           left, number of events that needed padding on the right, and
%           number of events that needed padding on both sides. Padding
%           occurs if (event index - left lag size) < 0 or (event index + 
%           right lag size) > target data size
%       
%       permTest - struct with results from permutation testing *
%           numPerms - number of permutations
%           lowPrctileLevel - Percentile level used to test for
%               significantly decreased blinking.
%           highPrctileLevel - Percentile level used to test for
%               significantly increased blinking.
%           lowPrctile - 1 x f vector with the high percentile blink rate
%               from the permutation test
%           highPrctile - 1 x f vector with the low percentile blink rate
%               from the permutation test
%           mean - 1 x f vector with the mean blink rate from the
%               permutation test
%       * If permutation testing is not run, this is an empty struct.
%       
%       inputSpecs - struct with details about the inputs provided
%           numTargets - number of entries in targetEvents
%           numRefSets - number of entries in refEvents
%           targetLens - length of each entry in targetEvents
%           refLens - length of each entry in refEvents
%           inclThresh - threshold for including a segment of target data
%           startFrame - frame to start including reference and target
%               events
%
% SEE ALSO: GETREFEVENTS, GETTARGETEVENTS, BLINKPSTHSUMMARY, BLINKPSTHFIGURES

% Written by Carolyn Ranti
% 3.3.2015
% Adapted from code written by Jenn Moriuchi, Grace Ann Marrinan, and Sarah Shultz

% TODO - add to GUI/summary writing file
%         refEventType - reference event type
%         refCode - reference code
%         targetEventType - target event type
%         targetCode - target code

% TODO - write a data quality check script for GUI

warning('THIS CODE HAS NOT BEEN THOROUGHLY CHECKED YET');

%% Set up

assert(iscell(targetEvents), 'Error in blinkPSTH: targetEvents must be a cell');
assert(iscell(refEvents), 'Error in blinkPSTH: refEvents must be a cell');

numTargets = length(targetEvents);
numRefSets = length(refEvents);
allDataLens = cellfun(@length, targetEvents);

if numRefSets > 1 && numRefSets ~= numTargets
    error('Error in blinkPSTH: If more than one reference set is provided, there must be exactly one per individual.')
end

%Check that reference frames are <= length of each corresponding target data set
maxRefValue = cellfun(@max, refEvents);
assert(prod(allDataLens >= maxRefValue) == 1, 'Error in blinkPSTH: all reference event indices must be <= length of the target data');

%Check that all vectors in targetEvents are ROW VECTORS. 
assert(prod(cellfun(@isrow, targetEvents)) == 1, 'Error in blinkPSTH: entries in targetEvents must be row vectors');

%Check that lagSize has 2 values
assert(length(lagSize)==2 && isnumeric(lagSize), 'Error in blinkPSTH: LagSize must be a vector with 2 numbers.');
windowSize = sum(lagSize) + 1;

%Figure out whether to run permutation test
runPermTest = (nargin>=4) && (~isempty(numPerms)) && (numPerms >= 0);


%% Parse optional inputs and check
assert(mod(length(varargin),2)==0, 'Error in blinkPSTH: Odd number of optional parameters (must be name, value pairs)');

%defaults
startFrame = 1;
inclThresh = .2; 
lowPrctileLevel = 2.5; 
highPrctileLevel = 97.5;

for v = 1:2:length(varargin)
   switch lower(varargin{v})
       case 'startframe'
           startFrame = varargin{v+1};
           if ~isnumeric(startFrame) || ~isscalar(startFrame) || startFrame<0
              error('startFrame must be a positive numeric value');
           end
       case 'inclthresh'
           inclThresh = varargin{v+1};
           if ~isnumeric(inclThresh) || ~isscalar(inclThresh) || inclThresh<0 || inclThresh>1
               error('inclThresh must be a numeric value between 0 and 1');
           end
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
       otherwise
           warning('Unknown parameter - skipping (%s)', varargin{v});
   end
end


%% Calculate cross-correlogram

results = makePSTH(refEvents, targetEvents, lagSize, startFrame, inclThresh);

%% Permutation testing

if runPermTest
    permResults = zeros(numPerms, windowSize);
    permutedData = targetEvents; %initialize as targetEvents (but it's overwritten in each loop)

    for p = 1:numPerms
        % circshift data: shift each subject independently 
        shiftSizes = round(allDataLens*rand(numTargets,1));
        for ii = 1:numTargets
            permutedData{ii} = circshift(targetEvents{ii}, shiftSizes(ii), 2); %TODO - check this/make sure that 
        end
        temp = makePSTH(refEvents, permutedData, lagSize, startFrame, inclThresh);
        permResults(p,:) = temp.psth;
    end

    % Add low and high percentile values to results
    results.permTest.numPerms = numPerms;
    results.permTest.lowPrctileLevel = lowPrctileLevel;
    results.permTest.highPrctileLevel = highPrctileLevel;
    results.permTest.lowPrctile = prctile(permResults, lowPrctileLevel);
    results.permTest.highPrctile = prctile(permResults, highPrctileLevel);
    results.permTest.mean = mean(permResults); %TODO - consider whether to make this median 
else
    results.permTest = struct();
end

%% Add input specs
results.inputSpecs.numTargets = numTargets;
results.inputSpecs.numRefSets = numRefSets;
results.inputSpecs.targetLens = cellfun(@length, targetEvents);
results.inputSpecs.refLens = cellfun(@length, refEvents);
results.inputSpecs.inclThresh = inclThresh;
results.inputSpecs.startFrame = startFrame;

end


%% Make a peri-stimulus time histogram
function results = makePSTH(refEvents, targetEvents, lagSize, startFrame, inclThresh)
    
    numRefSets = length(refEvents);
    numIndivs = length(targetEvents);
    windowSize = sum(lagSize) + 1;

    % Set counters at 0
    nRefSetsNoEvents = 0; %number of reference sets with no events
    nTargetPadding = zeros(1,3); %leftFill, rightFill, both

    indivPSTH = zeros(numIndivs, windowSize);

    if numRefSets == 1
        refFrames = refEvents{1};  
        if isempty(refFrames)
            error('No reference events.')
        end
    end

    %preallocate storage vars
    indivTotalRefEvents = nan(numIndivs,1); %number of reference events for each 
    indivUsedRefEvents = nan(numIndivs,1);
    
    % Loop through target group participants
    for targ = 1:numIndivs 

        % get the target-specific reference set, if applicable.
        if numRefSets>1     
            refFrames = refEvents{targ};

            % If no reference frames, skip ahead 
            % (this condition has already been checked if there's only one ref. set)
            if isempty(refFrames)
                nRefSetsNoEvents = nRefSetsNoEvents + 1;
                indivPSTH(targ,:) = NaN(1, windowSize);
                continue
            end
        end

        % get target data
        thisTarget = targetEvents{targ};
        
        % length of this person's data
        dataLen = length(thisTarget);

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
            if ~isempty(leftFill) && ~isempty(rightFill) %both
                nTargetPadding(3) = nTargetPadding(3) + 1;
            elseif ~isempty(leftFill) %just left
                nTargetPadding(1) = nTargetPadding(1) + 1;
            elseif ~isempty(rightFill) %just right
                nTargetPadding(2) = nTargetPadding(2) + 1;
            end
            
            % Add hits (as long as there's enough included data)
            if sum(~isnan(target)) > inclThresh*dataLen
                refFrameCount = refFrameCount + 1;
                target(isnan(target)) = 0;
                tempCrossCorrCounters = tempCrossCorrCounters + target;
            end
        end
        
        % Average across number of reference events and store this
        % individual's PSTH
        if refFrameCount > 0
            indivPSTH(targ,:) = tempCrossCorrCounters ./ refFrameCount;
        else 
            indivPSTH(targ,:) = NaN(1, windowSize);
        end
        
        %store the number of reference events (per person) and the number
        %of reference events used (i.e. the number with a sufficient amount
        %of included data)
        indivTotalRefEvents(targ) = length(refFrames);
        indivUsedRefEvents(targ) = refFrameCount;
        
    end %end of target loop

    % If none of the reference sets had events
    if nRefSetsNoEvents== numRefSets
        error('No reference events.');
    end
    
    % Average PSTH across all target group participants. 
    overallPSTH = nanmean(indivPSTH,1);

    %% results struct
    results = struct();
    results.psth = overallPSTH;
    results.indivPSTH = indivPSTH;
    results.indivTotalRefEventN = indivTotalRefEvents;
    results.indivUsedRefEventN = indivUsedRefEvents;
    results.nRefSetsNoEvents = nRefSetsNoEvents;
    results.nTargetPadding = nTargetPadding;
end
