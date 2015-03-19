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
%   'refSetLen'     Numeric vector containing the original length of each 
%                   reference event set. This is a variable output by
%                   GETREFEVENTS. If this parameter is passed in, it's used
%                   for error checking only: the script verifies that the
%                   length of each of the targetEvent sets matches the
%                   length reported by 
%                   If this is passed in, it's just used for error
%                   checking: 
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
%       * If permutation testing is not run, this is an empty struct.
%       
%       inputSpecs - struct with details about the inputs provided
%           lagSize - size of the window on either side of the event
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
% 3.19.2015
% Adapted from code written by Jenn Moriuchi, Grace Ann Marrinan, and Sarah Shultz

%% Set up

assert(iscell(targetEvents), 'targetEvents must be a cell.');
assert(iscell(refEvents), 'refEvents must be a cell.');

numTargets = length(targetEvents);
numRefSets = length(refEvents);
allDataLens = cellfun(@length, targetEvents);

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
runPermTest = (nargin>=4) && (~isempty(numPerms)) && (numPerms >= 0);

%% Parse optional inputs and check
assert(mod(length(varargin),2)==0, 'Odd number of optional parameters (must be name, value pairs)');

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
       case 'refsetlen'
           refSetLen = varargin{v+1};
           if ~isnumeric(refSetLen)
               error('refSetLen must be numeric');
           end
           
           if length(refSetLen) == 1
               if ~sum(allDataLens == refSetLen)
                  error('Mismatch between length of target event sets and length of reference event set.');
               end 
           elseif length(refSetLen) == numRefSets
               if (isrow(refSetLen) && ~isrow(allDataLens)) || (~isrow(refSetLen) && isrow(allDataLens))
                   refSetLen = refSetLen';
               end
               if ~isequal(allDataLens, refSetLen)
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


%% Calculate cross-correlogram
if haswaitbar
    tstart = tic; 
    waitbar(0, hWaitBar, 'Creating PSTH...');
end

results = makePSTH(refEvents, targetEvents, lagSize, startFrame, inclThresh, 0);

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
                results = struct();
                return
            end
        end
        
        % circshift data: shift each subject independently 
        shiftSizes = round(allDataLens.*rand(1,numTargets));
        for ii = 1:numTargets
            permutedData{ii} = circshift(targetEvents{ii}, shiftSizes(ii), 2); %TODO - check this/make sure that dimensions are correct
        end
        
        permResults(p,:) = makePSTH(refEvents, permutedData, lagSize, startFrame, inclThresh, 1); 
    
        %Update progress bar
        if haswaitbar
            waitbar(double(p)/double(numPerms), hWaitBar);
        end
    
    end

    if haswaitbar
        tstart = tic;
        waitbar(0, hWaitBar,'Calculating Significance...');
    end
    
    % Add low and high percentile values to results
    results.permTest.numPerms = numPerms;
    results.permTest.lowPrctileLevel = lowPrctileLevel;
    results.permTest.highPrctileLevel = highPrctileLevel;
    results.permTest.lowPrctile = prctile(permResults, lowPrctileLevel, 1);
    results.permTest.highPrctile = prctile(permResults, highPrctileLevel, 1);
    results.permTest.mean = mean(permResults);
    
    if haswaitbar
        while toc(tstart) < .5; end 
        waitbar(1, hWaitBar);
    end
    
else
    results.permTest.numPerms = 0;
    results.permTest.lowPrctileLevel = 0;
    results.permTest.highPrctileLevel = 0;
    results.permTest.lowPrctile = [];
    results.permTest.highPrctile = [];
    results.permTest.mean = [];
end

%% Add input specs
results.inputSpecs.lagSize = lagSize;
results.inputSpecs.numTargets = numTargets;
results.inputSpecs.numRefSets = numRefSets;
results.inputSpecs.targetLens = cellfun(@length, targetEvents);
results.inputSpecs.refLens = cellfun(@length, refEvents);
results.inputSpecs.inclThresh = inclThresh;
results.inputSpecs.startFrame = startFrame;
end


%% Make a peri-stimulus time histogram
function results = makePSTH(refEvents, targetEvents, lagSize, startFrame, inclThresh, PERMFLAG)
%PERMFLAG - if 1, indicates permutation testing. Output is the overallPSTH,
%rather than the entire struct. Also, some counters are skipped

    numRefSets = length(refEvents);
    numIndivs = length(targetEvents);
    windowSize = sum(lagSize) + 1;

    % If there is only 1 ref set, it must have events in it
    if numRefSets == 1
        refFrames = refEvents{1};  
        if isempty(refFrames)
            error('No reference events.')
        end
    end

    % Set counters at 0
    nRefSetsNoEvents = 0; %number of reference sets with no events
    nTargetPadding = zeros(numIndivs,3); %leftFill, rightFill, both
    indivTotalRefEvents = zeros(numIndivs,1); %total reference events for each target
    indivUsedRefEvents = zeros(numIndivs,1); %total ref events *used* for each target

    % initialized indivPSTH with NaNs
    indivPSTH = nan(numIndivs, windowSize);

    % Loop through target group participants
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

        % Loop through reference frames in the reference set
        tempCrossCorrCounters = zeros(1, windowSize);
        refFrameCount = 0; %counter - how many reference frames were used
        for r = 1:length(refFrames)

            
            % Define target window around timeZero.
            timeZero = refFrames(r);
            TS = max(startFrame, (timeZero-lagSize(1)));
            TE = min(dataLen, (timeZero+lagSize(2)));
            target = thisTarget(TS:TE);

            % If there is not enough included data, continue
            if sum(~isnan(target)) < inclThresh*windowSize
                continue
            end
            
            %Pad, if necessary, with 0s.
            leftFill = []; rightFill = [];
            if (timeZero - lagSize(1)) < startFrame
                leftFill = zeros(1, startFrame - (timeZero-lagSize(1)));
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

            % Add hits
            refFrameCount = refFrameCount + 1;
            tempCrossCorrCounters = nansum([tempCrossCorrCounters;target], 1);
            
        end
        
        % Average across number of reference events and store this
        % individual's PSTH
        if refFrameCount > 0
            indivPSTH(targ,:) = tempCrossCorrCounters ./ refFrameCount;
        
            if ~PERMFLAG
                %store the number of reference events (per person)
                indivTotalRefEvents(targ) = length(refFrames);

                % # reference events used (i.e. # with enough included frames)
                indivUsedRefEvents(targ) = refFrameCount;
            end
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
        results = overallPSTH;
    else
        results = struct();
        results.psth = overallPSTH;
        results.indivPSTH = indivPSTH;
        results.indivTotalRefEventN = indivTotalRefEvents;
        results.indivUsedRefEventN = indivUsedRefEvents;
        results.nRefSetsNoEvents = nRefSetsNoEvents;
        results.nTargetPadding = nTargetPadding;
    end
end
