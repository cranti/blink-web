function plotTargetAndRef(targetEvents, refEvents, axesH, titleText)
%PLOTTARGETANDREF
%
% Plot target and reference events (see blinkPSTH.m) in an axis (axsH)
%
% TODO - what should I do for continuous measures/more than one reference
% set? or what if it's continuous AND there are multiple reference sets?
% (maybe different colors?)



if nargin<3 || isempty(axesH)
    figure()
    axesH = gca;
end
hold(axesH,'on');

%% Plot target events
if ~isempty(targetEvents)
    
    for t = 1:length(targetEvents)
        events = find(targetEvents==1); %TODO what to do for continuous measure?
        nEvents = length(events);
        plot(axesH, events, t*ones(1,nEvents), 'bo');
    end
    
end

%% Plot reference events
if ~isempty(refEvents)    
    
    %get size of y axis
    yrange = ylim(axesH);
    
    if length(refEvents) == 1
        refs = refEvents{1};
        for r = 1:length(refs)
           plot(axesH, [refs(r), refs(r)], yrange, 'k'); 
        end
    else
        % TODO - how to plot if each person has a different set of reference
        % events?
        warning('Currently cannot plot multiple reference sets');
    end
    
   %plot(targetEvents) 
end


if nargin < 4 || isempty(titleText)
	title('Instantaneous Blink Rate');
else
	title({'Instantaneous Blink Rate',titleText{:}},'Interpreter','none'); 
end



%% Label plot
if nargin < 4 || isempty(titleText)
	title('Target and Reference Events');
else
	title({'Target and Reference Events',titleText{:}},'Interpreter','none'); 
end
xlabel('Sample #');
ylabel('Individual');

end