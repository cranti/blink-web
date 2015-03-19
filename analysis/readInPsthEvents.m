function [psthEvents, subjOrder] = readInPsthEvents(filename, formatType, varargin)
%READINREFEVENTS Read in a csv w/ target or reference events for blinkPSTH
% 
% USAGE
%   readInPsthEvents(filename) - read in filename w/ SetPerCol formatType.
%
%   readInPsthEvents(filename, 'SetPerCol', [hWaitBar])
%
%   readInPsthEvents(filename, '3col', sampleLen)
%
% INPUTS
%   filename    Name of a csv file containing numeric PSTH data (reference
%               or target events).
%   formatType  'SetPerCol' or '3col'. See below for details. This is
%               optional (default is 'SetPerCol').
%   sampleLen   Required if formatType is '3col'. If the file is huge, this
%               is advised so that preallocation can happen.
%   hWaitBar    Optional - handle to a wait dialog box with a cancel 
%               button. This gives the user the opportunity to stop reading
%               in the file in the middle. Only valid for 'SetPerCol'
%               formatted files. NOTE: If sampleLen is passed in (as a
%               positive value), this is assumed to be a waitbar.
%               Otherwise, a waitdlg. TODO - this should prob. be refined
%   
% OUTPUT
%   psthEvents  Cell vector. Each entry is a numeric row vector 
%               corresponding to a set of PSTH events in the input file.
% 	subjOrder 	order of targets/references. This is only relevant if the 
%               data is in the 3 column format, with identifiers in the 1st
%               column. Order is preserved from input.
%
% --- Details on formatType options ---
% 'SetPerCol'
%   One set of PSTH data (references or targets) per column, with a frame 
%   per row. PSTH data must be numeric (numbers or NaNs). Event sets do not
%   need to be the same length, but they must not have any missing data. In
%   otherwords, if a column is missing an entry in a particular row, it
%   cannot contain any data in subsequent rows.
%
% '3col'
%   The file must contain a matrix with 3 columns, containing only numeric
%   data, with one row per blink. In each row, the 1st column contains a
%   subject identifier (numeric value), the 2nd column contains the start
%   frame of the blink (integer value), and the 3rd column contains the end
%   frame of the blink (integer value). The number of columns in the output
%   is determined by the input variable sampleLen.
%
% ---------
% NOTE: Because the conversion process is fairly computationally demanding,
% it may take a while to read in files with many rows. 
%

% Written by Carolyn Ranti
% 3.19.2015


if nargin == 1
    formatType = 'SetPerCol';
end

if strcmpi(formatType, 'SetPerCol')
    narginchk(1,3);
    
    if nargin == 3 && ishandle(varargin{1})
        hWaitBar = varargin{1};
        haswaitdlg = 1;
    else
        haswaitdlg = 0;
    end
    
elseif strcmpi(formatType, '3col')
    narginchk(3, 3);
    sampleLen = varargin{1};
else
    error('Unknown formatType %s', formatType);
end

%% Read in 3 column file and return
if strcmpi(formatType, '3col')
    
    % read in 3 column file
    try
        events3col = csvread(filename);
    catch ME
        err = MException('BlinkGUI:fileIn',sprintf('Error reading in csv file %s',filename));
        err = addCause(err,ME);
        throw(err);
    end
    
    % convert to cell
    try
        [psthEvents, subjOrder] = blink3ColConvert(events3col, sampleLen, 1); %last parameter: read in as cell
        return
    catch ME
        err = MException('BlinkGUI:fileIn',sprintf('Error converting 3 column formatted file %s',filename));
        err = addCause(err,ME);
        throw(err);
    end
end

%% Read in matrix file - each column contains a set of PSTH data
try 
    fid = fopen(filename);
    orig = textscan(fid, '%s');
    fclose(fid);
    orig = orig{1};
catch ME
    fclose(fid);
    err = MException('BlinkGUI:fileIn', sprintf('Error reading in file %s',filename));
    err = addCause(err, ME);
    throw(err);
end

try
    %update user
    if haswaitdlg
       waitbar(0, hWaitBar, 'Converting data...');
    end
    
    %% Set up (use first line)
	c = strsplit(orig{1}, ',', 'CollapseDelimiters', false);
    
    % All PSTH sets must have an initial value
    if max(cellfun(@isempty, c))
        error('BlinkGUI:internal','All columns in PSTH file (%s) must have a value in the first row.', filename);
    end
    
    sampleLen = length(orig);
    numSets = length(c);
    
    % for output
    subjOrder = 1:numSets;
    
    %% initialize vars for loop
    
    % each row in the input file becomes a column of tempEvents
    tempEvents = nan(numSets, sampleLen);
    
    % keep track of how long each set is
    setLens = zeros(numSets, 1);
    
    %% go row by row to do conversions
    for row = 1:sampleLen
        
        %if the wait dialog is passed in, check it for cancel status
        if haswaitdlg
           if getappdata(hWaitBar,'canceling')
                psthEvents = {};
                return
           end
           waitbar(row/sampleLen, hWaitBar);
        end

        %% convert row to column of numbers, with inf denoting 
        events = textscan(orig{row},'%f',numSets,'Delimiter',',','EmptyValue',Inf);
        events = events{1}; % this is a column
        
        %pad (if needed) with inf
        paddedEvents = nan(numSets, 1);
        paddedEvents(1:length(events)) = events;

        
        %% update set lengths
        doneSets = isinf(events);
        alreadyDone = (setLens>0);
        
        % if a set was "done" in one row and in the next it's not, that
        % indicates a missing value. error out.
        if min(doneSets - alreadyDone)==-1
            col = find((doneSets - alreadyDone)==-1);
            error('BlinkGUI:internal','Missing value in row %i, col %i, file %s', row-1, col, filename);
        end

        setLens(doneSets & ~alreadyDone) = row-1;
        
        %% put into matrix (as column)
        tempEvents(:,row) = paddedEvents;

    end
    setLens(setLens==0) = row;
    
    %% convert to cell and remove the extra Infs from the end to make each set the right length
    psthEvents = num2cell(tempEvents, 2);
    
    for ii = 1:numSets
        if setLens(ii) < sampleLen
            psthEvents{ii} = psthEvents{ii}(1:setLens(ii));
        end     
    end

    % Check that there aren't any infinite values left
    for ii = 1:numSets
       if sum(isinf(psthEvents{ii}))
          error('BlinkGUI:internal','Illegal Inf value in file %s.',filename); 
       end
    end

    
catch ME
    if strcmpi(ME.identifier, 'BlinkGUI:internal')
        err = ME;
    else
        err = MException('BlinkGUI:fileIn', sprintf('Unknown error converting file %s',filename));
        err = addCause(err, ME);
    end
    throw(err);
end