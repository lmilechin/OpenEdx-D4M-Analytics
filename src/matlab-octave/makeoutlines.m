function [allOutlines] = makeoutlines(outlineName)
    %UNTITLED5 Summary of this function goes here
    %   Detailed explanation goes here

    global isOctave;
    global newline;

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
        if isOctave
            outlines = cellfun(@loadjson,outline,'UniformOutput',false);
        else
            outlines = cellfun(@jsondecode,outline,'UniformOutput',false);
        end
        allOutlines=struct();
        
        for i=1:length(outlines)
            o=outlines{i};
            if isOctave
                allOutlines.(strrep(strrep(o.('root'),'block','course'),'+type@course+course@course','')) = o.('blocks');
            else
                allOutlines.(matlab.lang.makeValidName(replace(replace(o.('root'),'block','course'),'+type@course+course@course',''))) = o.('blocks');
            end
        end
    end
end