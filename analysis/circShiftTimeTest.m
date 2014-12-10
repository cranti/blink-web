output2=[];
for numFrames = 30*[30:30:1800]
    
    a= 1:numFrames;
    
    for numPerms = [1000]
        tic
        for b = 1:numPerms
            shift = randi(length(a));
            [a(shift:numFrames),a(1:(shift-1))];
        end
        time = toc;
        output2 = [output2;numFrames,numPerms,time];
    end
end