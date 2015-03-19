%join a directory and a filename -- TODO look at how other systems
%define pathnames. May want this in a separate file, actually
function fullpath = dirFileJoin(dirname, filename)
    if strcmp(dirname(end),'/')
        fullpath = [dirname,filename];
    else
        fullpath = [dirname,'/',filename];
    end
end
