function [A] = parseFile(fname,outlineName)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

% Get course outlines
fid=fopen(outlineName,'r');
outline=fread(fid,'char=>char')';
fclose(fid);

outline=split(outline,newline);
outlines = cellfun(@jsondecode,outline,'UniformOutput',false);

allOutlines = struct();
for i=1:length(outlines)
    o=outlines{i};
    allOutlines.(matlab.lang.makeValidName(replace(replace(o.('root'),'block','course'),'+type@course+course@course',''))) = o.('blocks');
end

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
