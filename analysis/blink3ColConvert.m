function [blinkMat,subjOrder] = blink3ColConvert(blinks, sampleLen, outCell)
%BLINK3COLCONVERT - Convert 3 column input into a matrix of binary blink
%	data, with one person's data per row.
%
% INPUT
% 	blinks 		3 column matrix. See below for details.
%	sampleLen 	length of the clip sampled. Determines number of columns
% 				in the output matrix.
%   outCell     Optional. If true, output a cell with one entry per
%               subject. Default False.
%
% OUTPUT
% 	blinks 		n x f matrix (n = subjects, f = frames) with binary blink
%       		data (1 = blink, 0 = no blink, NaN = lost data). If outCell
%       		is true, 
% 	subjOrder 	order of subjects, matching the rows of blinkMat. Order is
%       		preserved from input.
%
% NOTES
%	The input matrix BLINKS contains blink data for a group of people, with
% 	one row per blink. In each row, the 1st column contains a unique subject 
% 	identifier (a numeric value), the 2nd column contains the start frame of
% 	the blink (integer value), and the 3rd column contains the end frame of 
% 	the blink. 
%
%	Example: 
%		Suppose subject 1 blinked twice, from frames 3-5 and frames 9-12,  
%		subject 2 blinked once, from frames 8-10, and data was collected for
%		15 frames.
%	
%			>> blinks = [1, 3, 5;
%				 	 	1, 9, 12;
%				 	 	2, 8, 10]; 
%			>> sampleLen = 15;
%
%			>> [blinkMat, subjOrder] = blink3ColConvert(blinks, sampleLen)
%			blinkMat = [0 0 1 1 1 0 0 0 1 1 1 1 0 0 0;
%						0 0 0 0 0 0 0 1 1 1 0 0 0 0 0];
%			subjOrder = [1; 2]
%
% 	In addition, if there is a blink start or stop index that is greater than
%	the sampleLen provided, the output matrix will still have enough frames to 
%	accommodate that blink. In the above example, if sampleLen < 12, the output
% 	blinkMat will still have 12 columns.

% Carolyn Ranti
% 3.17.2015 - added cell option

%% Inputs/checks

%default
if nargin<3
    outCell = 0;
end

assert(size(blinks,2)==3,'Input error: Blink data must have 3 columns.');

%%
subjOrder = unique(blinks(:,1),'stable'); %preserve the order of subjects

if ~outCell
    blinkMat = zeros(length(subjOrder), sampleLen);
else
    % if only one sampleLen is passed in, expand so that the same value
    % applies to all subjects
    if isscalar(sampleLen)
       sampleLen = sampleLen*ones(1, length(subjOrder)); 
    end
    
    % preallocate: vector of zeros in each cell entry
    blinkMat = cell(1, length(subjOrder));
    for ii = 1:length(subjOrder)
        blinkMat{ii} = zeros(1, sampleLen(ii));
    end
end

for ii = 1:size(blinks,1)
    start = blinks(ii,2);
    stop = blinks(ii,3);
    subjRow = (subjOrder == blinks(ii,1));
    
    if ~outCell
        blinkMat(subjRow,start:stop) = 1;
    else
        blinkMat{subjRow}(start:stop) = 1;
    end
end