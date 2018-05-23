function [modName,secName,courseLoc] = extractnames(url,allOutlines)
%extractnames Finds the section and module names for the given url
%   Given a url and a struct of course outlines, extractnames finds extracts
%   the module and section IDs from the url and finds them in the struct of
%   outlines containing their names. Also generates a string indicating the
%   sequential location in the course: the first three characters indicate the
%   module index, the second the section index within that module.

global isOctave;

% Split up the URL and find the course ID
url = strsplit(url,'/');
courseIdx = find(cellContains(url,'courseware'))-1;
courseID = url{courseIdx};
if isOctave
    courseID_key = courseID;
else
    courseID_key = matlab.lang.makeValidName(courseID);
end
courseFields = fieldnames(allOutlines.(courseID_key));

% Find module and section fieldnames
if isOctave
    modIdx = find(cellContains(courseFields, url{courseIdx+2}));
    secIdx = find(cellContains(courseFields, url{courseIdx+3}));
    modID =  [strrep(courseID,'course','block') '+type@chapter+block@' url{courseIdx+2}];
    secID =  [strrep(courseID,'course','block') '+type@sequential+block@' url{courseIdx+3}];
    modID_key =  courseFields{modIdx};
    secID_key =  courseFields{secIdx};
    courseIDfull =  courseFields{cellContains(courseFields, 'course')};
else
    modID =  [replace(courseID,'course','block') '+type@chapter+block@' url{courseIdx+2}];
    secID =  [replace(courseID,'course','block') '+type@sequential+block@' url{courseIdx+3}];
    modID_key =  matlab.lang.makeValidName(modID);
    secID_key =  matlab.lang.makeValidName(secID);
    courseIDfull =  matlab.lang.makeValidName([replace(courseID,'course','block') '+type@course+block@course']);
end

% Get module and section display names
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

% Build course location string
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

