function [A] = parseFile(fname,allOutlines)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

global newline;

% Get log file
fid=fopen(fname,'r');
clickstream=fread(fid,'char=>char')';
fclose(fid);

clickCell=strsplit(clickstream,newline);
if strcmp(clickCell{end},'')
    clickCell=clickCell(1:end-1);
end

A = makeAssoc(fname,clickCell,allOutlines);
end

