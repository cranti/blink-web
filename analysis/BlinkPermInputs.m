classdef BlinkPermInputs < handle
%BLINKPERMINPUTS Inputs for blinkPerm.m (used in blinkGUI.m)
%
% See also: BLINKGUIDATA BLINKGUI

% Very little error checking
    
   properties 
        rawBlinks = [];
        sampleRate = [];
        plotTitle = {};
   end
   
   methods
        function obj = set.sampleRate(obj, value)
            if ~isnumeric(value) || ~isscalar(value) || value < 0
                error('Sample rate must be a positive number');
            end
            obj.sampleRate = value;
        end
    end
   
end