%CCMAIN
%
% options to provide:
%	1. compare individual target events to one set of reference events
%	2. compare individual target events to individual set of reference events
%	3. compare group of blinkers to another group of blinkers (same as 2?)
%	4. different kinds of outputs -- individuals vs. 
%
%
% TODO 
% - figure out why vectors are being flipped...just keep everything
% horizontal, if possible??
% - permutation testing
% - verify, document (see orig. script)
% - input checking/error handling
% - think about what to pass in for sampleLen if using the 3col format. **Change
% PTmain to match whatever the logic is here **
% - think about plots
% - think about how to provide output to user

function output = CCmain(refEvents, refCode, targetEvents, targetCode, lagMax, sampleLen, varargin)

% try 
    %% Prep refEvents and targetEvents

    if ~isempty(sampleLen) && sampleLen>0
        [refEvents, ~] = blink3ColConvert(refEvents, sampleLen);
        [targetEvents, ~] = blink3ColConvert(targetEvents, sampleLen);
    end

    %%
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
    %   'autoCrossCorr'  0 (default) or 1.  Should be true if the target 
    %           individuals are being compared to everyone else in the group
    %           (i.e. if you're passing in the same values for refEvents and
    %           targetEvents)
    % 


    %% 

    output = crossCorrelogram(refEvents,refCode,targetEvents,targetCode,lagMax); %TODO - pass in varargin

    %% permutation testing

% catch ME
%     output.error = ME;
% end