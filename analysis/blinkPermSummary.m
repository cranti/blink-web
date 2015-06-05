function blinkPermSummary(prefix, results)
%BLINKPERMSUMMARY - Write out csv summary of results from blinkPerm.m
%
% Inputs:
%   prefix      Prefix for filename to write results to. Will be appended
%               with summary.csv. Any existing content will be overwritten.
%               This can include a path, if you don't want it saved in
%               current directory.
%   results     Results struct from blinkPerm.m
%
% See also MAT2CSV

% Written by Carolyn Ranti
% 6.5.2015

%% Handle Excel limitations by printing in columns, if necessary.
excelColLimit = 16384; 

%% Open file
filename = sprintf('%sBLINK_MODsummary.csv', prefix);
fid = fopen(filename,'w');
if fid<0
    ME = MException('BlinkGUI:fileOut',sprintf('Could not create file %s',filename));
    throw(ME);
end

try
    %% summary heading
    fprintf(fid, 'Blink Inhibition Analysis,%s\n', datestr(now));
    
    %% input/settings
    fprintf(fid, '\n** INPUTS **\n');
    fprintf(fid, 'filename,%s\n', results.inputs.filename);
    fprintf(fid, 'numParticipants,%i\n', results.inputs.numParticipants);
    fprintf(fid, 'numSamples,%i\n', results.inputs.numSamples); 
    fprintf(fid, 'sampleRate,%s\n', num2str(results.inputs.sampleRate));
    fprintf(fid, 'numPerms,%i\n', results.inputs.numPerms);
    if isempty(results.inputs.bandWRange)
        fprintf(fid, 'bandWRange,Not specified\n');
    else
        fprintf(fid, 'bandWRange,%s\n',num2str(results.inputs.bandWRange)); %TODO - change this. currently printing EVERY value in the range
    end
    fprintf(fid, 'lowerPrctileCutoff,%s\n',num2str(results.inputs.lowerPrctileCutoff)); 
    fprintf(fid, 'upperPrctileCutoff,%s\n',num2str(results.inputs.upperPrctileCutoff)); 
    fprintf(fid, 'numConsecSamples,%i\n', results.inputs.numConsecSamples);
    
    
    %%
    fprintf(fid, '\n** SMOOTHING **\n');
    fprintf(fid, 'bandW,%f\n', results.smoothing.bandW);
    
    %% increased and decreased frames are printed in a row each, if they fit
    fprintf(fid,'\n** SAMPLES W/ SIGNIFICANT BLINK MODULATION **\n');
    
    numDB = size(results.sigBlinkMod.blinkInhib,2);
    numIB = size(results.sigBlinkMod.incrBlink,2);
    
    if numDB < excelColLimit && numIB < excelColLimit
        decreasedBlinking = mat2csv(results.sigBlinkMod.blinkInhib, 1);
        increasedBlinking = mat2csv(results.sigBlinkMod.incrBlink, 1);
        fprintf(fid,'%s,%s\n','blinkInhib',decreasedBlinking);
        fprintf(fid,'%s,%s\n','incrBlink',increasedBlinking);

    else %otherwise, they are printed in columns

        table = num2cell(results.sigBlinkMod.blinkInhib');
        table(1:numIB, 2) = num2cell(results.sigBlinkMod.incrBlink');

        allSig_table = mat2csv(table);
        fprintf(fid,'%s,%s\n','blinkInhib',...
                            'incrBlink');
        fprintf(fid,'%s\n', allSig_table);              
    end
    
    
    %% smoothed blink rate and low/high percentiles are printed in columns
    fprintf(fid,'\n** SMOOTHED BLINK RATE (ALL SAMPLES) **\n');
    
    col_titles = {'Sample#',...
                'groupBR',...
                'lowerPrctilePerm',...
                'upperPrctilePerm'};
    
    table = [1:results.inputs.numSamples;
            results.smoothInstBR.groupBR;
            results.smoothInstBR.lowerPrctilePerm;
            results.smoothInstBR.upperPrctilePerm]';
    smoothBR_Percs = mat2csv(table);

    fprintf(fid,'%s,%s,%s,%s\n', col_titles{:});
    fprintf(fid,'%s\n',smoothBR_Percs);

catch ME
    fclose(fid);
    
    err = MException('BlinkGUI:fileOut', 'Error printing blink modulation summary file.');
    err = addCause(err, ME);
    throw(err);
end

%% Wrap up
fclose(fid);