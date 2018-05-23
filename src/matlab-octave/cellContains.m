function [res] = cellContains(cellArray,str)
%cellContains determines which cells in a  cell array contain a particular string
%   Takes in a cell array of strings, and a string.
%   Ouputs a logical vector, with 1's indicating the indices of the cells
%   that contain the queried string.

global isOctave;

if isOctave % Octave does not have a built in function to do this
    res = ~cellfun(@isempty,strfind(cellArray,str));
else % use Matlab's built in function
    res = contains(cellArray,str);
end

end