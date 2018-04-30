function [res] = cellContains(cellArray,str)
%UNTITLED10 Summary of this function goes here
%   Detailed explanation goes here

res = ~cellfun(@isempty,strfind(cellArray,str)) ;

end

