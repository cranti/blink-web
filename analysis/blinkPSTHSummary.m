function crossCorrSummary(filename, results)
%TODO 
% - think of better labels
% - document
%
% Written by Carolyn Ranti
% 2.22.2015

fid = fopen(filename,'w');
if fid<0
	error(sprintf('Could not open file %s', filename));
end

try
	%print summary title
	fprintf(fid, '%s,%s\n','Analysis Summary:','Peri-Stimulus Time Histogram');

	%print input settings:
	% number of subjects
	% number of frames
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
	fprintf(fid, 'PSTH:\n', mat2csv(results.crossCorr));

	% print significance
	fprintf(fid, '5th percentile of permutations:,%s\n', mat2csv(results.prctile05));
	fprintf(fid, '95th percentile of permutations:,%s\n', mat2csv(results.prctile95));

catch
	error('Error printing peri-stimulus time histogram summary file.');
	fclose(fid);
end
