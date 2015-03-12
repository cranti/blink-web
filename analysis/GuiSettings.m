classdef GuiSettings < handle
%GUISETTINGS General settings for blinkGUI.m
%
% See also: BLINKGUIDATA BLINKGUI

% Very little error checking
    
    properties
        maxPerms = 10000;
        error_log = '/Users/etl/Desktop/GitCode/blink-web/analysis/testing/blinkGUI_log.txt';
    end
        
    
    methods
        function obj = set.maxPerms(obj, value)
            if ~isnumeric(value) || ~isscalar(value) || value < 0
                error('Maximum permutations must be a positive number');
            end
            obj.maxPerms = value;
        end
    end
    
end