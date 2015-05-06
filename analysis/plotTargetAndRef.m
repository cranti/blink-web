function plotTargetAndRef(blinkPsthInputs, axesH, varargin)
%PLOTTARGETANDREF
%
% Plot target and reference events (from blinkPsthInputs) in an axis 
% (axesH).
%
% Each set is plotted on a "row", centered around an integer.
%
% Target events are plotted as blue circles, and reference events are
% plotted as black vertical lines. If there is only one reference set, it
% spans the entire y range. Otherwise, each reference set has a height of
% 1, and it is plotted on the same row as the corresponding target set.
%
% The x axis range and y axis range can be specified with parameter
% key/value pairs ('xrange' and 'yrange', as vectors with 2 numbers, a min
% and a max). 
%
% Can also specify the order that event sets are plotted ('sortby')
%   'original' - sorted in order of set identifier (default)
%   'ascending' - target sets with *fewer* events are on lower rows
%   'descending' - target sets with *more* events are on lower rows
%
% NOTES 
% > This only works when target and reference events are 1s and 0s (and
% NaNs) 
% > Using getPsthPlotSize for x and y ranges, and not doing any error
% checking for the optional range inputs. HOWEVER, if an "invalid" x or y
% range is passed in, it shouldn't error out.
% > Also, note that cbScrollPsth also uses getPsthPlotSize, and there are
% boundary checks in there.
%
% See also: GETPSTHPLOTSIZE, BLINKPSTHINPUTS, BLINKGUI, CBSCROLLPSTH

% Carolyn Ranti
% 4.23.15

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
    targetLens = cellfun(@length,targetEvents); 
    
    refEvents = blinkPsthInputs.refEvents;
    refOrder = blinkPsthInputs.refOrder; %to match to target
    refLens = blinkPsthInputs.refLens; %for figuring out xlim
    
    % if there are no targets or refs, quit
    if isempty(targetEvents) && isempty(refEvents)
        return
    end
    
    %% Parse varargin (set plot size and sort)

    %DEFAULT, from getPsthPlotSize - 10 event sets, 200 frames of data
    % (or whatever is possible given the length of the targets and refs)
    [def_xRange, def_yRange] = getPsthPlotSize(targetLens, refLens);
    minX = min(def_xRange);
    maxX = max(def_xRange);
    minY = min(def_yRange);
    maxY = max(def_yRange);
    
    %default sort = original
    sortby = 'original';
    
    % NB: no error checking here for x and y ranges
    for v = 1:2:length(varargin)
        switch lower(varargin{v})
            case 'xrange'
                minX = min(varargin{v+1});
                maxX = max(varargin{v+1});
            case 'yrange'
                minY = min(varargin{v+1});
                maxY = max(varargin{v+1});
            case 'sortby'
                if strcmpi(varargin{v+1}, 'original')
                    sortby = 'original';
                elseif strcmpi(varargin{v+1}, 'descend')
                    sortby = 'descend';
                elseif strcmpi(varargin{v+1}, 'ascend')
                    sortby = 'ascend';
                end
        end
    end
    

    %% Get ready to plot
    
    % Initialize things for title text
    titleText = {};
    targetTitle = blinkPsthInputs.targetTitle;
    refTitle = blinkPsthInputs.refTitle;

    % Keep track of whether we actually plotted anything
    plottedThings = 0;
    
    %% Plot target events
    if ~isempty(targetEvents)
        
        plottedThings = 1;
        
        % sort individuals according to parameter
        switch lower(sortby)
            case 'original'
                tOrder = 1:length(targetEvents);
            case 'descend' %highest density of events in lower rows
                numEvents = cellfun(@nansum, targetEvents);
                [~, tOrder] = sort(numEvents, 'descend');
            case 'ascend'
                numEvents = cellfun(@nansum, targetEvents);
                [~, tOrder] = sort(numEvents, 'ascend');
        end
        
        if iscolumn(tOrder)
            tOrder = tOrder';
        end
        
        %Create ytick and yticklabels
        yticks = [];
        yticklabels = [];
        
        %only plot the target events that are within the y range specified
        for y = (minY+.5):(maxY-.5) 
            
            %if this row exceeds the length of target data sets, just
            %continue
            if y>length(tOrder)
                continue
            end
            
            %get target events for this person
            t = tOrder(y);
            events = find(targetEvents{t}==1);
            
            %add to yticks
            yticks = [yticks, y];
            yticklabels = [yticklabels, targetOrder(t)];
            
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
                plot(axesH, [refs(ev), refs(ev)], [0, maxY], 'k');
            end
            
            % if target events don't exist, DON'T have any y ticks
            if isempty(targetEvents)      
                yticks = [];
                yticklabels = [];
            end
            
        % Plot multiple reference events as vertical lines that are 1 unit tall
        elseif length(refEvents) > 1
            
            %plot in original order, if targetEvents don't exist. Otherwise,
            %match targets and reference events
            if isempty(targetEvents)
                tOrder = 1:length(refEvents);
                
                %if there are no target events, yticks and yticklabels
                %haven't been set yet: initialize
                yticks = [];
                yticklabels = [];
            end
            
            for y = (minY+.5):(maxY-.5)
                
                %if there is no reference set for this row, continue 
                r = find(refOrder==tOrder(y));
                if isempty(r)
                    continue
                end
                
                % otherwise, get the appropriate ref set out of refEvents
                refs = refEvents{r};
                
                %set y range for each vertical line
                yrange = [y-.5, y+.5];
                
                % take out events too large/small to plot
                refs = refs(refs<=maxX & refs>=minX);
                
                %plot all the events
                for event = 1:length(refs)
                    plot(axesH, [refs(event), refs(event)], yrange, 'k');
                end
               
                
                %if there are no target events, yticks and yticklabels
                %haven't been set yet:
                if isempty(targetEvents)
                    yticks = [yticks, y];
                    yticklabels = [yticklabels, refOrder(r)];
                end
            end

        end
            

        
        
        % Add to title text
        titleText{end+1} = sprintf('REFERENCE: %s (black)', refTitle);
    end
    
    %% set axis limits and labels:

    %set y tick labels
    set(axesH, 'YTick', yticks, 'YTickLabel', yticklabels);

    %set axis limits
    ylim([minY, maxY]);
    xlim([minX, maxX]);
    
    %% Label plot
    if plottedThings
        title(titleText,'Interpreter','none');
        xlabel('Sample');
        ylabel('Set Number');
    end
    
catch ME
    err = MException('BlinkGUI:plotting','Error plotting target and reference events.');
    err = addCause(err, ME);
    throw(err);
end