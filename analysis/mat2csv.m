function csvReady = mat2csv(mat)
%MAT2CSV
% Convert a matrix of numbers to a string that is ready to print into a csv
% file. 
%
% String has commas delimiting columns, and a new line (\n) delimiting
% rows. Use fprintf to print the resulting string into a file.

% Carolyn Ranti
% 2.18.2015

cellVer = num2cell(mat);
cellVer = cellfun(@num2str,cellVer,'UniformOutput',false);

strRows = {};
for r = 1:size(cellVer,1)
    strRows{r} = strjoin(cellVer(r,:),',');
end

csvReady = strjoin(strRows,'\n');
    
