function targetEvents = getTargetEvents(eventData, eventCode, eventType)
%GETTARGETEVENTS 
% Output cell with target events. Each entry contains target data
% corresponding to an entry in original eventData. If eventCode is not 
% empty, targetEvents contain (essentially) binary vectors indicating the
% occurrence of eventCode in the original data (with NaNs preserved). If
% eventCode is empty, targetEvents = eventData.
% 
% 
% TODO - document, check
% 
% INPUTS:
%   eventData       Cell with one entry per individual. Each individual can 
%                   have different lengths of data. This can be continuous
%                   or categorical data. NaNs indicate samples with lost or
%                   unusable data (see blinkPSTH parameter 'inclThresh'
%   eventCode       (opt) Value that indicates the occurrence of a reference 
%                   event. If unspecified, the event data is left unchanged
%                   (i.e. if you want to create a PSTH with continuous
%                   target data).
%   eventType       (opt) 'allSamples', 'firstSampleOnly', 'lastSampleOnly',
%                   or 'middleSampleOnly'. Default is 'allSamples'. 
%
% OUTPUTS:
%   targetEvents    Cell with one entry per individual. If eventCode has
%                   been specified, each entry is a vector of 1s
%                   (indicating reference event), 0s (indicating no target),
%                   and NaNs (indicating lost or unusable data, preserved
%                   from the original input)
%
% See also: READINPSTHEVENTS, BLINKPSTH

% Written by Carolyn Ranti
% 3.11.15

numIndivs = length(eventData);

% if there is no target code, keep data the same (continuous measure)
if nargin < 2 || isempty(eventCode)
    targetEvents = eventData;
    return 
end

%otherwise, create a cell with 1 = target event, 0 = no target, NaNs preserved

%default for eventType is allSamples
if nargin < 3 || isempty(eventType)
    eventType = 'allSamples';
end

targetEvents = cell(1,numIndivs);

for ii = 1:numIndivs

    thisData = eventData{ii};
    theseNans = isnan(thisData);

    if strcmpi(eventType, 'allSamples')
        thisTarget = (thisData == eventCode);
    elseif strcmpi(eventType, 'firstSampleOnly')
        temp = diff([0, thisData == eventCode]); 
        thisTarget = (temp==1);
    elseif strcmpi(eventType, 'lastSampleOnly')
        temp = diff([(thisData == eventCode), 0]);
        thisTarget = (temp==-1);
    elseif strcmpi(eventType, 'middleSampleOnly')
        %find first and last samples
        temp = diff([0,(thisData == eventCode)]);
        firstSamples = find(temp==1);
        temp = diff([(thisData == eventCode), 0]);
        lastSamples = find(temp==-1);
        
        %sanity check - make sure that there are the same number of first
        %and last samples (this should never be false...)
        assert(length(firstSamples) == length(lastSamples), 'Error calculating middle sample');
        
        %round the average of first and last samples for each blink to get
        %the middle sample
        numEvents = length(firstSamples);
        targInds = zeros(1,numEvents);
        for r = 1:numEvents
            targInds(r) = round(mean([firstSamples(r),lastSamples(r)]));
        end
        thisTarget = zeros(size(thisData));
        thisTarget(targInds) = 1;
    else 
        error('Error in getTargetEvents: unrecognized eventType')
    end

    %put nans back in
    thisTarget = thisTarget*1;
    thisTarget(theseNans) = NaN;
    
    %make it a row vector
    if ~isrow(thisTarget)
        thisTarget = thisTarget';
    end
    
    targetEvents{ii} = thisTarget;
end
