function [incourse] = incourseware(URL,logline)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
URLparts = split(URL,'/');
incourse = (isfield(logline,'context') ...
    && isfield(logline.('context'),'course_id') ...
    && contains(URL,[logline.('context').('course_id') '/courseware/']) ...
    && ~contains(URL,'login') && length(URLparts)>7);
end

