function blinkPermSummary(prefix, results, inputFile)
%BLINKPERMSUMMARY - Write out csv summary of results from blinkPerm.m
%
% Inputs:
%   prefix      Prefix for filename to write results to. Will be appended
%               with summary.csv. Any existing content will be overwritten.
%               This can include a path, if you don't want it saved in
%               current directory.
%   results     Results struct from blinkPerm.m
%   inputFile   Optional - name of file loaded with data.
%
% See also MAT2CSV

% Written by Carolyn Ranti
% 3.17.2015

%% Handle Excel limitations by printing in columns, if necessary.
excelColLimit = 16384; 

%% Parse inputs
if nargin<3 || isempty(inputFile)
    inputFile = 'unknown';
end

%% Open file
filename = sprintf('%sBLINK_MODsummary.csv', prefix);
fid = fopen(filename,'w');
if fid<0
    ME = MException('BlinkGUI:fileOut',sprintf('Could not create file %s',filename));
    throw(ME);
end

try
    %% summary heading
    fprintf(fid, 'Group Blink Inhibition Analysis,%s\n', datestr(now));
    
    %% input/settings
    fprintf(fid, '\n** INPUTS **\n');
    fprintf(fid, 'Input file:,%s\n', inputFile);
    fprintf(fid, 'Sample rate (Hz):,%s\n', num2str(results.inputs.sampleRate));
    fprintf(fid, '# Individuals:,%i\n', results.inputs.numIndividuals);
    fprintf(fid, '# Permutations:,%i\n', results.inputs.numPerms);
    fprintf(fid, '# Consecutive samples (sig.):,%i\n', results.inputs.sigFrameThr);
    
    %%
    fprintf(fid, '\n** SMOOTHING **\n');
    fprintf(fid, 'Gaussian kernel bandwidth:,%f\n', results.optW);
    
    %% increased and decreased frames are printed in a row each, if they fit
    fprintf(fid,'\n** SIGNIFICANT FRAMES **\n');
    
    numDB = size(results.decreasedBlinking,2);
    numIB = size(results.increasedBlinking,2);
    
    if numDB < excelColLimit && numIB < excelColLimit
        decreasedBlinking = mat2csv(results.decreasedBlinking, 1);
        increasedBlinking = mat2csv(results.increasedBlinking, 1);
        fprintf(fid,'%s,%s\n','Decreased blinking',decreasedBlinking);
        fprintf(fid,'%s,%s\n','Increased blinking',increasedBlinking);

    else %otherwise, they are printed in columns

        table = num2cell(results.decreasedBlinking');
        table(1:numIB, 2) = num2cell(results.increasedBlinking');

        allSig_table = mat2csv(table);
        fprintf(fid,'%s,%s\n','Frames w/ decreased blinking',...
                            'Frames w/ increased blinking');
        fprintf(fid,'%s\n', allSig_table);              
    end
    
    
    %% smoothed blink rate and low/high percentiles are printed in columns
    fprintf(fid,'\n** ALL FRAMES **\n');
    
    col_titles = {'Smoothed Blink Rate',...
                sprintf('%s percentile of permutations', num2str(results.lowPrctileLevel)),...
                sprintf('%s percentile of permutations', num2str(results.highPrctileLevel))};
    table = [results.smoothedBR;
            results.lowPrctile;
            results.highPrctile]';
    smoothBR_Percs = mat2csv(table);

    fprintf(fid,'%s,%s,%s\n', col_titles{:});
    fprintf(fid,'%s\n',smoothBR_Percs);

catch ME
    fclose(fid);
    
    err = MException('BlinkGUI:fileOut', 'Error printing blink modulation summary file.');
    err = addCause(err, ME);
    throw(err);
end

%% Wrap up
fclose(fid);