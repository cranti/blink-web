function blinkPSTHSummary(prefix, results)
%BLINKPSTHSUMMARY - Write out csv summary of results from blinkPSTH.m
%
% Inputs:
%   prefix          Prefix for filename to write results to -- will be appended
%                   with 'summary.csv'. Any existing content will be overwritten.
%                   Can include name of directory where file should be saved.
% 	results         Results struct from blinkPSTH(), after it's been 
%                   converted by blinkPSTHMatConvert() 
%
% See also MAT2CSV

% Written by Carolyn Ranti
% 7.7.2015

%TODO - carefully check outputs to make sure that things haven't been switched around


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
    fprintf(fid, 'winSizeBefore,%i\n', results.inputs.winSizeBefore);
    fprintf(fid, 'winSizeAfter,%i\n', results.inputs.winSizeAfter);
    fprintf(fid, 'sampleStart,%i\n', results.inputs.sampleStart);
    fprintf(fid, 'numPerms,%i\n', results.inputs.numPerms);
    fprintf(fid, 'lowerPrctileCutoff,%s\n',num2str(results.inputs.lowerPrctileCutoff)); 
    fprintf(fid, 'upperPrctileCutoff,%s\n',num2str(results.inputs.upperPrctileCutoff)); 
    fprintf(fid, 'includeThresh,%s\n', num2str(results.inputs.includeThresh));
    
	%% Reference event data
    fprintf(fid,'\n** REFERENCE EVENTS **\n');
    fprintf(fid, 'filename,%s\n', results.refEvents.filename);
    fprintf(fid, 'eventType,%s\n', results.refEvents.eventType);
    fprintf(fid, 'eventCode,%s\n', num2str(results.refEvents.eventCode));
    fprintf(fid, 'numSets,%i\n', results.refEvents.numSets);
    fprintf(fid, 'numSamples,%s\n', mat2csv(results.refEvents.numSamples, 1));
    
    %% Target event data
    fprintf(fid,'\n** TARGET EVENTS **\n');
    fprintf(fid, 'filename,%s\n', results.targetEvents.filename); 
    fprintf(fid, 'eventType,%s\n', results.targetEvents.eventType);
    fprintf(fid, 'eventCode,%s\n', num2str(results.targetEvents.eventCode));
    fprintf(fid, 'numSets,%i\n', results.targetEvents.numSets);
    fprintf(fid, 'numSamples,%s\n', mat2csv(results.targetEvents.numSamples, 1));
   
    
    %% PSTH
	fprintf(fid, '\n** GROUP PSTH RESULTS **\n');
	
    %PSTH as average blink count
    fprintf(fid, 'PSTH - Mean Blink Count\n');
    fprintf(fid, 'time,%s\n', mat2csv(results.groupPSTH.time,1));
    fprintf(fid, 'meanBlinkCount,%s\n', mat2csv(results.groupPSTH.meanBlinkCount, 1));
    fprintf(fid, 'lowerPrctilePerm,%s\n', mat2csv(results.groupPSTH.lowerPrctilePerm, 1));
	fprintf(fid, 'upperPrctilePerm,%s\n', mat2csv(results.groupPSTH.upperPrctilePerm, 1));
    fprintf(fid, 'meanPerm,%s\n', mat2csv(results.groupPSTH.meanPerm, 1));
    
    %PSTH as percent change from mean
    fprintf(fid, '\nPSTH - Percent Change from Mean\n');
    fprintf(fid, 'time,%s\n', mat2csv(results.groupPSTH.time,1));
    fprintf(fid, 'percChangeBPM,%s\n', mat2csv(results.groupPSTH.percChangeBPM));
    fprintf(fid, 'percChangeLowerPrctile,%s\n', mat2csv(results.groupPSTH.percChangeLowerPrctile));
    fprintf(fid, 'percChangeUpperPrctile,%s\n', mat2csv(results.groupPSTH.percChangeUpperPrctile));

    
    %% individual PSTH
    fprintf(fid, '\n** INDIVIDUAL PSTH RESULTS **\n');
    
    %Table of values for individual results
    fprintf(fid, 'targetSetID,%s\n', mat2csv(results.indivPSTH.targetSetID, 1));
    
    refOrder = results.indivPSTH.refSetID;
    if isscalar(refOrder)
        refOrder = ones(size(results.indivPSTH.refSetID))*refOrder;
    end
    fprintf(fid, 'refSetID,%s\n', mat2csv(refOrder, 1));

    fprintf(fid, 'numRefEventsDefined,%s\n', mat2csv(results.indivPSTH.numRefEventsDefined, 1));
    fprintf(fid, 'numRefEventsIncl,%s\n', mat2csv(results.indivPSTH.numRefEventsIncl, 1));
	fprintf(fid, 'numTargetEventsDefined,%s\n', mat2csv(results.indivPSTH.numTargetEventsDefined, 1));
    fprintf(fid, 'numPadBefore,%s\n', mat2csv(results.indivPSTH.numPadBefore, 1));
	fprintf(fid, 'numPadAfter,%s\n', mat2csv(results.indivPSTH.numPadAfter, 1));
	fprintf(fid, 'numPadBoth,%s\n', mat2csv(results.indivPSTH.numPadBoth, 1));
    
    fprintf(fid, '\nindivMeanBlinkCount\n');
    
    fprintf(fid, 'targetSetID \\\\ time,%s\n', results.indivPSTH.time);
    for ii = 1:size(results.indivPSTH.meanBlinkCount, 1)
        fprintf(fid,'%s\n',mat2csv([results.indivPSTH.targetSetID(ii), results.indivPSTH.meanBlinkCount(ii,:)], 1));
    end

catch ME
    fclose(fid);
    
    err = MException('BlinkGUI:fileOut', 'Error printing PSTH summary file.');
    err = addCause(err, ME);
    throw(err);
end

%% Wrap up
fclose(fid);