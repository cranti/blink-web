function [psthEvents, setOrder] = readInPsthEvents(filename, formatType, sampleLen)
%READINPSTHEVENTS Read in a csv w/ target or reference events for blinkPSTH
% 
% USAGE
%   readInPsthEvents(filename) - read in filename w/ SetPerCol formatType.
%
%   readInPsthEvents(filename, 'SetPerCol') - read in a filename with 
%       SetPerCol formatType.
%
%   readInPsthEvents(filename, '3col', sampleLen) - read in a filename with
%       3col format, and number of samples collected = sampleLen
%
% INPUTS
%   filename    Name of a csv file containing numeric PSTH data (reference
%               or target events).
%   formatType  'SetPerCol' or '3col'. See below for details. This is
%               optional (default is 'SetPerCol').
%   sampleLen   Required if formatType is '3col'. 
%   
% OUTPUT
%   psthEvents  Cell vector. Each entry is a numeric row vector 
%               corresponding to a set of events in the input file. If it's
%               in 3 column format, 1 indicates the occurrence of an event.
%               Otherwise, the values are unchanged from the input file.
% 	setOrder 	order of targets/references. This is most relevant if the 
%               data is in the 3 column format, with identifiers in the 1st
%               column. Sets are sorted by ID number (ascending).
%
% --- Details on formatType options ---
% 'SetPerCol'
%   One set of PSTH data (references or targets) per column, with a frame 
%   per row. PSTH data must be numeric (numbers or NaNs). Event sets do not
%   need to be the same length, but they must not have any missing data. In
%   otherwords, if a column is missing an entry in a particular row, it
%   cannot contain any data in subsequent rows.
%   Note: if there is a character anywhere in the dataset, the script will
%   NOT error out, but it will abort read-in, so the length of the sets
%   will be off. 
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
%
% See also: GETTARGETEVENTS GETREFEVENTS

% Written by Carolyn Ranti
% 6.5.2015 - Overhauled, significant speed up


if nargin == 1
    formatType = 'SetPerCol';
end

switch lower(formatType)
    case 'setpercol'
        if nargin == 3
            error('sampleLen should not be specified for SetPerCol format');
        end
    case '3col'
        narginchk(3, 3);  
    otherwise
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
        [psthEvents, setOrder] = blink3ColConvert(events3col, sampleLen, 1); %last parameter: read in as cell
        
        %Reorder the data: sort the set identifiers (setOrder), and use
        %that order to sort psthEvents
        [setOrder, I] = sort(setOrder);
        psthEvents = psthEvents(I);
        
    catch ME
        err = MException('BlinkGUI:fileIn',sprintf('Error converting 3 column formatted file %s',filename));
        err = addCause(err,ME);
        throw(err);
    end
    
    return
end


%% Read in SetPerCol file - each column contains a set of PSTH data
try 
    fid = fopen(filename);
    
    %read in the first line to determine # sets and make format string
    firstLine = fgetl(fid);
    c = strsplit(firstLine, ',', 'CollapseDelimiters', false);
    numSets = length(c);
    fStr = repmat('%f ',1,numSets);

    %rewind and read all, filling empty spaces with Inf
    frewind(fid);
    allData = textscan(fid, fStr, 'Delimiter', ',' ,'EmptyValue', Inf, 'CollectOutput', 1);
    fclose(fid);
    
    %pull matrix out of nesting 
    allData = allData{1};
    
catch ME
    fclose(fid);
    err = MException('BlinkGUI:fileIn', sprintf('Error reading in file %s',filename));
    err = addCause(err, ME);
    throw(err);
end

%Convert the data
try
    
    %go column by column and add to psthEvents
    psthEvents = {};
    for s = 1:numSets

        %Pull one column out
        thisSet = allData(:,s)';

        %make sure all inf are at the end
        infI = find(isinf(thisSet));
        infI(end+1) = length(thisSet)+1;
        infCheck = diff(infI);

        if any(infCheck>1)
            error('Missing a value in column %i, file %s',s,filename);
        end

        %remove the infs and add this set to psthEvents
        lastInc = min(infI)-1;
        psthEvents{s} = thisSet(1:lastInc);
        
    end
    
    %% create setOrder variable for output
    setOrder = 1:numSets;
   
catch ME
    if strcmpi(ME.identifier, 'BlinkGUI:internal')
        err = ME;
    else
        err = MException('BlinkGUI:fileIn', sprintf('Error converting file %s',filename));
        err = addCause(err, ME);
    end
    throw(err);
end