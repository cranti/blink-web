
% options to provide:
%	1. compare individual target events to one set of reference events
%	2. compare individual target events to individual set of reference events
%	3. compare group of blinkers to another group of blinkers (same as 2?)
%	4. combine with perm testing stuff (this should be in a main script)
%	5. different kinds of outputs -- individuals vs. 
%
% TODO - figure out why vectors are being flipped...just keep everything horizontal, if possible
% input checking / error handling
%
% TODO - verify, document (see orig. script)


function output = CCmain()

%% Inputs

% read in 
% convert ref/target events with blink3ColConvert, if necessary

% INPUTS
% RefEvents = {[1 1 0 0 1 1 0 0]}; %cell vector --> assert that every entry must be a vector, all vectors must be same length
% RefCode = 1; %how is reference event defined?
% TargetEvents = {[0 1 1 0 0 1 1 0]}
% TargetCode = 1; %if it's empty, continuous measure
% lagMax = 30; %change name

% OPTIONAL - name/value pairs
%   'startFrame' (default = 1) - where to start 
%   'refEvent' (default = 'allFrames') - 'allFrames' (default) or
%           'firstFrameOnly'
%   'targetEvent' (default = 'allFrames') - 'allFrames' (default) or
%           'firstFrameOnly'
%

%% 


output = crossCorrel(refEvents,refCode,targetEvents,targetCode,lagMax,varargin);



%% graphs
