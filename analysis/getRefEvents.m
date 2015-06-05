function [refEvents, refSetLen] = getRefEvents(eventData, eventCode, eventType, sampleStart)
%GETREFEVENTS
% Output cell of reference sets. Each entry contains indices of reference
% events (i.e. the occurrence of eventCode in original eventData)
%
%
% TODO - document, check
%
% INPUTS:
%   eventData       Cell with one entry per set of reference data.
%   eventCode       Value that indicates the occurrence of a reference 
%                   event. 
%   eventType       (opt) 'allSamples', 'firstSampleOnly', 'lastSampleOnly',
%                   or 'middleSampleOnly'. Default is 'allSamples'. 
%   sampleStart     First sample to start including reference events (e.g. 
%                   if you want to avoid an artifact from the beginning
%                   of a movie). Default is 1.
%
% OUTPUTS:
%   refEvents       Cell with one entry per reference set, containing the 
%                   the indices of the reference events.
%   refSetLen       Length of each original reference set.
%
% See also: READINPSTHEVENTS, BLINKPSTH

% Written by Carolyn Ranti
% 3.11.15


numRefSets = length(eventData);
refSetLen = cellfun(@length, eventData);

%default eventType is 'allSamples'
if nargin < 3 || isempty(eventType)
    eventType = 'allSamples';
end

% default sampleStart = 1
if nargin < 4 || isempty(sampleStart)
    sampleStart = 1;
end

refEvents = cell(1,numRefSets); 

for ii = 1:numRefSets
    
    thisData = eventData{ii};

    if strcmpi(eventType,'allSamples')
        refFrames = find(thisData == eventCode); 
    elseif strcmpi(eventType,'firstSampleOnly')
        temp = diff([0,(thisData == eventCode)]);
        refFrames = find(temp==1);
    elseif strcmpi(eventType, 'lastSampleOnly')
        temp = diff([(thisData == eventCode), 0]);
        refFrames = find(temp==-1);
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
        refFrames = zeros(1,numEvents);
        for r = 1:numEvents
            refFrames(r) = round(mean([firstSamples(r),lastSamples(r)]));
        end

    else 
        error('Error in getRefEvents: unrecognized eventType')
    end
    
    %start after sampleStart 
    refFrames = refFrames(refFrames >= sampleStart);

    %store reference events in a cell
    refEvents{ii} = refFrames; 
end