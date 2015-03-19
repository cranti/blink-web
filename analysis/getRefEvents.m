function [refEvents, refSetLen] = getRefEvents(eventData, eventCode, eventType, startFrame)
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
%   eventType       (opt) 'allFrames', 'firstFrameOnly', 'lastFrameOnly',
%                   or 'middleFrameOnly'. Default is 'allFrames'. 
%   startFrame      First frame to start including reference events (e.g. 
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

%default eventType is 'allFrames'
if nargin < 3 || isempty(eventType)
    eventType = 'allFrames';
end

% default startFrame = 1
if nargin < 4 || isempty(startFrame)
    startFrame = 1;
end

refEvents = cell(1,numRefSets); 

for ii = 1:numRefSets
    
    thisData = eventData{ii};

    if strcmpi(eventType,'allFrames')
        refFrames = find(thisData == eventCode); 
    elseif strcmpi(eventType,'firstFrameOnly')
        temp = diff([0,(thisData == eventCode)]);
        refFrames = find(temp==1);
    elseif strcmpi(eventType, 'lastFrameOnly')
        temp = diff([(thisData == eventCode), 0]);
        refFrames = find(temp==-1);
    elseif strcmpi(eventType, 'middleFrameOnly')

        %find first and last frames
        temp = diff([0,(thisData == eventCode)]);
        firstFrames = find(temp==1);
        temp = diff([(thisData == eventCode), 0]);
        lastFrames = find(temp==-1);
        
        %sanity check - make sure that there are the same number of first
        %and last frames (this should never be false...)
        assert(length(firstFrames) == length(lastFrames), 'Error calculating middle frame');
        
        %round the average of first and last frames for each blink to get
        %the middle frame
        numEvents = length(firstFrames);
        refFrames = zeros(1,numEvents);
        for r = 1:numEvents
            refFrames(r) = round(mean([firstFrames(r),lastFrames(r)]));
        end

    else 
        error('Error in getRefEvents: unrecognized eventType')
    end
    
    %start after startFrame 
    refFrames = refFrames(refFrames >= startFrame);

    %store reference events in a cell
    refEvents{ii} = refFrames; 
end