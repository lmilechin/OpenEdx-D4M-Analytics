function [incourse] = incourseware(URL,logline)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
URLparts = strsplit(URL,'/');
incourse = (isfield(logline,'context') ...
    && isfield(logline.('context'),'course_id') ...
    && strfind(URL,[logline.('context').('course_id') '/courseware/']) ...
    && ~strfind(URL,'login') && length(URLparts)>7);
end

