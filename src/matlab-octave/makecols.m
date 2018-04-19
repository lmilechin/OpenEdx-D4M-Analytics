function [cols] = makecols(logline,allOutlines,prefix)
    
    cols='';
    
    if isfield(logline,'agent')
        logline = rmfield(logline,'agent');
    end
    if isfield(logline,'accept_language')
        logline = rmfield(logline,'accept_language');
    end
    
    toplevel = isfield(logline,'event_type');
    
    if toplevel && strcmp(logline.('event_type'),'problem_graded') && strcmp(logline.('event_source'),'browser')
        logline = rmfield(logline,'event');
    end
    
    if isfield(logline,'event') && isa(logline.('event'),'char') && contains(logline.('event'),'POST')
        logline = rmfield(logline,'event');
    elseif isfield(logline,'event') && isa(logline.('event'),'char') && contains(logline.('event'),'{')
        try
            logline.('event')=jsondecode(logline.('event'));
        catch err
            disp(['Could not parse: ' logline.('event')])
        end
    end
    
    if toplevel && strcmp(logline.('event_type'),'problem_check') && strcmp(logline.('event_source'),'server')
        [probcols,logline.('event')] = extractproblem(logline.('event'));
        cols = [cols probcols newline];
    end
    
    currPage = '';
    
    % If: event_type == context_path AND (host event_type) ~= referer, this is a navigation event
    if toplevel && isfield(logline.('context'),'path') ...
            && strcmp(logline.('event_type'),logline.('context').('path')) ...
            && ~contains(logline.('event_type'),'handler') ...
            && ~strcmp(['https://' logline.('host') logline.('event_type')],logline.('referer'))
        currPage = ['https://' logline.('host') logline.('event_type')];
        lastPage = logline.('referer');
        logline.('event_type') = 'navigation';
        logline.('context').('path') = currPage;

        if incourseware(lastPage,logline) && incourseware(currPage,logline)%(contains(lastPage,logline('context')('course_id')*'/courseware/') && !contains(lastPage,'loglinein')) && 
            %(contains(currPage,logline('context')('course_id')*'/courseware/') && !contains(currPage,'loglinein'))
            [modName,secName,courseLoc] = extractnames(lastPage,allOutlines);
            cols = [cols 'last_module_name|' modName newline];
            cols = [cols 'last_section_name|' secName newline];
            cols = [cols 'last_course_loc|' courseLoc newline];
            
            [modName,secName,courseLoc] = extractnames(currPage,allOutlines);
            cols = [cols 'new_module_name|' modName newline];
            cols = [cols 'new_section_name|' secName newline];
            cols = [cols 'new_course_loc|' courseLoc newline];
        end
        
    elseif isfield(logline,'referer')
        currPage = logline.('referer');
    end

    if toplevel && incourseware(currPage,logline) %haskey(logline,'event_type') && contains(currPage,logline('context')('course_id')*'/courseware/') && !contains(currPage,'loglinein')
        [modName,secName,courseLoc] = extractnames(currPage,allOutlines);
        cols = [cols 'module_name|' modName newline];
        cols = [cols 'section_name|' secName newline];
        cols = [cols 'course_loc|' courseLoc newline];
    end
    
    keys = fieldnames(logline);
    for i=1:length(keys)%key in keys(logline)
        key = keys{i};
        
        if (isa(logline.(key),'char') || isa(logline.(key),'double')) && ~isempty(logline.(key))
            if isa(logline.(key),'double')
                logline.(key) = num2str(logline.(key));
            end
            cols = [cols prefix key '|' replace(char(logline.(key)),newline,'') newline];
        elseif length(logline.(key))>1 && ~isempty(logline.(key))
            if ~isa(logline.(key)(1),'struct')
                newstr = strjoin(replace(logline.(key),newline,''),[newline prefix key '|']);
                cols = [cols prefix key '|' newstr newline];
            else
                disp('this not done yet')
                %cols = (cols join(join(makecols(logline(key),prefix*key*'_'))))
            end
        elseif isa(logline.(key),'struct')
            cols = [cols makecols(logline.(key),allOutlines,[prefix key '_'])];
        end
        
    end
    
    if ~isempty(cols) && cols(end)~=newline
        cols = [cols newline];
    end
    
    
end