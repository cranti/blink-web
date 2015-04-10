classdef BlinkPermInputs < handle
%BLINKPERMINPUTS Inputs for blinkPerm.m (used in blinkGUI.m)
%
% See also: BLINKGUIDATA BLINKGUI

% Very little error checking
    
   properties 
        rawBlinks = [];
        sampleRate = [];
        smoothType = 'sskernel';
        
        plotTitle = {};
        filename = '';
   end
   
   methods
        function set.sampleRate(obj, value)
            if ~isnumeric(value) || ~isscalar(value) || value < 0
                error('Sample rate must be a positive number');
            end
            obj.sampleRate = value;
        end
        
        function set.smoothType(obj, value)
            if ~(strcmpi(value,'sskernel'))
               error('Smooth type must be sskernel'); 
            end
            obj.smoothType = value;
        end
    end
   
end