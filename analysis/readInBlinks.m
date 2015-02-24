function blinks = readInBlinks(filename, formatType, sampleLen)
%READINBLINKS - Read in a csv file with blink data
%
% INPUTS
%   filename    Name of a csv file containing blink data
%   formatType  'BinaryMat' or '3col'. See below for details.
%   sampleLen   int - Only necessary if formatType is '3col'
%   
% OUTPUT
%   blinks      nxf matrix (n = subjects, f = frames) with binary blink
%               data (1 = blink, 0 = no blink, NaN = lost data)
%
% formatType: '3col'
%   The file must contain a matrix with 3 columns, containing only numeric
%   data, with one row per blink. In each row, the 1st column contains a subject 
%   identifier (numeric value), the 2nd column contains the start frame of
%   the blink (integer value), and the 3rd column contains the end frame of 
%   the blink. The number of columns in the BLINK output is determined by 
%   the input variable SAMPLELEN.
%
% formatType: 'BinaryMat'
%   The csv file must contain a matrix of binary blink data, consisting of
%   1s (blink frame), 0s (non blink frame), and NaNs (lost data). 
%   NOTE:
%   In the file, there is one subject per column, with a frame per row. 
%   However, the output has this data transposed, such that each row is a 
%   different subject and each column is a frame, to match input 
%   specifications for the blink analysis functions.

% Written by Carolyn Ranti
% 2.23.2015

try
    if strcmpi(formatType,'BinaryMat')
        blinks = csvread(filename);
        blinks = blinks';
    elseif strcmpi(formatType,'3col')
        blinks_3col = csvread(filename);
        [blinks,~] = blink3ColConvert(blinks_3col, sampleLen);
    end
    
catch ME
    err = MException('BlinkGUI:fileIn',sprintf('Error reading in blink file %s',filename));
    err = addCause(err,ME);
    throw(err);
end

