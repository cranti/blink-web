function [blinks, error_msg] = readInBlinks(filename, formatType, sampleLen)
%TODO - if format type is '3col', read in 3 column version -- use sampleLen
% Otherwise, if format type is 'BinaryMat' or 
%
% Add error checking, etc
% NOTE: Excel has a much higher row limit than column limit, so I've
% switched the input specifications (for the BinaryMat option): users should save their data with
% subjects as columns and frames as rows. This script will transpose the
% data, to match the format of all of the original scripts.


error_msg = '';
try
    if nargin==1 || strcmpi(formatType,'BinaryMat')
        blinks = csvread(filename);
        blinks = blinks';
    elseif strcmpi(formatType,'3col')
        %TODO - read in file. csvread only works with numbers, so that's
            %what subject identifiers will have to be...
        blinks_3col = csvread(filename);
        [blinks,~] = blink3ColConvert(blinks_3col, sampleLen);
    end
    
catch ME
    error_msg = ME.message;
    blinks = [];
end

