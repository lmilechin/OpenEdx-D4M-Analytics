function [A] = makeAssoc(fname,clickCell,allOutlines)
%makeAssoc constructs the associative array with data from the log file
%   Given the filename (used to create the rowIDs), cell of clickstream data,
%   and struct of outlines, parses clickstream data, forms row IDs, and
%   constructs an associative array.

global isOctave;
global newline;

% Remove uninteresting data
clickCell(cellContains(clickCell,'"page_close"'))=[];
clickCell(cellContains(clickCell,'"username": "",'))=[];
clickCell=strrep(clickCell,', "page": null','');

% Parse JSON clickstream data into structs
if isOctave
    logStructs = cellfun(@loadjson,clickCell,'UniformOutput',false);
else
    logStructs = cellfun(@jsondecode,clickCell,'UniformOutput',false);
end

% Make column keys for each event
logcols = cellfun(@(x) makecols(x,allOutlines,''),logStructs,'UniformOutput',false);

% Form row keys and column keys, construct associative array
if ~isempty(logcols)

    % Create row key- combine filename with line number
    lens = num2cell(cellfun(@NumStr,logcols));
    linenums = num2str((1:length(logStructs))','%04i');
    rIDs = cellstr([repmat([fname(14:end) '_'],size(linenums,1),1) linenums]);
    rIDs = cellfun(@(x,y) repmat([x newline],1,y), rIDs, lens','UniformOutput',false);

    % Form final row and column keys
    rIDs = strjoin(rIDs,'');
    cIDs = strjoin(logcols,'');

    % Construct associative array
    A = Assoc(rIDs, cIDs, 1);
else
    % If no events are parsed, form empty associative array
    A = Assoc('','','');
end

end

