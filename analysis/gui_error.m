% 
% create an error dialogue window, and log the error if there is a log file 
% 
% Pass in MException and the name of an error_log file

function gui_error(ME, error_log)
    
    % Show the error in a modal dlg box
    w = errordlg(ME.message, 'Error', 'modal');
    
    % Print to error log, if it's available
    if nargin==1 || isempty(error_log)
        fid = -1;
    else
        fid = fopen(error_log,'a');
    end
        
    if fid<=0
        warndlg('Error log file not found!')
    else
        
        fprintf(fid,'%s\t',datestr(now));
        fprintf(fid,'%s\n',ME.message);
        
        %PRINT STACK
        %if there is a cause, print that stack (which is actually what I care about)
        if ~isempty(ME.cause) 
            stack = ME.cause{1}.stack;
            fprintf(fid,'Cause:\t%s\n',ME.cause{1}.message);
            
        % Otherwise, print the stack from the exception
        else
            stack = ME.stack;
        end
     
        for i = 1:length(stack)
            fprintf(fid, '\tLine %i\t%s\t%s\n', stack(i).line, stack(i).name, stack(i).file);
        end
        
        fprintf(fid,'\n');
        fclose(fid);
    end
    
    % wait for the user to close the error
    uiwait(w);
end

