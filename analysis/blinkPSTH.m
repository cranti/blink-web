function results = blinkPSTH(refEvents, targetEvents, lagSize, numPerms, varargin)
%BLINKPSTH - Create a peri-stimulus time histogram using a group's blink
%data. Assess significance via permutation testing, with the number of
%permutations specified.

% TODO - fix 2 names in indivPSTH
% TODO - update documentation

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
%   'sampleStart'   First sample to start including target and reference
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
%   'refLens'       Numeric vector containing the original length of each 
%                   reference event set. This is a variable output by
%                   GETREFEVENTS. If this parameter is passed in, it's used
%                   for error checking only: the script verifies that the
%                   length of each of the targetEvent sets matches the
%                   length reported by TODO
%   'hWaitBar'      Handle to a waitbar to update user with progress
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
%       * This only exists if permutation testing is run.
%       
%       changeFromMean - struct with additional results from permutation
%       testing:
%           psth - the PSTH represented as a percent change from the mean
%           value of the permuted data (for each sample).
%           
%
%       inputs - struct with details about the inputs provided
%           lagSize - size of the window on either side of the event
%           startFrame - frame to start including reference and target
%               events
%           inclThresh - threshold for including a segment of target data
%           numTargets - number of target event sets TODO - change everywhere to numTargetSets 
%           numRefSets - number of reference event sets
%           targetLens - number of samples in each target event set
%           refLens - number of samples in each reference event set. If the
%               optional input (refLens) isn't passed in, this is an empty
%               matrix.
%
% SEE ALSO: GETREFEVENTS, GETTARGETEVENTS, BLINKPSTHSUMMARY, BLINKPSTHFIGURES

% Written by Carolyn Ranti
% 6.4.2015
% Adapted from code written by Jenn Moriuchi, Grace Ann Marrinan, and Sarah Shultz

%% Set up

% Check type of inputs (switched formats from old code)
assert(iscell(targetEvents), 'targetEvents must be a cell.');
assert(iscell(refEvents), 'refEvents must be a cell.');

%
numTargets = length(targetEvents);
numRefSets = length(refEvents);
allDataLens = cellfun(@length, targetEvents);

%Check the number of ref sets (should be either 1 OR 1 per target set)
if numRefSets > 1 && numRefSets ~= numTargets
    error('If more than one reference set is provided, there must be exactly one per individual.')
end

%Check that reference frames are <= length of each corresponding target data set
maxRefValue = cellfun(@max, refEvents);
assert(prod(allDataLens >= maxRefValue) == 1, 'All reference event indices must be <= length of the target data.');

%Check that all vectors in targetEvents are ROW VECTORS. 
assert(prod(cellfun(@isrow, targetEvents)) == 1, 'Entries in targetEvents must be row vectors.');

%Check that lagSize has 2 values
assert(length(lagSize)==2 && isnumeric(lagSize), 'LagSize must be a vector with 2 numbers.');
windowSize = sum(lagSize) + 1;

%Figure out whether to run permutation test
runPermTest = (nargin>=4) && (~isempty(numPerms)) && (numPerms > 0);

%% Parse optional inputs and check
assert(mod(length(varargin),2)==0, 'Odd number of optional parameters (must be name, value pairs)');

%defaults
sampleStart = 1;
inclThresh = .2; 
lowPrctileLevel = 2.5; 
highPrctileLevel = 97.5;
refLens = [];

for v = 1:2:length(varargin)
   switch lower(varargin{v})
       case 'samplestart'
           sampleStart = varargin{v+1};
           if ~isnumeric(sampleStart) || ~isscalar(sampleStart) || sampleStart<0
              error('sampleStart must be a positive numeric value');
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
       case 'reflens'
           refLens = varargin{v+1};
           if ~isnumeric(refLens)
               error('refSetLen must be numeric');
           end
           
           if length(refLens) == 1
               if ~sum(allDataLens == refLens)
                  error('Mismatch between length of target event sets and length of reference event set.');
               end 
           elseif length(refLens) == numRefSets
               if (isrow(refLens) && ~isrow(allDataLens)) || (~isrow(refLens) && isrow(allDataLens))
                   refLens = refLens';
               end
               if ~isequal(allDataLens, refLens)
                  error('Mismatch between length of target event sets and length of reference event sets.');
               end
           else
               error('refSetLen must contain one value per set of reference data passed in.');
           end
           
       case 'hwaitbar'
           hWaitBar = varargin{v+1};
           %make sure it's a valid handle
           if ishandle(hWaitBar)
               haswaitbar = 1;
           end
   end
end

