function [error_msg] = blinkPermSummary(filename, results)
%Write out csv summary of RESULTS (structure from blinkPerm.m) to FILENAME
% Overwrites anything in FILENAME
% 
% Blanket try/catch statement -- if there is an error, it is output.
% Otherwise, empty string is output.
%
% See also MAT2CSV

% TODO - print in columns, not rows, to deal with excel limitations
% TODO - when thinking about limitations for the data that can be input,
% consider how much data can be output into a csv.
% TODO - error checking (filename must be a csv?)
% Carolyn Ranti
% 2.18.2015

error_msg = '';

excelColLimit = 16384;

try
    fid = fopen(filename,'w');
    fprintf(fid, '%s,%s\n\n', 'Summary:', 'Group Blink Modulation Analysis');
    fprintf(fid, 'Summary printed:,%s\n', datestr(now));
    fprintf(fid, 'Number of permutations:,%i\n\n', results.inputValues.numPerms);

    
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
    
    %% smoothed blink rate and 5th/95th percentiles are printed in columns
    col_titles = {'Smoothed Blink Rate',...
                '5th Percentile of Permutations',...
                '95th Percentile of Permutations'};
    table = [results.smoothedBR;
            results.permBR_5thP;
            results.permBR_95thP]';
    smoothBR_Percs = mat2csv(table);

    fprintf(fid,'\n');
    fprintf(fid,'%s,%s,%s\n', col_titles{:});
    fprintf(fid,'%s\n',smoothBR_Percs);
    
catch ME
    error_msg = ME.message;
end




