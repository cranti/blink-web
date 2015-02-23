function refEvents = readInRefEvents(filename)
% Read in a csv with one row per set of reference events -- 
% reference events must be number values.
% The rows do not need to be the same length (??)
% 
% Outputs a cell with one entry per set of reference events
% Entries are vectors of number values
%
% Written by Carolyn Ranti
% 2.22.2015

try
	M = csvread(filename);

	refEvents = {};
	for r = 1:size(M,1)
		refEvents{end+1} = M(r,:);
	end
	
catch 
	error('Error reading in reference events file.')
end