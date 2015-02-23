function blinkGUI()
DEV = true;

% Add inputs:
    % numPerms
    % sampleRate
    % sample length
    % advanced options: W

% > have multiple analysis types available in one GUI, and change input
%       fields according to the analysis type (uitoggletool?)
% > output useful error messages from all subfunctions
% > reset anything when new file is loaded?
% > have a window with version info, my name, website, etc.
% > help documentation --> send to website, contact info
% > uimenu, uitoolbar --> have different menus and toolbars?
% > windows path joining... will need to change some hard-coded things
% > logging: how to set a location for log file?
% > specs file? 
% > graph things within the GUI
% > have an option to NOT save anything, and just generate the figures
%   (exploratory)

% NOTE: input specs have changed slightly: subjects should each have a
% column, and frames should be in rows (better for excel limits).
    % think about excel limits when considering how much data to accept --
    % 1/2 many rows - a few, max of how many subjects?


%% Define variables accessible by nested functions:
outputDir = '';
rawBlinks = [];
results = [];

if DEV
    error_log = '/Users/etl/Desktop/GitCode/blink-web/logs/blinkGUI_log.txt';
    sampleRate = 30;
end



%% GUI

%MAIN FIGURE
%Parent figure width and height
W=610;
H=650;

hMain = figure('units','pixels',...
    'position',[100 100 W H],...
    'MenuBar', 'none',...
    'Toolbar','none',...
    'HandleVisibility','callback',...
    'numbertitle','off',...
    'name', 'Blink Analyses',...
    'Color',[215/256 230/256 230/256]);

set(hMain,'DefaultUicontrolFontName','Helvetica',...
    'DefaultUicontrolFontSize',15,...
    'DefaultUicontrolFontUnits','pixels')


%LOAD BLINK CSV
%Button that brings up menu to select a file
hLoadBlinkFile = uicontrol(hMain,'Style','pushbutton',...
    'String','Load Blink csv',...
    'Units','normalized',...
    'Position',[10/W 610/H 150/W 30/H],...
    'UserData',0,... %indicates whether file has been loaded
    'Callback',@LoadBlinks);

%Displays the name of the file that has been loaded
hListBlinkFile = uicontrol(hMain,'Style','text',...
    'Units','normalized',...
    'Position',[180/W 610/H 200/W 30/H],...
    'String','Blink Input File',...
    'FontAngle','italic');

%CHOOSE WHERE TO SAVE RESULTS FILES
%Output directory
hChooseOutputDir = uicontrol(hMain,'Style','pushbutton',...
    'String','Choose output directory',...
    'Units','normalized',...
    'Position',[10/W 565/H 150/W 30/H],...
    'UserData',0,... %indicates whether dir has been selected
    'Callback',@ChooseOutputDir);

%Editable text box where output filename is entered
hListOutputFile = uicontrol(hMain,'Style','text',...
    'Units','normalized',...
    'Position',[180/W 565/H 200/W 30/H],...
    'String','Output Directory',...
    'FontAngle','italic');


%TYPE NAME OF OUTPUT FILE
%Label for edit box where output filename can be entered
hOutputFileLabel = uicontrol(hMain,'Style','text',...
    'Units','normalized',...
    'Position',[10/W 520/H 150/W 30/H],...
    'FontWeight','bold',...
    'String','Enter name for output file:',...
    'BackgroundColor',[215/256 230/256 230/256]);

%Editable text box where output filename is entered
hOutputFile = uicontrol(hMain,'Style','edit',...
    'Units','normalized',...
    'Position',[180/W 520/H 200/W 30/H]);


% NUMBER OF PERMUTATIONS
% Label
hNumPermsLabel = uicontrol(hMain,'Style','text',...
    'Units','normalized',...
    'Position',[10/W 475/H 175/W 30/H],...
    'FontWeight','bold',...
    'String','Number of permutations:',...
    'BackgroundColor',[215/256 230/256 230/256]);

% Editable text box where number of permutations is entered
hNumPerms = uicontrol(hMain,'Style','edit',...
    'Units','normalized',...
    'Position',[180/W 475/H 200/W 30/H]);


%TODO - label and text box for sample rate
% sampleRate = 15;


%Axes to plot selected data
hPlotAxes = axes('Parent',hMain, ...
                'Units', 'normalized', ...
                'HandleVisibility','callback', ...
                'Position',[25/W 250/H 550/W 200/H]);

%Button to run the analysis
%ANALYZE BUTTON
GoButton = uicontrol(hMain,'Style','pushbutton',...
    'String','Blink Mod',...
    'FontWeight','bold',...
    'BackgroundColor',[.6 .95 .6],...
    'Units','normalized',...
    'Position',[375/W 15/H 100/W 30/H],...
    'FontSize',16,...
    'Callback',@RunBlinkPerm);


