function crossCorrFigures(outputDir, results, yText, ax)
% TODO - testing, documentation
%
% Written by Carolyn Ranti
% 2.22.2015

try
	% Create a new axis if a handle wasn't passed in
	if nargin < 4
		figure();
		ax = gca;
	else
		cla(ax,'reset');
	end

	%
	xValues = length(results.crossCorr) - (length(results.crossCorr)+1)/2;

	% bar graph
	bar(ax, xValues, results.crossCorr, 'k');
	hold on
	plot(ax, xValues, results.prctile05, 'b');
	plot(ax, xValues, results.prctile95, 'r');

	legend(ax, {'Peri-stimulus time histogram','5th percentile','95th percentile'});
	xlabel(ax, 'Event offset (frames)');
	ylabel(ax, yText);

catch
	error('Error plotting peri-stimulus time histogram.');
end