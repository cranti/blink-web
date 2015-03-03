function targetEvents = getTargetEvents(eventData, eventCode, eventType)
%GETTARGETEVENTS
% 
% TODO - document, check, update blinkPSTH to also use cell
% TODO - combine this with textread?
% 
% INPUTS:
%   eventData       Cell with one entry per individual. Each individual can 
%                   have different lengths of data TODO finish me
%   eventCode       (opt) Value that indicates the occurrence of a target event. If 
%                   unspecified, the event data is left unchanged TODO finish me
%   eventType       (opt) 'allFrames', 'firstFrameOnly', 'lastFrameOnly', or
%                   'middleFrameOnly'. If unspecified, defaults to 'allFrames'
%
% OUTPUTS:
%   targetEvents    TODO

% Written by Carolyn Ranti
% 2.27.15

numIndivs = length(eventData);

% if there is no target code, keep data the same (continuous measure)
if nargin == 1
    targetEvents = eventData;

%otherwise, create a cell with 1 = target event, 0 = no target, NaNs preserved
else
    %default for eventType is allFrames
    if nargin == 2 || isempty(eventType)
        eventType = 'allFrames';
    end

    targetEvents = cell(1,numIndivs);

    for ii = 1:numIndivs

        thisData = eventData{ii};
        theseNans = isnan(thisData);

        if strcmpi(eventType, 'allFrames')
            thisTarget = (thisData == eventCode);
        elseif strcmpi(eventType, 'firstFrameOnly')
            temp = diff([0, thisData == eventCode]); 
            thisTarget = (temp==1);
        elseif strcmpi(eventType, 'lastFrameOnly')
            temp = diff([0,(thisData == eventCode)]);
            refFrames = find(temp==-1);
        elseif strcmpi(eventType, 'middleFrameOnly')
            warning('TODO - write me') %bwlabel or bwlabeln?
        else 
            error('Error in getTargetEvents: unrecognized eventType')
        end

        %put nans back in
        thisTarget(theseNans) = NaN;
        targetEvents{ii} = thisTarget;
    end
end