%% Utility functions

    %join a directory and a filename -- TODO look into how other systems
    %define pathnames.
    function fullpath = dirFileJoin(dirname, filename)
        if strcmp(dirname(end),'/')
            fullpath = [dirname,filename];
        else
            fullpath = [dirname,'/',filename];
        end
    end

    %create an error dialogue window, and log the error if there is an
    %error log file
    function gui_error(error_msg, fxn, moreinfo)
        errordlg(error_msg);
        
        fid = fopen(error_log,'a');
        if fid>0
            fprintf(fid,'%s\t',datestr(now));
            fprintf(fid,'Function: %s\t',fxn);
            fprintf(fid,'%s',error_msg);
            if nargin==3
                fprintf(fid,'\t%s',moreinfo);
            end
            fprintf(fid,'\n\n');
            fclose(fid);
        end
    end

%% Callback functions

    %read in input file
    function LoadBlinks(varargin)
        [input_file, PathName] = uigetfile('*.csv','Choose a csv file with blink data');
        
        input_file_full = dirFileJoin(PathName, input_file);
        
        %TODO - before loading the file, ask the user about the format of the
        %data...If the format is 3 column, ask them to enter sample length. Pop
        %up windows?
        formatType = 'BinaryMat';
        if strcmpi(formatType,'3col')
            sampleLen = 100; 
        else
            sampleLen = NaN;
        end
        
        if input_file ~= 0
            [rawBlinks, error_msg] = readInBlinks(input_file_full,formatType,sampleLen);
            
            if error_msg
                gui_error(error_msg,'readInBlinks')
            else
                set(hListBlinkFile,'String',input_file,'Value',1,'FontAngle','normal');
                       
                %Plot instantaneous blink rate
                cla(hPlotAxes,'reset');
                plotInstBR(rawBlinks, sampleRate, hPlotAxes);
            end
        end
    end

    %choose output directory
    function ChooseOutputDir(varargin)
        outputDir = uigetdir('','Choose a folder where results will be saved');
        if outputDir ~= 0
            set(hListOutputFile,'String',outputDir,'Value',1,'FontAngle','normal');
        end
    end

    % Run BlinkMod analysis (blinkPerm.m), create/save figures and summary csv file
    function RunBlinkPerm(varargin)
        
        errordlg_msg = {};
        if isempty(rawBlinks)
            errordlg_msg{end+1} = '  No data was loaded.';
        end
        
        %get number of permutations and check it
        numPerms = get(hNumPerms,'String');
        
        if isempty(numPerms)
            errordlg_msg{end+1} = '  Number of permutations was not specified.';
        elseif isempty(str2double(numPerms)) %returns [] if not a valid number
            errordlg_msg{end+1} = '  Number of permutations must be a number';
        else
            numPerms = int8(str2double(numPerms));
        end
        
        %get sample rate and check it
%         sampleRate = get(hSampleRate,'String');
        if isempty(sampleRate)
            errordlg_msg{end+1} = '  Sample rate of the data was not specified.';
        end
        
        
        if isempty(outputDir)
            errordlg_msg{end+1} = '  Folder to save results was not specified.';
        end
        
        
        if ~isempty(errordlg_msg)
            errordlg(errordlg_msg);
        else
            
            %get summary filename
            summary_file = get(hOutputFile,'String');
        
            if isempty(summary_file)
               warndlg('You did not specify a name for the summary file -- results will be saved in the output directory in summary.csv');
               summary_file = 'summary.csv';
               set(hOutputFile,'String',summary_file);
            end
            
            % run the analysis
            [results, error_msg] = blinkPerm(numPerms, rawBlinks, sampleRate);
            if error_msg
                gui_error(error_msg,'blinkPerm')
            end
            
            % create figures
            %TODO!
            cla(hPlotAxes,'reset');
            error_msg = blinkPermFigures(outputDir, results, [hPlotAxes,NaN,NaN]);
            if error_msg
                gui_error(error_msg,'blinkPermFigures')
            end
            
            
            % if the summary file name isn't csv, change it
            if isempty(regexp(summary_file,'.csv$'))
                temp = strsplit(summary_file,'.');
                if length(temp)==1
                    summary_file = [summary_file,'.csv'];
                else
                    summary_file = [temp{1},'.csv'];
                end
                set(hOutputFile,'String',summary_file);
            end
            % get the full path for the csv summary file
            summary_file_full = dirFileJoin(outputDir, summary_file);
            
            % output csv summary file
            error_msg = blinkPermSummary(summary_file_full, results);
            if error_msg
                gui_error(error_msg,'blinkPermSummary')
            end
        end
    end

end