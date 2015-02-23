function [output, error_msg] = PTmain(numPerms, blinkInput, sampleRate, sampleLen)
%DELETE ME - this is no longer really doing anything 

%PTMAIN
% Blink web app - main script for identifying moments of blink inhibition,
% using permutation testing.
%
% INPUT:
%   Number of permutations to run for the test
%   Blink data -- 2 acceptable formats.
%       n x f matrix (n = subjects, f = frames) with binary blink data (1 =
%           blink, 0 = not blink, NaN = lost data)
%       3 column matrix: subject #, start frame, end frame
%   Sample rate (Hz)
%   Sample length, in frames (only required if 3 column format is used for blink data)
%
% OUTPUT:
%   Struct with the following fields:   (same as BLINKPERM output)
%       smoothedBR - 1 x f vector with smoothed instantaneous blink rate
%       	for the group
%       decreasedBlinking - vector with frames in which the smoothed blink
%           rate of the group is less than the 5th percentile found by the
%           permutation testing.
%       increasedBlinking - vector with frames in which the smoothed blink
%           rate of the group is greater than the 95th percentile found by
%           permutation testing.
%       permBR_5thP - 1 x f vector with the 5th percentile blink rate found
%           by permutation testing.
%       permBR_95thP - 1 x f vector with the 95th percentile blink rate
%          found by permutation testing.
%      
% NOTES:
%  > How will data be passed to this script? Maybe the website should
%    handle different file types and output a text file?
%  > For website, document shortcomings of the clip-by-clip method (can't
%    concatenate as easily, because of the maxFrameNum requirement.)
%  > Think about the output data format (different possible options)
%       - Graph on the website: smoothed blink rate + 95th p + 5th p,
%       showing where there are significant moments of blink
%       inhib/increased blinking
%  > Sample rate: change to Hz, accept non-integer value
%  > Think about how to handle errors/report them to the user
%
% TIMING: 
%   sskernel is the bottleneck (in convWindow) - For 11 subjects, 46000 frames --> 200-ish 
%       secs, 5s for everything else.

% Carolyn Ranti
% Updated 2.18.15


error_msg = '';

try
    %% Prep input (TODO - do this in web app)
    
    %Convert from 3 column format to the n x f matrix format - TODO: do
    %this in the web app?
    
    if nargin == 4
        [blinkInput,~] = blink3ColConvert(blinkInput, sampleLen);
    end

    %% Moments of group blink inhib (permutations)
    %permutes data, computes instantaneous BR of permuted data, smoothes
    %instantaneous blink rate of permuted data, computes 95th and 5th
    %percentiles.

    % Permutation testing: 
    output = blinkPerm(numPerms, blinkInput, sampleRate);

catch ME
    %TODO - throw useful error messages
    
    output = '';
    error_msg = ME.message;
end
