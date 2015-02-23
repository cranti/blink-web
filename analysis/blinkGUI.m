function blinkGUI()
DEV = true;

% Add inputs:
    % sampleRate
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
%   (exploratory)?
% > what to do upon closing the figure? (fclose all, etc)
% > no resizing?
% > option to save the figures/remake them without rerunning the analysis


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

    %join a directory and a filename -- TODO look at how other systems
    %define pathnames.
    function fullpath = dirFileJoin(dirname, filename)
        if strcmp(dirname(end),'/')
            fullpath = [dirname,filename];
        else
            fullpath = [dirname,'/',filename];
        end
    end

    %create an error dialogue window, and log the error if there is a log file 
    function gui_error(ME)
        
        errordlg(ME.message);
        
        fid = fopen(error_log,'a');
        if fid>0
            fprintf(fid,'%s\t',datestr(now));
            fprintf(fid,'%s\n',ME.message);
            
            %PRINT THE STACK
            if ~isempty(ME.cause) %if there is a cause, print that stack
                stack = ME.cause{1}.stack;
                fprintf(fid,'Cause:\t%s\n',ME.cause{1}.message);
            else %otherwise, the stack from the exception
                stack = ME.stack;
            end
         
            for i = 1:length(stack)
                fprintf(fid, '\tLine %i\t%s\t%s\n', stack(i).line, stack(i).name, stack(i).file);
            end
            
            fprintf(fid,'\n');
            fclose(fid);
        end
    end

%% Callback functions

    %read in input file
    function LoadBlinks(varargin)
        [input_file, PathName] = uigetfile('*.csv','Choose a csv file with blink data');
        
        input_file_full = dirFileJoin(PathName, input_file);

        if input_file == 0
            return
        end
        
        % Get file type before loading file
        options = {'Binary blink matrix','BinaryMat';
                    'Three column format','3col'};
        [formatType, value] = twoRadioDlg(options);
        %if user cancels
        if value==0
            return
        end
        %formatType = 'BinaryMat';
        
        if strcmpi(formatType,'3col')
            prompt = {'Enter data length:'};
            dlg_title = '3 Column Format';
            num_lines = 1;
            answer = inputdlg(prompt,dlg_title, num_lines);
            
            
            if isempty(answer)
                return
            else
                sampleLen = str2num(answer{1});
                if sampleLen<0
                    errordlg('Data length must be greater than 0.');
                    return
                end
            end
        elseif strcmpi(formatType,'BinaryMat')
            sampleLen = NaN;
        else
            error('Unrecognized format type');
        end
        
        %try to read in file
        try
            rawBlinks = readInBlinks(input_file_full, formatType, sampleLen);
        catch ME
            gui_error(ME);
            return
        end
        
        set(hListBlinkFile,'String',input_file,'Value',1,'FontAngle','normal');
        
        %Plot instantaneous blink rate
        cla(hPlotAxes,'reset');
        plotInstBR(rawBlinks, sampleRate, hPlotAxes);
        
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
            errordlg_msg{end+1} = '\tNo data was loaded.';
        end
        
        %get number of permutations and check it
        numPerms = get(hNumPerms,'String');
        
        if isempty(numPerms)
            errordlg_msg{end+1} = '\tNumber of permutations was not specified.';
        elseif isempty(str2double(numPerms)) %returns [] if not a valid number
            errordlg_msg{end+1} = '\tNumber of permutations must be a number';
        else
            numPerms = int8(str2double(numPerms));
        end
        
        %get sample rate and check it
%         sampleRate = get(hSampleRate,'String');
        if isempty(sampleRate)
            errordlg_msg{end+1} = '\tSample rate of the data was not specified.';
        end
        
        
        if isempty(outputDir)
            errordlg_msg{end+1} = '\tFolder to save results was not specified.';
        end
        
        
        if ~isempty(errordlg_msg)
            msg = strjoin(errordlg_msg,'\n');
            errordlg(sprintf(msg));
            return
        end
        
            
        %get summary filename
        summary_file = get(hOutputFile,'String');

        if isempty(summary_file)
           warndlg('You did not specify a name for the summary file -- results will be saved in the output directory in summary.csv');
           summary_file = 'summary.csv';
           set(hOutputFile,'String',summary_file);
        end


        % run the analysis
        %TODO - get Wvalue from the GUI instead of hard-coding here
        Wrange = 4;
        try
            results = blinkPerm(numPerms, rawBlinks, sampleRate, Wrange);
        catch ME
            gui_error(ME);
            return
        end

        % create figures
        %TODO - get fig format from GUI instead of hardcoding here
        figFormat = 'pdf';
        try
            blinkPermFigures(outputDir, results, figFormat); %, [ax1,ax2,ax3]);
        catch ME 
            gui_error(ME);
        end

        % summary file
        % if the summary file name isn't csv, change it
        if isempty(regexp(summary_file, '.csv$', 'once'))
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
        try
            blinkPermSummary(summary_file_full, results);
        catch ME
            gui_error(ME);
        end
        
    end

end