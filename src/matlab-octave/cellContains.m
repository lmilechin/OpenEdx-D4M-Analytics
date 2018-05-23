function [res] = cellContains(cellArray,str)
%UNTITLED10 Summary of this function goes here
%   Detailed explanation goes here

isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;

if isOctave
    res = ~cellfun(@isempty,strfind(cellArray,str));
else
    res = contains(cellArray,str);
end

end

