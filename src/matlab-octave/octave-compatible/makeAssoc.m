function [A] = makeAssoc(fname,clickCell,allOutlines)
%UNTITLED9 Summary of this function goes here
%   Detailed explanation goes here

if ~exist('newline')
    newline = char(10);
end

clickCell(cellContains(clickCell,'"page_close"'))=[];
clickCell(cellContains(clickCell,'"username": "",'))=[];
clickCell=strrep(clickCell,', "page": null','');


logStructs = cellfun(@loadjson,clickCell,'UniformOutput',false);

logcols = cellfun(@(x) makecols(x,allOutlines,''),logStructs,'UniformOutput',false);

if ~isempty(logcols)
    lens = num2cell(cellfun(@NumStr,logcols));

    linenums = num2str((1:length(logStructs))','%04i');
    rIDs = cellstr([repmat([fname(14:end) '_'],size(linenums,1),1) linenums]);

    rIDs = cellfun(@(x,y) repmat([x newline],1,y), rIDs, lens','UniformOutput',false);

    rIDs = strjoin(rIDs,'');
    cIDs = strjoin(logcols,'');

    A = Assoc(rIDs, cIDs, 1);
else
    A = Assoc('','','');
end

end

