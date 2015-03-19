function plotTargetAndRef(blinkPsthInputs, axesH, varargin)
%PLOTTARGETANDREF
%
% Plot target and reference events (see blinkPSTH.m) in an axis (axsH)
%
% Function for blinkGUI.m

% TODO - document (pay attn to: input, xrange, etc)
% sortby option
% NOTE - this only works when target and reference events are 1s and 0s
% (and NaNs)


%%
try
    if nargin<2 || isempty(axesH)
        figure()
        axesH = gca;
    end
    hold(axesH,'on');
    
    % Get target and reference events out of blinkPsthInputs
    targetEvents = blinkPsthInputs.targetEvents;
    refEvents = blinkPsthInputs.refEvents;
    refSetLen = blinkPsthInputs.refSetLen; %for figuring out xlim
    
    % Initialize things for title text
    titleText = {};
    targetTitle = blinkPsthInputs.targetTitle;
    refTitle = blinkPsthInputs.refTitle;
    
    
    % Keep track of whether we actually plotted anything
    plottedThings = 0;
    
    %% Figure out xrange
    
    %get maximum size of target events and maximum reference event:
    if ~isempty(targetEvents)
        maxX = max(cellfun(@length,targetEvents));
    elseif ~isempty(refEvents)
        maxX = max(refSetLen);
    end
    
    %default:
    minX = 1;
    maxX = min(maxX, 200);
    sortby = 'original';
    inds = [];
    
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
            case 'inds'
                inds = varargin{v+1};
        end
    end
    
    
    %% Plot target events
    if ~isempty(targetEvents)
        
        plottedThings = 1;
        
        %only plot some of the individuals, if that option was passed in:
        if ~isempty(inds)
            targetEvents = targetEvents(inds);
        end
        
        % sort individuals according to parameter
        if strcmpi(sortby, 'original')
            tOrder = 1:length(targetEvents);
        elseif strcmpi(sortby, 'descend')
            numEvents = cellfun(@nansum, targetEvents);
            [~, tOrder] = sort(numEvents, 'descend');
        elseif strcmpi(sortby, 'ascend')
            numEvents = cellfun(@nansum, targetEvents);
            [~, tOrder] = sort(numEvents, 'ascend');
        end
        
        if iscolumn(tOrder)
            tOrder = tOrder';
        end
        
        for ii = 1:length(targetEvents)
            t = tOrder(ii);
            
            events = find(targetEvents{t}==1) + minX - 1;
            
            %take out events too large/small to plot:
            events = events(events<=maxX);
            events = events(events>=minX);
            
            %plot target event set on its own row:
            nEvents = length(events);
            plot(axesH, events, t*ones(1,nEvents), 'bo');
        end
        
        xlim([minX, maxX]);
        
        % Add to title text
        titleText{end+1} = sprintf('TARGET: %s',targetTitle);
        
    end
    
    %% Plot reference events
    if ~isempty(refEvents)
        
        plottedThings = 1;
        
        %only plot some of the individuals, if that option was passed in:
        if ~isempty(inds)
            refEvents = refEvents(inds);
        end
        
        % Plot 1 reference event as vertical lines spanning height of graph
        if length(refEvents) == 1
            
            %get size of y axis
            yrange = ylim(axesH);
            
            %take out references too large/small to plot
            refs = refEvents{1};
            refs = refs(refs<=maxX);
            refs = refs(refs>=minX);
            
            %for each event
            for ev = 1:length(refs)
                plot(axesH, [refs(ev), refs(ev)], yrange, 'k');
            end
            
        % Plot multiple reference events as vertical lines that are 1 unit tall
        elseif length(refEvents) > 1
            
            %plot in original order, if targetEvents don't exist. Otherwise,
            %match targets and reference events
            if isempty(targetEvents)
                rOrder = 1:length(refEvents);
            else
                rOrder = tOrder;
            end
            
            for ii = 1:length(refEvents)
                r = rOrder(ii);
                
                %take out events too large/small to plot
                refs = refEvents{r};
                refs = refs(refs<=maxX);
                refs = refs(refs>=minX);
                
                yrange = [r-.5, r+.5];
                for event = 1:length(refs)
                    plot(axesH, [refs(event), refs(event)], yrange, 'k');
                end
            end
            
            ylim([0, max(rOrder)+.5]);
            
        end
        
        xlim([minX, maxX]);
        
        % Add to title text
        titleText{end+1} = sprintf('REFERENCE: %s', refTitle);
    end
    
    %% Label plot
    if plottedThings
        title(titleText,'Interpreter','none');
        xlabel('Sample #');
        ylabel('Individual');
    end
    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting target and reference events.');
    err = addCause(err, ME);
    throw(err);
end