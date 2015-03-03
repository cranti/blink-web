function refEvents = getRefEvents(eventData, eventCode, eventType, startFrame)
%GETREFEVENTS
% Output cell of reference frame sets - each set (row in eventData) turns into 
% a logical vector (in it's own cell entry)
%
% TODO - document, check
% TODO - combine this with textread?
%
% INPUTS:
%   eventData       Cell with one entry per individual. Each individual can 
%                   have different lengths of data TODO finish me
%   eventCode       (opt) Value that indicates the occurrence of a target event. If 
%                   unspecified, the event data is left unchanged TODO finish me
%   eventType       (opt) 'allFrames', 'firstFrameOnly', 'lastFrameOnly', or
%                   'middleFrameOnly'. If unspecified, defaults to 'allFrames'
%   startFrame      TODO
%
% OUTPUTS:
%   refEvents       TODO

% Written by Carolyn Ranti
% 2.27.15

numRefSets = length(eventData);

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
        temp = diff([0,(thisData == eventCode)]);
        refFrames = find(temp==-1);
    elseif strcmpi(eventType, 'middleFrameOnly')
        warning('TODO - write me') %bwlabel or bwlabeln?
    else 
        error('Error in getRefEvents: unrecognized eventType')
    end
    
    %start 
    refFrames = refFrames(refFrames >= startFrame);

    %store reference events in a cell
    refEvents{ii} = refFrames; 
end