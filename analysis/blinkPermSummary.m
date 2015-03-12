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
% 2.23.2015

excelColLimit = 16384; %dealing with Excel limitations by printing in columns, if necessary.

% Open file
filename = sprintf('%sblinkModSummary.csv', prefix);
fid = fopen(filename,'w');
if fid<0
    ME = MException('BlinkGUI:fileOut',sprintf('Could not create file %s',filename));
    throw(ME);
end


try

    % summary heading
    fprintf(fid, '%s,%s\n\n', 'Summary:', 'Group Blink Modulation Analysis');
    fprintf(fid, 'Summary printed:,%s\n', datestr(now));
    
    % input setting
    fprintf(fid, 'Number of permutations:,%i\n', results.inputs.numPerms);
    fprintf(fid, 'Optimized W used for Gaussian kernel:,%f', results.optW);
    fprintf(fid,'\n');
    
    %% increased and decreased frames are printed in a row each, if they fit
    if length(results.decreasedBlinking) < excelColLimit && length(results.increasedBlinking) < excelColLimit
        decreasedBlinking = mat2csv(results.decreasedBlinking);
        increasedBlinking = mat2csv(results.increasedBlinking);
        fprintf(fid,'%s,%s\n','Frames w/ significantly decreased blinking',decreasedBlinking);
        fprintf(fid,'%s,%s\n','Frames w/ significantly increased blinking',increasedBlinking);
    
    else %otherwise, they are printed in columns
        table = [results.decreasedBlinking; 
                results.increasedBlinking]';
        allSig_table = mat2csv(table);
        fprintf(fid,'%s,%s\n','Moments of significantly decreased blinking',...
                            'Moments of significantly increased blinking');
        fprintf(fid,'%s\n', allSig_table);              
    end
    
    %separate sections with a newline
    fprintf(fid,'\n'); 
    
    %% smoothed blink rate and low/high percentiles are printed in columns
    col_titles = {'Smoothed Blink Rate',...
                sprintf('%.2f percentile of permutations', results.lowPrctileLevel),...
                sprintf('%.2f percentile of permutations', results.highPrctileLevel)};
    table = [results.smoothedBR;
            results.lowPrctile;
            results.highPrctile]';
    smoothBR_Percs = mat2csv(table);

    fprintf(fid,'\n');
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