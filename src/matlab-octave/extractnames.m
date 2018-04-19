function [modName,secName,courseLoc] = extractnames(url,allOutlines)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

url = split(url,'/');
courseID = url{5};
courseID_key = matlab.lang.makeValidName(courseID);



modID =  [replace(courseID,'course','block') '+type@chapter+block@' url{7}];
secID =  [replace(courseID,'course','block') '+type@sequential+block@' url{8}];
modID_key =  matlab.lang.makeValidName(modID);
secID_key =  matlab.lang.makeValidName(secID);
courseIDfull =  matlab.lang.makeValidName([replace(courseID,'course','block') '+type@course+block@course']);

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