%% Initialize results struct:

%Structure
results = struct();
results.inputs = struct();
results.refEvents = struct();
results.targetEvents = struct();
results.groupPSTH = struct();
results.indivPSTH = struct();

%Fill in inputs
results.inputs.winSizeBefore = lagSize(1);
results.inputs.winSizeAfter = lagSize(2);
results.inputs.sampleStart = sampleStart;
results.inputs.numPerms = numPerms;
results.inputs.lowerPrctileCutoff = lowPrctileLevel;
results.inputs.upperPrctileCutoff = highPrctileLevel;
results.inputs.includeThresh = inclThresh; 

%Fill in refEvents
results.refEvents.numSets = numRefSets; 
results.refEvents.numSamples = refLens; 

%Fill in targetEvents
results.targetEvents.numSets = numTargets; 
results.targetEvents.numSamples = cellfun(@length, targetEvents);


%% Calculate cross-correlogram
if haswaitbar
    tstart = tic; 
    waitbar(0, hWaitBar, 'Creating PSTH...');
end

% Make PSTH, filling in results struct
[results.groupPSTH, results.indivPSTH] = makePSTH(refEvents, targetEvents, lagSize, sampleStart, inclThresh, 0);

%have it take at least 1/2 second (for message to be visible in waitbar)
if haswaitbar
    while toc(tstart) < .5; end 
    waitbar(1, hWaitBar);
end

%% Permutation testing
if runPermTest
    if haswaitbar
        waitbar(0, hWaitBar, 'Running Permutation Test...');
    end
    
    permResults = zeros(numPerms, windowSize);
    permutedData = targetEvents; %initialize as targetEvents (overwritten in each loop)

    for p = 1:numPerms
        
        if haswaitbar
            %Check for Cancel button press
            if getappdata(hWaitBar,'canceling')
                results = [];
                return
            end
        end
        
        % circshift data: shift each subject independently 
        shiftSizes = round(allDataLens.*rand(1,numTargets));
        for ii = 1:numTargets
            permutedData{ii} = circshift(targetEvents{ii}, shiftSizes(ii), 2);  %what to shift, how much to shift it, dimension of shift
        end
        
        permResults(p,:) = makePSTH(refEvents, permutedData, lagSize, sampleStart, inclThresh, 1); 
    
        %Update progress bar
        if haswaitbar
            waitbar(double(p)/double(numPerms), hWaitBar);
        end
    end

    if haswaitbar
        tstart = tic;
        waitbar(0, hWaitBar,'Calculating Significance...');
    end

    % Add permutation testing to groupPSTH
    results.groupPSTH.lowerPrctilePerm = prctile(permResults, lowPrctileLevel, 1); 
    results.groupPSTH.upperPrctilePerm = prctile(permResults, highPrctileLevel, 1);
    results.groupPSTH.meanPerm = mean(permResults, 1);
    
    % Calculate the PSTH as % change from the mean of permutations, and add
    % it to the results struct:
    results.groupPSTH.percChangeBPM = (results.psth - results.permTest.mean)./results.permTest.mean;
    results.groupPSTH.percChangeLowerPrctile = (results.permTest.lowPrctile - results.permTest.mean)./results.permTest.mean; 
    results.groupPSTH.percChangeUpperPrctile = (results.permTest.highPrctile - results.permTest.mean)./results.permTest.mean;
       
    if haswaitbar
        while toc(tstart) < .5; end 
        waitbar(1, hWaitBar);
    end
end


end


