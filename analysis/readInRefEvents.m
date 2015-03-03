function refEvents = readInRefEvents(filename)
%READINREFEVENTS Read in a csv with reference events for blinkPSTH.m
% 
% INPUT
%   filename    Name of a csv file containing numeric reference data.
%
% OUTPUT
%   refEvents   Cell vector. Each entry is a vector corresponding to a row
%               in the original file.
%
% READINREFEVENTS(FILENAME) uses CSVREAD to read in reference event data
% from a csv file. The file must contain 
% Read in a csv with one row per set of reference events -- 
% reference events must be number values.
% The rows do not need to be the same length (??)
% 
% Outputs a cell with one entry per set of reference events
% Entries are vectors of number values

% Written by Carolyn Ranti
% 2.23.2015

try
	%TODO - what does csvread do when rows have different numbers of columns?
	M = csvread(filename);

	refEvents = {};
	for r = 1:size(M,1)
		refEvents{end+1} = M(r,:);
	end
	
catch ME
    err = MException('BlinkGUI:fileIn',sprintf('Error reading in reference events file %s',filename));
    err = addCause(err, ME);
    throw(err);
end