classdef BlinkGuiData < handle
%BLINKGUIDATA Container class for various settings in blink GUI
%
% See also: BLINKGUI

% Very little error checking
   
    properties 
        guiSettings; %= GuiSettings; %settings
        output; %= GuiOutputs; %from output panel
        blinkPermInputs; %= BlinkPermInputs; % for blinkPerm
        blinkPsthInputs; %= BlinkPsthInputs; % for blinkPSTH
    end
    
    properties (SetAccess = private)
        handles; %handles to all items in the GUI -- set via a method
    end
    
    methods
        
        %constructor
        function obj = BlinkGuiData()
            obj.guiSettings = GuiSettings; %settings
            obj.output = GuiOutputs; %from output panel
            obj.blinkPermInputs = BlinkPermInputs; % for blinkPerm
            obj.blinkPsthInputs = BlinkPsthInputs; % for blinkPSTH
        end
        
        
        %Verify GUI settings
        function obj = set.guiSettings(obj, value)
            if isa(value, 'GuiSettings')
                obj.guiSettings = value;
            else
                error('Invalid class for "guiSettings" property');
            end
        end
        
        function obj = set.output(obj, value)
            if isa(value, 'GuiOutputs')
                obj.output = value;
            else
                error('Invalid class for "output" property');
            end
        end
        
        function obj = set.blinkPermInputs(obj, value)
            if isa(value, 'BlinkPermInputs')
                obj.blinkPermInputs = value;
            else
                error('Invalid class for "blinkPermInputs" property');
            end
        end
        
        function obj = set.blinkPsthInputs(obj, value)
            if isa(value, 'BlinkPsthInputs')
                obj.blinkPsthInputs = value;
            else
                error('Invalid class for "blinkPsthInputs" property');
            end
        end
        
        %create handles object
        function obj = setHandles(obj, guiHandle)
            obj.handles = guihandles(guiHandle);
            obj.handles.hWaitBar = [];
        end
        
        %Add a wait bar to handles
        function obj = setWaitBar(obj, waitBar)
            obj.handles.hWaitBar = waitBar; 
        end

    end
    
end