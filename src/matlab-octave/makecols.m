function [cols] = makecols(logline,allOutlines,prefix)
%makecols creates column keys for event data
%   Given a struct containing log data, struct of outlines, and prefix
%   for the column key, produces a string containing all the column keys

global isOctave;
global newline;

cols='';
toplevel = isfield(logline,'event_type');

% Remove uninteresting fields
if isfield(logline,'agent')
    logline = rmfield(logline,'agent');
end
if isfield(logline,'accept_language')
    logline = rmfield(logline,'accept_language');
end
if toplevel && strcmp(logline.('event_type'),'problem_graded') && strcmp(logline.('event_source'),'browser')
    logline = rmfield(logline,'event');
end

% Remove event field for "POST/GET" events (these are not explicit events)
if isfield(logline,'event') && isa(logline.('event'),'char') && any(strfind(logline.('event'),'POST'))
    logline = rmfield(logline,'event');

% Try to parse events that may not have parsed the first time
elseif isfield(logline,'event') && isa(logline.('event'),'char') && any(strfind(logline.('event'),'{'))
    try
        if isOctave
            logline.('event')=loadjson(logline.('event'));
        else
            logline.('event')=jsondecode(logline.('event'));
        end
    catch err
        disp(['Could not parse: ' logline.('event')])
    end
end

% Parse problem event
if toplevel && strcmp(logline.('event_type'),'problem_check') && strcmp(logline.('event_source'),'server')
    [probcols,logline.('event')] = extractproblem(logline.('event'));
    cols = [cols probcols newline];
end

% Prepare to parse urls for module/section names and locations
currPage = '';
if toplevel
    if isOctave
        courseID = logline.('context').('course_id');%genvarname(logline.('context').('course_id'));
    else
        courseID = matlab.lang.makeValidName(logline.('context').('course_id'));
    end
end

% Parse nagivigation events: If: event_type == context_path AND (host event_type) ~= referer, this is a navigation event
if toplevel && isfield(logline.('context'),'path') ...
        && strcmp(logline.('event_type'),logline.('context').('path')) ...
        && ~any(strfind(logline.('event_type'),'handler')) ...
        && ~strcmp(['https://' logline.('host') logline.('event_type')],logline.('referer'))
    currPage = ['https://' logline.('host') logline.('context').('path')];
    lastPage = logline.('referer');
    logline.('event_type') = 'navigation';
    logline.('context').('path') = currPage;
    
    % Grab module/section names and course location previous/current page if both in courseware (to make course navigation graph)
    if incourseware(lastPage,logline) && incourseware(currPage,logline) && isfield(allOutlines,courseID)
        [modName,secName,courseLoc] = extractnames(lastPage,allOutlines);
        cols = [cols 'last_module_name|' modName newline];
        cols = [cols 'last_section_name|' secName newline];
        cols = [cols 'last_course_loc|' courseLoc newline];
        
        [modName,secName,courseLoc] = extractnames(currPage,allOutlines);
        cols = [cols 'new_module_name|' modName newline];
        cols = [cols 'new_section_name|' secName newline];
        cols = [cols 'new_course_loc|' courseLoc newline];
    end

% If it's not a navigation event, the current page can be gotten from the referrer
elseif isfield(logline,'referer')
    currPage = logline.('referer');
end

% Grab the module/section names and course location if current page is in courseware
if toplevel && incourseware(currPage,logline) && ~isempty(allOutlines) && isfield(allOutlines,courseID) %haskey(logline,'event_type') && contains(currPage,logline('context')('course_id')*'/courseware/') && !contains(currPage,'loglinein')
    [modName,secName,courseLoc] = extractnames(currPage,allOutlines);
    cols = [cols 'module_name|' modName newline];
    cols = [cols 'section_name|' secName newline];
    cols = [cols 'course_loc|' courseLoc newline];
end

% Parse remaining fields
keys = fieldnames(logline);
for i=1:length(keys)
    key = keys{i};
    
    % If field is a scalar (single) character or number, just add it
    if (isa(logline.(key),'char') || isa(logline.(key),'double')) && ~isempty(logline.(key))
        if isa(logline.(key),'double')
            logline.(key) = num2str(logline.(key));
        end
        cols = [cols prefix key '|' strrep(char(logline.(key)),newline,'') newline];

    % If field is a non-empty array, add each element
    elseif length(logline.(key))>1 && ~isempty(logline.(key))
        if ~isa(logline.(key)(1),'struct')
            newstr = strjoin(replace(logline.(key),newline,''),[newline prefix key '|']);
            cols = [cols prefix key '|' newstr newline];
        else
            disp('array of structs not currently supported')
        end
    % If field is a struct, recursively call makecols on the struct
    elseif isa(logline.(key),'struct')
        cols = [cols makecols(logline.(key),allOutlines,[prefix key '_'])];
    end
    
end

% Add newline to end of cols if it is missing
if ~isempty(cols) && cols(end)~=newline
    cols = [cols newline];
end


end