function blinkPSTHSummary(prefix, results, otherInputSpecs)
%BLINKPSTHSUMMARY - Write out csv summary of results from blinkPSTH.m
%
% Inputs:
%   prefix          Prefix for filename to write results to -- will be appended
%                   with 'summary.csv'. Any existing content will be overwritten.
%                   Can include name of directory where file should be saved.
% 	results         Results struct from blinkPSTH.m
%   otherInputSpecs Struct with information about the way that target and
%                   reference data were identified. Fields that will be
%                   printed (if they exist) are: refEventType, refCode,
%                   refLens, targetEventType, and targetCode.
%
% See also MAT2CSV

% Written by Carolyn Ranti
% 4.9.2015

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
    fprintf(fid, '\n** INPUTS **\n');
    fprintf(fid, 'Window size before event:,%i\n', results.inputs.lagSize(1));
    fprintf(fid, 'Window size after event:,%i\n', results.inputs.lagSize(2));
    fprintf(fid, 'Sample start:,%i\n', results.inputs.startFrame);
    fprintf(fid, 'Include threshold:,%s\n', num2str(results.inputs.inclThresh));
    fprintf(fid, '# permutations,%i\n', results.permTest.numPerms);
    fprintf(fid, 'Lower percentile cutoff:,%s\n',num2str(results.permTest.lowPrctileLevel)); 
    fprintf(fid, 'Upper percentile cutoff:,%s\n',num2str(results.permTest.highPrctileLevel)); 

	%% Reference event data
    fprintf(fid,'\n** REFERENCE EVENTS **\n');
    fprintf(fid, 'Input file:,%s\n', otherInputSpecs.refFilename);

    if isfield(otherInputSpecs, 'refEventType')
        fprintf(fid, 'Event type:,%s\n', otherInputSpecs.refEventType);
    end
    if isfield(otherInputSpecs, 'refCode')
        fprintf(fid, 'Event code:,%s\n', num2str(otherInputSpecs.refCode));
    end
    fprintf(fid, '# reference sets:,%i\n', results.inputs.numRefSets);
    if isfield(otherInputSpecs, 'refLens')
        fprintf(fid, '# samples per reference set:,%s\n', mat2csv(otherInputSpecs.refLens, 1));
    end

    %% Target event data
    fprintf(fid,'\n** TARGET EVENTS **\n');
    fprintf(fid, 'Input file:,%s\n', otherInputSpecs.targetFilename); 

    if isfield(otherInputSpecs, 'targetEventType')
        fprintf(fid, 'Event type:,%s\n', otherInputSpecs.targetEventType);
    end
    if isfield(otherInputSpecs, 'targetCode')
        fprintf(fid, 'Event code:,%s\n', num2str(otherInputSpecs.targetCode));
    end
    fprintf(fid, '# target participants:,%i\n', results.inputs.numTargets);
    fprintf(fid, '# samples per target participant:,%s\n', mat2csv(results.inputs.targetLens, 1));
   
    
    %% PSTH
	fprintf(fid, '\n** GROUP PSTH RESULTS **\n');
	
    %print offset (time from event) with each psth:
    offsetToPrint = (-results.inputs.lagSize(1)):(results.inputs.lagSize(2));
    offsetToPrint = mat2csv(offsetToPrint);
    
    %PSTH as average blink count
    fprintf(fid, 'PSTH - Average Blink Count\n');
    fprintf(fid, 'Time (samples):,%s\n', offsetToPrint);
    fprintf(fid, 'psth:,%s\n', mat2csv(results.psth, 1));
    fprintf(fid, 'lowerPrctile:,%s\n', mat2csv(results.permTest.lowPrctile, 1));
	fprintf(fid, 'upperPrctile:,%s\n', mat2csv(results.permTest.highPrctile, 1));
    fprintf(fid, 'permMean:,%s\n', mat2csv(results.permTest.mean, 1));
    
    %PSTH as percent change from mean
    fprintf(fid, '\nPSTH - Percent Change from Mean\n');
    fprintf(fid, 'Time (samples):,%s\n', offsetToPrint);
    fprintf(fid, 'psth:,%s\n', mat2csv(results.changeFromMean.psth));
    fprintf(fid, 'lowerPrctile:,%s\n', mat2csv(results.changeFromMean.lowerPrctile));
    fprintf(fid, 'upperPrctile:,%s\n', mat2csv(results.changeFromMean.upperPrctile));

    
    %% individual PSTH
    fprintf(fid, '\n** INDIVIDUAL PSTH RESULTS **\n');
    
    %Table of values for individual results
    if isfield(otherInputSpecs, 'targetOrder')
        fprintf(fid, 'Target identifier:,%s\n', mat2csv(otherInputSpecs.targetOrder, 1));
    end 
    
    if isfield(otherInputSpecs, 'refOrder')
        refOrder = otherInputSpecs.refOrder;
        if isscalar(refOrder)
            refOrder = ones(size(otherInputSpecs.targetOrder))*refOrder;
        end
        fprintf(fid, 'Reference identifier:,%s\n', mat2csv(refOrder, 1));
    end
    
    fprintf(fid, 'Total reference events per target participant:,%s\n', mat2csv(results.indivTotalRefEventN, 1));
    fprintf(fid, 'Included reference events per target participant:,%s\n', mat2csv(results.indivUsedRefEventN, 1));
	fprintf(fid, '# events w/ padding before event:,%s\n', mat2csv(results.nTargetPadding(:,1), 1));
	fprintf(fid, '# events w/ padding after event:,%s\n', mat2csv(results.nTargetPadding(:,2), 1));
	fprintf(fid, '# events w/ padding before & after:,%s\n', mat2csv(results.nTargetPadding(:,3), 1));
    
    fprintf(fid, '\nIndividual PSTH, (avg blink count; 1 row per target participant)\n');
    
    fprintf(fid, 'Target identifier \\\\ Time (samples):,%s\n', offsetToPrint);
    for ii = 1:size(results.indivPSTH, 1)
        fprintf(fid,'%s\n',mat2csv([otherInputSpecs.targetOrder(ii),results.indivPSTH(ii,:)], 1));
    end

catch ME
    fclose(fid);
    
    err = MException('BlinkGUI:fileOut', 'Error printing PSTH summary file.');
    err = addCause(err, ME);
    throw(err);
end

%% Wrap up
fclose(fid);