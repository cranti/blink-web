function csvReady = mat2csv(mat)
%MAT2CSV Convert a matrix of numeric data into a csv-formatted string
% 
% INPUT:
%   mat         Numeric matrix
% 
% OUTPUT:
%   csvReady    String with data from MAT. Commas delimit columns and a new
%               line (\n) delimits rows. 
%
% Use fprintf to print the resulting string into a file.
%
% See also CSVWRITE, FPRINTF

% Carolyn Ranti
% 2.24.2015 documentation

cellVer = num2cell(mat);
cellVer = cellfun(@num2str,cellVer,'UniformOutput',false);

strRows = {};
for r = 1:size(cellVer,1)
    strRows{r} = strjoin(cellVer(r,:),',');
end

csvReady = strjoin(strRows,'\n');
    
