function results = blinkPermMatConvert(results, inputFile, bandWRange)
% Make a few changes to the struct returned by blinkPerm, in preparation
% for saving out from blinkGUI
%
% See also: BLINKPERM, BLINKGUI

% 6.5.2015

%add filename to inputs:
results.inputs.filename = inputFile;

% replace inputs.bandWRange - instead of a vector with the actual numbers
% that were checked, save the user-entered string from the GUI
results.inputs.bandWRange = bandWRange;

% remove inputs.smoothType from the struct
newInputs = rmfield(results.inputs, 'smoothType');
results.inputs = newInputs;


end