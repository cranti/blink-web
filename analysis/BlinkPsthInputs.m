classdef BlinkPsthInputs < handle
%BLINKPSTHINPUTS Inputs for blinkPsth.m (used in blinkGUI.m)
%
% See also: BLINKGUIDATA BLINKGUI

% Very little error checking
   
    properties
        
        %% General Settings
        startFrame = 1;
        
        %% Target Events
        targetEvents = {}; % Target event sets
        targetOrder = []; %maps target IDs to order of items in targetEvents
        
        targetCode = []; %value used to identify occurrence of target
        targetEventType = ''; %allFrames, firstFrameOnly, etc
        
        targetFilename = ''; %loaded file
        
        %% Reference Events
        refEvents = {}; % Reference event sets
        refOrder = []; %maps reference IDs to order of items in refEvents
        refLens = []; %samples in original reference sets (used for error checking)
        
        refCode = []; %value used to identify occurrence of reference 
        refEventType = ''; %allFrames, firstFrameOnly, etc
        
        refFilename = ''; %loaded file
        
        %% Plotting
        
        % Title text
        targetTitle = ''; 
        refTitle = '';
        
        % Sort order (original, ascend, descend)
        plotSort = 'original'; 
    end
    
    methods
        function set.startFrame(obj, value)
            if ~isnumeric(value) || ~isscalar(value) || value < 0
                error('Start frame must be a positive number');
            end
            obj.startFrame = value;
        end
    end
    
end