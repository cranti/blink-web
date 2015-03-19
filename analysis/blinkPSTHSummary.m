function blinkPSTHSummary(prefix, results, otherInputSpecs)
%BLINKPSTHSUMMARY - Write out csv summary of results from blinkPSTH.m
%
% Inputs:
%   prefix          Prefix for filename to write results to. Will be appended
%                   with summary.csv. Any existing content will be overwritten.
%                   Can include name of directory where file should be saved.
% 	results         Results struct from blinkPSTH.m
%   extraInputSpecs Struct with information about the way that target and
%                   reference data were identified. Fields that will be
%                   printed (if they exist) are: refEventType, refCode,
%                   refSetLen, targetEventType, and targetCode.
%
% See also MAT2CSV

% Written by Carolyn Ranti
% 3.19.2015

%%

if nargin<3 || ~isstruct(otherInputSpecs)
    otherInputSpecs = struct();
end

%% Open file
filename = sprintf('%sPSTHsummary.csv', prefix);
fid = fopen(filename, 'w');
if fid<0
    ME = MException('BlinkGUI:fileOut',sprintf('Error printing PSTH summary - could not create file %s',filename));
    throw(ME);
end

try
	%% summary heading
	fprintf(fid, 'Peri-Stimulus Time Histogram,%s\n', datestr(now));
    
    %% GENERAL SETTINGS
    fprintf(fid, '\n** SETTINGS **\n');
    fprintf(fid, 'Window size before event:,%i\n', results.inputSpecs.lagSize(1));
    fprintf(fid, 'Window size after event:,%i\n', results.inputSpecs.lagSize(2));
    fprintf(fid, 'Start Frame:,%i\n', results.inputSpecs.startFrame);
    fprintf(fid, 'Include threshold:,%.2f\n',results.inputSpecs.inclThresh);
    fprintf(fid, '# permutations,%i\n', results.permTest.numPerms);


	%% Reference event data
    fprintf(fid,'\n** REFERENCE SETS **\n');
    fprintf(fid, 'Input file:,%s\n', otherInputSpecs.refFilename);

    if isfield(otherInputSpecs, 'refEventType')
        fprintf(fid, 'Event Type:,%s\n', otherInputSpecs.refEventType);
    end
    if isfield(otherInputSpecs, 'refCode')
        fprintf(fid, 'Event Code:,%i\n', otherInputSpecs.refCode);
    end
    fprintf(fid, '# reference sets:,%i\n', results.inputSpecs.numRefSets);
    if isfield(otherInputSpecs, 'refSetLen')
        fprintf(fid, '# samples per reference set:,%s\n', mat2csv(otherInputSpecs.refSetLen, 1));
    end

    %% Target event data
    fprintf(fid,'\n** TARGETS **\n');
    fprintf(fid, 'Input file:,%s\n', otherInputSpecs.targetFilename); 

    if isfield(otherInputSpecs, 'targetEventType')
        fprintf(fid, 'Event Type:,%s\n', otherInputSpecs.targetEventType);
    end
    if isfield(otherInputSpecs, 'targetCode')
        fprintf(fid, 'Event Code:,%i\n', otherInputSpecs.targetCode);
    end
    fprintf(fid, '# target participants:,%i\n', results.inputSpecs.numTargets);
    fprintf(fid, '# samples per target participant:,%s\n', mat2csv(results.inputSpecs.targetLens, 1));
   
    
    %% PSTH
	fprintf(fid, '\n** PSTH RESULTS **\n');
	
    offsetToPrint = (-results.inputSpecs.lagSize(1)):(results.inputSpecs.lagSize(2));
    fprintf(fid, 'Offset from event:,%s\n', mat2csv(offsetToPrint));
    fprintf(fid, 'PSTH (avg # blinks):,%s\n', mat2csv(results.psth, 1));

	% significance
    fprintf(fid, '%.2f percentile of permutations:,%s\n', results.permTest.lowPrctileLevel, mat2csv(results.permTest.lowPrctile, 1));
	fprintf(fid, '%.2f percentile of permutations:,%s\n', results.permTest.highPrctileLevel, mat2csv(results.permTest.highPrctile, 1));
    fprintf(fid, 'Mean of permutations:,%s\n', mat2csv(results.permTest.mean, 1));
    
    
    %% individual PSTH
    fprintf(fid, '\n** INDIVIDUAL RESULTS **\n');
    
    % Table of values  
    fprintf(fid, 'Total reference events per target participant:,%s\n', mat2csv(results.indivUsedRefEventN, 1));
    fprintf(fid, 'Included reference events per target participant:,%s\n', mat2csv(results.indivTotalRefEventN, 1));
	fprintf(fid, '# events w/ padding before event:,%s\n', mat2csv(results.nTargetPadding(:,1), 1));
	fprintf(fid, '# events w/ padding after event:,%s\n', mat2csv(results.nTargetPadding(:,2), 1));
	fprintf(fid, '# events w/ padding before & after:,%s\n', mat2csv(results.nTargetPadding(:,3), 1));
    
    fprintf(fid, '\nIndividual PSTH (avg # blinks. 1 row per target participant)\n');
    fprintf(fid, 'Offset from event:,%s\n', mat2csv(offsetToPrint));
    for ii = 1:size(results.indivPSTH, 1)
        fprintf(fid,',%s\n',mat2csv(results.indivPSTH(ii,:), 1));
    end

catch ME
    fclose(fid);
    
    err = MException('BlinkGUI:fileOut', 'Error printing PSTH summary file.');
    err = addCause(err, ME);
    throw(err);
end

%% Wrap up
fclose(fid);