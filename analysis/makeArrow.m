function arrow = makeArrow(w, h, dir, bor, fc, bc)
%MAKEARROW 
%
% w     width
% h     height
% dir   direction ('right', 'left', 'up', 'down')
% bor   border ([width, height])
% fc    foreground color (color of arrow)
% bc    background color (color around arrow)

%% border
if nargin<4
   bor = [0, 0]; 
end

borW = bor(1);
borH = bor(2);

w = w-2*borW;
h = h-2*borH;

%% Colors - default = black arrow, white background
if nargin<6
   fc = [0 0 0]; %foreground color
   bc = [1 1 1]; %background color
end

%% if up or down, switch things...
if strcmpi(dir, 'up') || strcmpi(dir, 'down')
    %width and height
    oldW = w;
    w = h;
    h = oldW;
    
    %swap border
    borW = bor(2);
    borH = bor(1);
end


%% right facing arrow
arrow = ones(h, w, 3);
arrow(:,:,1) = bc(1);
arrow(:,:,2) = bc(2);
arrow(:,:,3) = bc(3);

%head center
headC = ceil(h/2);

for c = w:-1:(w-headC+1)
    
    rows = (headC - (w-c)):(headC + (w-c));
    
    arrow(rows,c,1) = fc(1);
    arrow(rows,c,2) = fc(2);
    arrow(rows,c,3) = fc(3);
end


%stem size = ~1/3 height (centered)
stemBordH = floor(1/3*h); 

%add stem
arrow((stemBordH+1):(end-stemBordH), 1:(w-headC), 1) = fc(1);
arrow((stemBordH+1):(end-stemBordH), 1:(w-headC), 2) = fc(2);
arrow((stemBordH+1):(end-stemBordH), 1:(w-headC), 3) = fc(3);


%% add border back
if borH>0 || borW>0
    origArrow = arrow;

    arrow = ones(h+2*borH, w+2*borW, 3);
    arrow(:,:,1) = bc(1);
    arrow(:,:,2) = bc(2);
    arrow(:,:,3) = bc(3);

    arrow((borH+1):(borH+h), (borW+1):(borW+w), :) = origArrow;
end

%% Set direction
switch dir
    case 'left'
        arrow = fliplr(arrow);
    case 'down'
        arrow = permute(arrow, [2 1 3]); %transpose
    case 'up'
        arrow = fliplr(arrow);
        arrow = permute(arrow, [2 1 3]);
end

