function [incourse] = incourseware(URL,logline)
%incourseware indicates whether the given URL is in the courseware
%   Given a string URL and the current line of the log that is being
%   parsed, determines whether the event occurred in the courseware

URLparts = strsplit(URL,'/');
incourse = (isfield(logline,'context') ... % make sure context is a field
    && isfield(logline.('context'),'course_id') ... % make sure coruse_ID is a field
    && any(strfind(URL,[logline.('context').('course_id') '/courseware/'])) ... % check if url contains COURSEID/courseware
    && isempty(strfind(URL,'login')) ... % make sure url doesn't contain "login"
    && length(URLparts)>7); % make sure the url contains the module and section IDs
end