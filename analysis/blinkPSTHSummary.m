function blinkPSTHSummary(filename, results)
%BLINKPSTHSUMMARY -  - Write out csv summary of RESULTS (structure from
% blinkPSTH.m) to FILENAME (overwriting any content).
%
% See also MAT2CSV

% Written by Carolyn Ranti
% 2.23.2015

fid = fopen(filename,'w');
if fid<0
    error('Could not open file %s',filename);
end

try
	%print summary title
	fprintf(fid, '%s,%s\n','Summary:','Peri-Stimulus Time Histogram');
    fprintf(fid, 'Summary printed:,%s\n', datestr(now));

	%print input settings:
    % TODO - think of better labels for some of these?)
	fprintf(fid, 'Number of subjects,%i\n', results.inputs.numIndividuals);
	fprintf(fid, 'Number of frames,%i\n', results.inputs.numFrames);
	fprintf(fid, 'Reference Event Type,%s\n', results.inputs.refEventType);
	fprintf(fid, 'Reference Event Code,%i\n', results.inputs.refCode);
	fprintf(fid, 'Target Event Type,%s\n', results.inputs.targetEventType);
	fprintf(fid, 'Target Event Code,%i\n', results.inputs.targetCode);
	fprintf(fid, 'Start Frame,%i\n', results.inputs.startFrame);
	fprintf(fid, 'Number of permutations,%i\n', results.inputs.numPerms);

	% print cross-correlogram
	fprintf(fid, '\nPSTH summary\n');
	fprintf(fid, 'Number of reference sets with no events:,%i\n', results.nRefsNoEvents);
	fprintf(fid, 'Number of events with padding\n');
	fprintf(fid, ',Before the event:,%s\n', results.nTargetPadding(1));
	fprintf(fid, ',After the event:,%s\n', results.nTargetPadding(2));
	fprintf(fid, ',Before and after:,%s\n', results.nTargetPadding(3));
	fprintf(fid, 'PSTH:,%s\n', mat2csv(results.crossCorr));

	% print significance
	fprintf(fid, '5th percentile of permutations:,%s\n', mat2csv(results.prctile05));
	fprintf(fid, '95th percentile of permutations:,%s\n', mat2csv(results.prctile95));

catch
	fclose(fid);
	error('Error printing peri-stimulus time histogram summary file.');
end
