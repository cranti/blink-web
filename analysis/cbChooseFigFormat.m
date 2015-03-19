% Callback function for blinkGUI.m
% Choose figure format from dropdown menu
%
% gd is an instance of BlinkGuiData


function cbChooseFigFormat(hObj, ~, gd)
    %'jpg|pdf|eps|fig|png|tif'
    
    switch get(hObj, 'Value')
        case 1
            figf = 'jpg';
        case 2 
            figf = 'pdf';
        case 3
            figf = 'eps';
        case 4
            figf = 'fig';
        case 5
            figf = 'png';
        case 6
            figf = 'tif';
        otherwise
            figf = [];
    end
    
    %save fig format in guidata
    gd.output.figFormat = figf;
end