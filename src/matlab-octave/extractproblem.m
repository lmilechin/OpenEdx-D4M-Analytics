function [eventcols,event] = extractproblem(event)
%extractproblem parses out problem events
%   Given the "event" struct, parses out the fields of interest. Returns
%   the string of column keys and the remaining fields of the event struct

global newline;

% Remove uninteresting fields
event = rmfield(event,'state'); % not useful?
event = rmfield(event,'answers'); % info in submission

% Extract interesting fields and remove them from the struct
submission = event.('submission'); 
event = rmfield(event,'submission');
correct_map = event.('correct_map');
event = rmfield(event,'correct_map');
problem_id_long = event.('problem_id');
event = rmfield(event,'problem_id');

% Parse out the "submission" struct
eventcols = '';
prob_id = '';
keys = fieldnames(submission);
for i=1:length(keys)
    key = keys{i};
    full_id = strsplit(key,'_');
    sub_id = strjoin(full_id(2:3),'_');
    keys2 = fieldnames(submission.(key));
    for j = 1:length(keys2)
        key2 = keys2{j};
        if ~isempty(submission.(key).(key2))
            if isa(submission.(key).(key2),'logical')
                logstr = {'false','true'};
                val = logstr{submission.(key).(key2)+1};
            elseif isa(submission.(key).(key2),'cell')
                val = strjoin(submission.(key).(key2),[newline 'event_' key2 '_' sub_id '|']);
            else
                val = char(submission.(key).(key2));
            end
            
            eventcols = [eventcols 'event_' key2 '_' sub_id '|' val newline];
        end
    end
    if length(prob_id)<1
        prob_id = full_id{1};
    end
end
eventcols = [eventcols 'event_problem_id|' prob_id newline 'event_problem_id_long|' problem_id_long newline];

% Parse out "correct_map"
keys = fieldnames(correct_map);
for i=1:length(keys)
    key = keys{i};
    full_id = strsplit(key,'_');
    sub_id = strjoin(full_id(2:3),'_');
    keys2 = fieldnames(correct_map.(key));
    for j=1:length(keys2)
        key2 = keys2{j};
        if ~isempty(correct_map.(key).(key2)) && ~isa(correct_map.(key).(key2),'struct')
            eventcols = [eventcols 'event_' key2 '_' sub_id '|' char(correct_map.(key).(key2)) newline];
        end
    end
end

end

