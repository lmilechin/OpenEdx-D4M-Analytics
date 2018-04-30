function [A] = parseFile(fname,outlineName)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

if ~exist('newline')
    newline = char(10);
end

if ~isempty(outlineName)
    hasOutline = 1;
else
    hasOutline = 0;
end

% Get course outlines
allOutlines = struct([]);
if hasOutline
    fid=fopen(outlineName,'r');
    outline=fread(fid,'char=>char')';
    fclose(fid);
    
    outline=strsplit(outline,newline);
    outlines = cellfun(@loadjson,outline,'UniformOutput',false);
    allOutlines=struct();
    
    for i=1:length(outlines)
        o=outlines{i};
        allOutlines.(strrep(strrep(o.('root'),'block','course'),'+type@course+course@course','')) = o.('blocks');
    end
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

