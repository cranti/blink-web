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
%                   or categorical data. NaNs indicate frames with lost or
%                   unusable data (see blinkPSTH parameter 'inclThresh'
%   eventCode       (opt) Value that indicates the occurrence of a reference 
%                   event. If unspecified, the event data is left unchanged
%                   (i.e. if you want to create a PSTH with continuous
%                   target data).
%   eventType       (opt) 'allFrames', 'firstFrameOnly', 'lastFrameOnly',
%                   or 'middleFrameOnly'. Default is 'allFrames'. 
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

%default for eventType is allFrames
if nargin < 3 || isempty(eventType)
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
        temp = diff([(thisData == eventCode), 0]);
        thisTarget = (temp==-1);
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
        targInds = zeros(1,numEvents);
        for r = 1:numEvents
            targInds(r) = round(mean([firstFrames(r),lastFrames(r)]));
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
