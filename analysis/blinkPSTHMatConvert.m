function results = blinkPSTHMatConvert(results, otherInputSpecs)
% Make a few changes to the struct returned by blinkPerm, in preparation
% for saving out from blinkGUI
%
% See also: BLINKPSTH, BLINKGUI

% 7.7.2015

%TODO - transpose things?

%Add to input specs
results.indivPSTH.targetSetID = otherInputSpecs.targetOrder; %results.inputs.targetOrder 
results.indivPSTH.refSetID = otherInputSpecs.refOrder; %results.inputs.refOrder

%Add to target events
results.targetEvents.filename = otherInputSpecs.targetFilename; %results.inputs.targetFilename
results.targetEvents.eventType = otherInputSpecs.targetEventType; %results.inputs.targetEventType
results.targetEvents.eventCode = otherInputSpecs.targetCode; %results.inputs.targetEventCode

%Add to reference events
results.refEvents.filename = otherInputSpecs.refFilename; %results.inputs.refFilename
results.refEvents.eventType = otherInputSpecs.refEventType; %results.inputs.refEventType
results.refEvents.eventCode = otherInputSpecs.refCode; %results.inputs.refCode


end