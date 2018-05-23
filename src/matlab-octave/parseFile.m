function [A] = parseFile(fname,allOutlines)
%parseFile parse file into associative array
%   Given a filename and struct of course outlines, reads
%   in file of event data, splits into cell array, and creates
%   associative array.

global newline;

% Read in log file
fid=fopen(fname,'r');
clickstream=fread(fid,'char=>char')';
fclose(fid);

% Split into cell array
clickCell=strsplit(clickstream,newline);
if strcmp(clickCell{end},'')
    clickCell=clickCell(1:end-1);
end

% Create associative array
A = makeAssoc(fname,clickCell,allOutlines);

end

