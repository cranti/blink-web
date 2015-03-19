function csvReady = mat2csv(mat, oneRow)
%MAT2CSV Convert a matrix of numeric data into a csv-formatted string
% 
% INPUT:
%   mat         Numeric matrix OR cell 
%   oneRow      If true, will delimit both rows AND columns with commas
%               (i.e. a single row of csv data) 
% 
% OUTPUT:
%   csvReady    String with data from MAT. Commas delimit columns and a new
%               line (\n) delimits rows. 
%
% Use fprintf to print the resulting string into a file.
%
% 
%
% See also CSVWRITE, FPRINTF

% Carolyn Ranti
% 3.16.2015


%if oneRow isn't specified, print as is
if nargin == 1
    oneRow = 0;
end

% If cell is passed in for mat, don't use num2cell
if ~iscell(mat)
    cellVer = num2cell(mat);
else
    cellVer = mat;
end

cellVer = cellfun(@num2str,cellVer,'UniformOutput',false);

strRows = {};
for r = 1:size(cellVer,1)
    strRows{r} = strjoin(cellVer(r,:),',');
end

if oneRow  
    csvReady = strjoin(strRows,',');
else
    csvReady = strjoin(strRows,'\n');
end
