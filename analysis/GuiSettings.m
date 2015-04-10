classdef GuiSettings < handle
%GUISETTINGS General settings for blinkGUI.m
%
% See also: BLINKGUIDATA BLINKGUI

    
    properties
        maxPerms;
        error_log;
    end
        
    
    methods
        
        %constructor
        function obj = GuiSettings()
            obj.maxPerms = 10000;
            obj.error_log = sprintf('files/%s_BlinkAnalysesLOG.txt',datestr(now,'yyyy-mm'));
            
            %TODO - read in preferences file OR defaults if it doesn't
            %exist
            
        end
        
        function set.maxPerms(obj, value)
            if ~isnumeric(value) || ~isscalar(value) || value < 0
                error('Maximum permutations must be a positive number');
            end
            obj.maxPerms = value;
        end
    end
    
end