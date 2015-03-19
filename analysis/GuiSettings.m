classdef GuiSettings < handle
%GUISETTINGS General settings for blinkGUI.m
%
% See also: BLINKGUIDATA BLINKGUI

% Very little error checking
    
    properties
        maxPerms;
        error_log;
    end
        
    
    methods
        
        %constructor
        function obj = GuiSettings(obj)
            obj.maxPerms = 10000;
            obj.error_log = '/Users/etl/Desktop/GitCode/blink-web/analysis/testing/blinkGUI_log.txt';
        end
        
        function obj = set.maxPerms(obj, value)
            if ~isnumeric(value) || ~isscalar(value) || value < 0
                error('Maximum permutations must be a positive number');
            end
            obj.maxPerms = value;
        end
    end
    
end