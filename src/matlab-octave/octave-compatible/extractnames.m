function [modName,secName,courseLoc] = extractnames(url,allOutlines)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

url = 'https://bwedx.mit.edu/courses/course-v1:LLx+LLX03+Q3_2016/courseware/02b2117125de4bb6a723f55df5190037/d13ed24b30c547a3865082602a060e92/';

if ~exist('newline')
    newline = char(10);
end

url = strsplit(url,'/');
courseIdx = find(cellContains(url,'courseware'))-1;
courseID = url{courseIdx};
courseID_key = genvarname(courseID);

courseFields = fieldnames(allOutlines.(courseID_key));

modIdx = find(cellContains(courseFields, url{courseIdx+2}));
secIdx = find(cellContains(courseFields, url{courseIdx+3}));
modID =  [strrep(courseID,'course','block') '+type@chapter+block@' url{courseIdx+2}];
secID =  [strrep(courseID,'course','block') '+type@sequential+block@' url{courseIdx+3}];
modID_key =  courseFields{modIdx};
secID_key =  courseFields{secIdx};
courseIDfull =  courseFields{cellContains(courseFields, 'course')};
genvarname([strrep(courseID,'course','block') '+type@course+block@course']);

if isfield(allOutlines.(courseID_key),modID_key)
    modName = allOutlines.(courseID_key).(modID_key).('display_name');
else
    modName = 'unknown';
end
if isfield(allOutlines.(courseID_key),secID_key)
    secName = allOutlines.(courseID_key).(secID_key).('display_name');
else
    secName = 'unknown';
end

if strcmp(secName,'unknown') || strcmp(modName,'unknown')
    courseLoc = '000.000';
else
    modOrder = allOutlines.(courseID_key).(courseIDfull).('children');
    secOrder = allOutlines.(courseID_key).(modID_key).('children');
    modLoc = find(strcmp(modOrder,modID));
    secLoc = find(strcmp(secOrder,secID));
    
    if isempty(modLoc) || isempty(secLoc)
        courseLoc = '000.000';
    else
        courseLoc = [num2str(modLoc(1),'%03i') '.' num2str(secLoc(1),'%03i')];
    end
    
end

end

