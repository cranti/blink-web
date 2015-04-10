function plotTargetAndRef(blinkPsthInputs, axesH, varargin)
%PLOTTARGETANDREF
%
% Plot target and reference events (see blinkPSTH.m) in an axis (axsH)
%
% Function for blinkGUI.m

% TODO - document (pay attn to: input, xrange, etc)
% sortby option (esp for 3 column format -- input order?)

% NOTES 
% > This only works when target and reference events are 1s and 0s (and
% NaNs) 
% > The overall min/max values for things are hard coded - must match
% scrolling script

%%
try
    if nargin<2 || isempty(axesH)
        figure()
        axesH = gca;
    end
    hold(axesH,'on');
    
    % Get target and reference events out of blinkPsthInputs
    targetEvents = blinkPsthInputs.targetEvents;
    targetOrder = blinkPsthInputs.targetOrder; %to figure out ylabels
    
    refEvents = blinkPsthInputs.refEvents;
    refLens = blinkPsthInputs.refLens; %for figuring out xlim
    
    % Initialize things for title text
    titleText = {};
    targetTitle = blinkPsthInputs.targetTitle;
    refTitle = blinkPsthInputs.refTitle;

    % Keep track of whether we actually plotted anything
    plottedThings = 0;
    
    %% Parse out varargin
    
    %get maximum size of target events and maximum reference event:
    if ~isempty(targetEvents)
        dataMaxX = max(cellfun(@length,targetEvents));
        dataMaxY = length(targetEvents)+.5;
    elseif ~isempty(refEvents)
        dataMaxX = max(refLens);
        dataMaxY = length(refEvents)+.5;
    else
        return
    end
    
    %default: (this must match hard-coded values in cbScrollPsth)
    minX = 0;
    maxX = min(dataMaxX, 200);
    minY = .5; 
    maxY = min(10.5, dataMaxY);
    sortby = 'original';
    
    
    for v = 1:2:length(varargin)
        switch lower(varargin{v})
            case 'xrange'
                minX = min(varargin{v+1});
                maxX = max(varargin{v+1});
            case 'sortby'
                if strcmpi(varargin{v+1}, 'original')
                    sortby = 'original';
                elseif strcmpi(varargin{v+1}, 'descend')
                    sortby = 'descend';
                elseif strcmpi(varargin{v+1}, 'ascend')
                    sortby = 'ascend';
                end
            case 'yrange'
                minY = min(varargin{v+1});
                minY = max(minY,.5);
                
                maxY = max(varargin{v+1});
                %TODO - make this all match (in Xs and maxY)
        end
    end

    
    %% Plot target events
    if ~isempty(targetEvents)
        
        plottedThings = 1;
        
        % sort individuals according to parameter
        switch lower(sortby)
            case 'original'
                tOrder = 1:length(targetEvents);
            case 'descend' %"descending" --> i actually want 
                numEvents = cellfun(@nansum, targetEvents);
                [~, tOrder] = sort(numEvents, 'descend');
            case 'ascend'
                numEvents = cellfun(@nansum, targetEvents);
                [~, tOrder] = sort(numEvents, 'ascend');
        end
        
        if iscolumn(tOrder)
            tOrder = tOrder';
        end
        
        %only plot the target events that are within the y range specified
        for y = (minY+.5):(maxY-.5) 
            
            %get target events for this person
            t = tOrder(y);
            events = find(targetEvents{t}==1);
            
            %take out events too large/small to plot:
            events = events(events<=maxX & events>=minX);
            
            %each target set gets its own row:
            allY = y*ones(1, length(events));
            
            %actually plot it
            plot(axesH, events, allY, 'bo');
        end
        
        % Add to title text
        titleText{end+1} = sprintf('TARGET: %s (blue)',targetTitle);
        
    end
    
    %% Plot reference events
    if ~isempty(refEvents)
        
        plottedThings = 1;
        
        % Plot 1 reference event as vertical lines spanning height of graph
        if length(refEvents) == 1
            
            refs = refEvents{1};
            
            %take out references too large/small to plot
            refs = refs(refs<=maxX & refs>=minX);
            
            %for each event
            for ev = 1:length(refs)
                plot(axesH, [refs(ev), refs(ev)], [0, dataMaxY], 'k');
            end
            
        % Plot multiple reference events as vertical lines that are 1 unit tall
        elseif length(refEvents) > 1
            
            %plot in original order, if targetEvents don't exist. Otherwise,
            %match targets and reference events
            if isempty(targetEvents)
                tOrder = 1:length(refEvents);
            end
            
            for y = (minY+.5):(maxY-.5)
                
                % get this set of reference events
                r = tOrder(y);
                refs = refEvents{r};
                
                %set y range for each vertical line
                yrange = [r-.5, r+.5];
                
                % take out events too large/small to plot
                refs = refs(refs<=maxX & refs>=minX);
                
                %plot all the events
                for event = 1:length(refs)
                    plot(axesH, [refs(event), refs(event)], yrange, 'k');
                end
            end

        end

        % Add to title text
        titleText{end+1} = sprintf('REFERENCE: %s (black)', refTitle);
    end
    
    %% set axis limits and labels:

    %set ytick and ytick label
    yticks = 1:dataMaxY;
    yticklabels = targetOrder(tOrder);
    set(axesH, 'YTick', yticks, 'YTickLabel', yticklabels);

    %set axis limits
    ylim([minY, maxY]);
    xlim([minX, maxX]);
    
    %% Label plot
    if plottedThings
        title(titleText,'Interpreter','none');
        xlabel('Sample #');
        ylabel('Target Participant');
    end
    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting target and reference events.');
    err = addCause(err, ME);
    throw(err);
end