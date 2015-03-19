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
% 3.17.2015

%%

% dealing with Excel limitations by printing in columns, if necessary.
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
    fprintf(fid, 'Group Blink Modulation Analysis,%s\n', datestr(now));
    
    %% input/settings
    fprintf(fid, '\n** SETTINGS **\n');
    fprintf(fid, 'Input file:,%s\n', 'TODO - ADD THIS');
    fprintf(fid, '# permutations:,%i\n', results.inputs.numPerms);
    fprintf(fid, 'Optimized W used for Gaussian kernel:,%f\n', results.optW);

    
    %% increased and decreased frames are printed in a row each, if they fit
    fprintf(fid,'\n** SIGNIFICANT FRAMES **\n');
    
    numDB = size(results.decreasedBlinking,2);
    numIB = size(results.increasedBlinking,2);
    
    if numDB < excelColLimit && numIB < excelColLimit
        decreasedBlinking = mat2csv(results.decreasedBlinking, 1);
        increasedBlinking = mat2csv(results.increasedBlinking, 1);
        fprintf(fid,'%s,%s\n','Frames w/ decreased blinking',decreasedBlinking);
        fprintf(fid,'%s,%s\n','Frames w/ increased blinking',increasedBlinking);

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
                sprintf('%.2f percentile of permutations', results.lowPrctileLevel),...
                sprintf('%.2f percentile of permutations', results.highPrctileLevel)};
    table = [results.smoothedBR;
            results.lowPrctile;
            results.highPrctile]';
    smoothBR_Percs = mat2csv(table);

    fprintf(fid,'**ALL FRAMES**\n');
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