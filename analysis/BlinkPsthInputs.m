classdef BlinkPsthInputs < handle
%BLINKPSTHINPUTS Inputs for blinkPsth.m (used in blinkGUI.m)
%
% See also: BLINKGUIDATA BLINKGUI

% Very little error checking
   
    properties
        targetEvents = {};
        refEvents = {};
        startFrame = 1;
        
        % target/ref event information:
        targetCode = [];
        targetEventType = '';
        targetFilename = '';
        
        refCode = [];
        refEventType = '';
        refSetLen = []; %length of original reference sets (used for error checking)
        refFilename = '';
        
        %title text for plotting
        targetTitle = ''; 
        refTitle = '';
    end
    
    methods
        function obj = set.startFrame(obj, value)
            if ~isnumeric(value) || ~isscalar(value) || value < 0
                error('Start frame must be a positive number');
            end
            obj.startFrame = value;
        end
    end
    
end