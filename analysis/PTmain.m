%PTMAIN
% Blink web app - main script for blink inhibition id (permutation testing)
%
% INPUT:
%   Number of permutations to run for the test
%   Blink data -- 2 acceptable formats.
%       n x f matrix (n = subjects, f = frames) with 1 = blink, 0 = not blink, NaN = lost data
%         OR
%       3 column matrix: subject #, start frame, end frame
%   Samples per minute (e.g. 1800 if sample rate is 30Hz)
%   Sample length, in frames (only required if 3 column format is used for blink data)
%
% NOTES:
%  > How will data be passed to this script? Website will need to handle
%    file uploads
%  > For website, document shortcomings of the clip-by-clip method (can't
%    concatenate as easily, because of the maxFrameNum requirement.)
%  > Think about the output data format (different possible options)
%  > Sample rate: change to Hz? accept non-integer value?
%
%
% TIMING: 
%   sskernel is the bottleneck- For 11 subjects, 46000 frames --> 200-ish 
%       secs, 5s for everything else.
%
%   
% Carolyn Ranti

function output = PTmain(numPerms, blinkInput, samplesPerMin, sampleLen)


%% Prep input

if nargin == 4
    [blinkInput,subjOrder] = blink3ColConvert(blinkInput, sampleLen);
else
    subjOrder = 'Subject order unchanged from input.';
end

fractBlinks = raw2fractBlinks(blinkInput);

%% Moments of group blink inhib (permutations)
%permutes data, computes instantaneous BR of permuted data, smoothes
%instantaneous blink rate of permuted data, computes 95th and 5th
%percentiles.

% smooth group BR
Y = convWindow(fractBlinks); % gaussian window to convolve with data
smoothedBR = smoothBlinkRate(fractBlinks, samplesPerMin, Y);

% permutations
[permBR_5thP, permBR_95thP] = blinkPerm(numPerms, fractBlinks, samplesPerMin, Y);

% significant moments
decreasedFrames = find(smoothedBR < permBR_5thP);
increasedFrames = find(smoothedBR > permBR_95thP);

%% Output structure
output.smoothedBR = smoothedBR;
output.decreasedBlinking = decreasedFrames;
output.increasedBlinking = increasedFrames;
output.permBR_5thP = permBR_5thP;
output.permBR_95thP = permBR_95thP;
output.subjOrder = subjOrder;

%% Plots