%% Make a peri-stimulus time histogram
function [groupPSTH, indivPSTH] = makePSTH(refEvents, targetEvents, lagSize, sampleStart, inclThresh, PERMFLAG)
%PERMFLAG - if 1, indicates permutation testing. Output is the overallPSTH,
%rather than the entire struct. Also, some counters are skipped

    numRefSets = length(refEvents);
    numIndivs = length(targetEvents);
    windowSize = sum(lagSize) + 1;
    sampleOffset = (-lagSize(1)):lagSize(2);

    % If there is only 1 ref set, it must have events in it
    if numRefSets == 1
        refFrames = refEvents{1};  
        if isempty(refFrames)
            error('No events in the reference set.')
        end
    % If there are multiple ref sets, at least one must have events
    else
        nonEmptyRefs = cellfun(@(x) ~isempty(x), refEvents);
        if sum(nonEmptyRefs)==0
            error('No events in any of the reference sets.')
        end
    end

    % Set counters at 0
    nRefSetsNoEvents = 0; %number of reference sets with no events
    nTargetPadding = zeros(numIndivs,3); %leftFill, rightFill, both
    indivTotalRefEvents = zeros(numIndivs,1); %total reference events for each target
    indivUsedRefEvents = zeros(numIndivs,1); %total ref events *used* for each target
    
    % initialized indivPSTH with NaNs
    indivPSTH = nan(numIndivs, windowSize);

    %% Loop through target group participants
    for targ = 1:numIndivs 

        % get the target-specific reference set, if applicable.
        if numRefSets>1     
            refFrames = refEvents{targ};

            % If no reference frames, skip ahead
            %  > this has been checked if there's only 1 ref set
            if isempty(refFrames)
                nRefSetsNoEvents = nRefSetsNoEvents + 1;
                continue
            end
        end


        % get target data
        thisTarget = targetEvents{targ};
        dataLen = length(thisTarget);
                    
        %store the number of reference events events (per person)
        indivTotalRefEvents(targ) = length(refFrames);
        
        % Loop through reference frames in the reference set
        tempPSTHCount = zeros(1, windowSize);
        tempRefFrameCount = zeros(1, windowSize);
        
        refFrameCount = 0; %counter - how many reference frames were used
        for r = 1:length(refFrames)

            
            % Define target window around timeZero.
            timeZero = refFrames(r);
            TS = max(sampleStart, (timeZero-lagSize(1)));
            TE = min(dataLen, (timeZero+lagSize(2)));
            target = thisTarget(TS:TE);

            % If there is not enough included data, continue
            if sum(~isnan(target)) < inclThresh*windowSize
                continue
            end
            
            %Pad, if necessary, with 0s.
            leftFill = []; rightFill = [];
            if (timeZero - lagSize(1)) < sampleStart
                leftFill = zeros(1, sampleStart - (timeZero-lagSize(1)));
            end
            if (timeZero + lagSize(2)) > dataLen
                rightFill = zeros(1,(timeZero+lagSize(2))-dataLen);
            end
            target = [leftFill, target, rightFill];
            
            % Advance padding counters
            % (only if you're not doing permutation testing)
            if ~PERMFLAG
                if ~isempty(leftFill) && ~isempty(rightFill) %both
                    nTargetPadding(targ, 3) = nTargetPadding(targ, 3) + 1;
                elseif ~isempty(leftFill) %just left
                    nTargetPadding(targ, 1) = nTargetPadding(targ, 1) + 1;
                elseif ~isempty(rightFill) %just right
                    nTargetPadding(targ, 2) = nTargetPadding(targ, 2) + 1;
                end
            end

            % Number of reference frames with sufficient included data
            refFrameCount = refFrameCount + 1;
            
            % Tally the number of blinks per bin (tempPSTHCount), and the
            % number of reference events that contributed included data
            % (e.g. non-NaN) to each bin (tempRefFrameCount)
            % (this is a somewhat significant change to the way it was
            % calculated prior to July 2015)
            tempPSTHCount = nansum([tempPSTHCount;target], 1);
            tempRefFrameCount = tempRefFrameCount + ~isnan(target); 
        end
        
        % Average across number of reference events and store this
        % individual's PSTH
        if refFrameCount > 0
            indivPSTH(targ,:) = tempPSTHCount ./ tempRefFrameCount;

            % # reference events used (i.e. # with enough included frames)
            indivUsedRefEvents(targ) = refFrameCount;
            
        end
        
    end %end of target loop

    % If none of the reference sets had events
    if nRefSetsNoEvents == numRefSets
        error('No reference events.');
    end
    
    % Average PSTH across all target group participants. 
    overallPSTH = nanmean(indivPSTH,1);

    %% results struct
    if PERMFLAG %if permutation testing, only output the psth
        groupPSTH = overallPSTH;
        indivPSTH = [];
    else
        %Group PSTH
        groupPSTH = struct();
        groupPSTH.time = sampleOffset;
        groupPSTH.meanBlinkCount = overallPSTH; % results.psth
        
        %Individual PSTH
        indivPSTH = struct();
        indivPSTH.time = sampleOffset;
        indivPSTH.meanBlinkCount = indivPSTH; 
        indivPSTH.numRefEventsDefined = indivTotalRefEvents; %TODO fix this name
        indivPSTH.numRefEventsIncl = indivUsedRefEvents; 
        indivPSTH.numTargetEventsDefined = cellfun(@nansum,targetEvents); %TODO fix this name
        indivPSTH.numPadBefore = nTargetPadding(:,1);
        indivPSTH.numPadAfter = nTargetPadding(:,2);
        indivPSTH.numPadBoth = nTargetPadding(:,3);
        
    end
end
