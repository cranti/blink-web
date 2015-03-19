classdef BlinkGuiData < handle
%BLINKGUIDATA Container class for various settings in blink GUI
%
% See also: BLINKGUI

% Very little error checking
   
    properties 
        guiSettings; %settings
        output; %from output panel
        blinkPermInputs; %for blinkPerm
        blinkPsthInputs; %for blinkPSTH
    end
    
    properties (SetAccess = private)
        handles; %handles to all items in the GUI -- set via a method
    end
    
    methods
        
        % constructor
        function obj = BlinkGuiData()
            obj.guiSettings = GuiSettings; %settings
            obj.output = GuiOutputs; %from output panel
            obj.blinkPermInputs = BlinkPermInputs; % for blinkPerm
            obj.blinkPsthInputs = BlinkPsthInputs; % for blinkPSTH
        end
        
        % reset blink perm stuff
        function obj = resetPerm(obj)
           obj.blinkPermInputs = BlinkPermInputs;
        end
        
        % reset blink psth stuff
        function obj = resetPsth(obj)
            obj.blinkPsthInputs = BlinkPsthInputs;
        end
        
        %% Verify GUI settings
        function set.guiSettings(obj, value)
            if isa(value, 'GuiSettings')
                obj.guiSettings = value;
            else
                error('Invalid class for "guiSettings" property');
            end
        end
        
        function set.output(obj, value)
            if isa(value, 'GuiOutputs')
                obj.output = value;
            else
                error('Invalid class for "output" property');
            end
        end
        
        function set.blinkPermInputs(obj, value)
            if isa(value, 'BlinkPermInputs')
                obj.blinkPermInputs = value;
            else
                error('Invalid class for "blinkPermInputs" property');
            end
        end
        
        function set.blinkPsthInputs(obj, value)
            if isa(value, 'BlinkPsthInputs')
                obj.blinkPsthInputs = value;
            else
                error('Invalid class for "blinkPsthInputs" property');
            end
        end
        
        %% Handles object
        %create handles object, given the handle to a parent figure
        function setHandles(obj, guiHandle)
            obj.handles = guihandles(guiHandle);
            obj.handles.hWaitBar = [];
        end
        
        %Add a wait bar to handles
        function setWaitBar(obj, waitBar)
            obj.handles.hWaitBar = waitBar; 
        end

    end
    
end