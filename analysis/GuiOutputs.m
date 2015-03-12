classdef GuiOutputs < handle
%GUIOUTPUTS Output settings for blinkGUI.m
%
% See also: BLINKGUIDATA BLINKGUI

% Very little error checking

    properties
        dir = '';
        saveCsv = 1;
        saveMat = 1;
        saveFigs = 1;
        figFormat;% = 'jpg'; 
    end
    
    methods
        function obj = set.figFormat(obj, value)
           if ~(strcmpi(value,'jpg') ||...
                   strcmpi(value,'pdf') || ...
                   strcmpi(value,'eps') || ...
                   strcmpi(value,'fig') || ...
                   strcmpi(value,'png') || ...
                   strcmpi(value,'tif') || ...
                   strcmpi(value,'bmp') ||...
                   strcmpi(value, ''))
               error('Fig format must be empty or one of the following: jpg, pdf, eps, fig, png, tif, bmp')
           end
           obj.figFormat = value;
        end
    end
    
end