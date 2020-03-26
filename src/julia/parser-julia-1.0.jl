using D4M,JSON,JLD,GZip

# Function to read in data and outlines and parse data
function parseFile(fname,savename,outlinename)

    # Read in log file
    f = GZip.open("$fname.gz")
    log = readlines(f)

    # Parse outlines and combine into single dict
    outlines = JSON.parse.(readlines(outlinename))
    allOutlines = Dict{String,Any}()
    for o in outlines
        allOutlines[replace(replace(o["root"],"block" => "course"),"+type@course+course@course" => "")] = o["blocks"]
    end
    
    # Filename to be used in row key
    filename = fname[findlast("/",fname)[end]+1:length(fname)]

    # Create associative array and save
    A = makeAssoc(filename,log,allOutlines)
    if !isempty(A)
        save(savename,"A",A)
        return savename
    else
        return nothing
    end
    
    
end

# Function to create associative array
function makeAssoc(fname,log,allOutlines)
    
    # Strings that occur in uninteresting events
    unneeded=["page_close","\"username\": \"\""]

    # Remove any uninteresting events now
    for str in unneeded
        log = log[.~occursin.(str,log)];
    end

    # Parse the JSON log file into dict
    log = JSON.parse.(log);
    
    unneeded_events = ["/handler/xmodule_handler/","/handler/transcript/","/handler/vote","handler/student_voted","/handler/publish_event","/handler/get_user_state","/handler/get_results","/handler/drop_item","/handler/do_attempt"]
    
    for str in unneeded_events
        log = log[.~occursin.(str,getindex.(log,"event_type"))]
    end

    # Make column keys
    cols = makecols.(log,Ref(allOutlines))

    # Return emtpy associative array if cols is empty
    if isempty(cols)
        A = Assoc("","","")
    else
        # Finish column keys
        cIDs = split(join(join.(cols[cols .!= ""],'\n'),'\n'),'\n')

        # Make row keys
        lens = length.(cols)
        rIDs = (fname[14:end]*'_').*lpad.([1:length(log);],4,'0').*'\n';
        rIDs = split(join(repeat.(rIDs,lens),"")[1:end-1],'\n')

        # Form associative array
        A = Assoc(rIDs, cIDs, 1)
    end
    
end

# Function to create column keys for event data
function makecols(dict,allOutlines,prefix="")

    cols=[]
    toplevel = haskey(dict,"event_type")
    
    # Remove uninteresting fields
    delete!(dict,"agent")
    delete!(dict,"accept_language")
    if toplevel && dict["event_type"] == "problem_graded" && dict["event_source"] == "browser"
        delete!(dict,"event")
    end

    # Remove event field for "POST/GET" events (these are not explicit events)
    if haskey(dict,"event") && isa(dict["event"],String) && occursin("POST",dict["event"])
        delete!(dict,"event")

    # Try to parse events that may not have parsed the first time
    else
        try
            dict["event"]=JSON.parse(dict["event"])
        catch
            
        end
    end
    
    # Parse problem event
    if toplevel && dict["event_type"] == "problem_check" && dict["event_source"] == "server"
        cols = [cols; extractproblem(dict["event"])]
    end
    
    # Parse nagivigation events: If: event_type == context_path AND (host event_type) ~= referer, this is a navigation event
    currPage = ""
    if toplevel && dict["event_type"] == "edx.course.home.resume_course.clicked"
        lastPage = dict["referer"]
        currPage = dict["event"]["url"]
        dict["event_type"] = "navigation"
    elseif toplevel && (dict["event_type"] == "edx.ui.lms.link_clicked" || dict["event_type"] == "edx.ui.lms.outline.selected")
        lastPage = dict["event"]["current_url"]
        currPage = dict["event"]["target_url"]
        dict["event_type"] = "navigation"
    elseif toplevel && haskey(dict["context"],"path") && (dict["event_type"] == dict["context"]["path"]) && ~occursin("handler",dict["event_type"]) && (["https://"*dict["host"]*dict["event_type"]] != dict["referer"])
        currPage = "https://"*dict["host"]*dict["event_type"]
        lastPage = dict["referer"]

        # Uncomment these if you get edx.course.home.resume_course.clicked 
        # or edx.ui.lms.* events and don't want them double counted
#        if incourseware(lastPage,dict) || incourseware(currPage,dict)
#            return ""
#        end
        dict["event_type"] = "navigation"
        dict["context"]["path"] = currPage
    
    # If it's not a navigation event, the current page can be gotten from the referrer
    elseif haskey(dict,"referer")
        currPage = dict["referer"]
    end
        
    # Grab module/section names and course location previous/current page if both in courseware (to make course navigation graph)
    if toplevel && dict["event_type"] == "navigation" && incourseware(lastPage,dict) && haskey(allOutlines,dict["context"]["course_id"])
        
        modName,secName,courseLoc = extractnames(lastPage,allOutlines)
        cols = [cols; "last_module_name|"*modName]
        cols = [cols; "last_section_name|"*secName]
        cols = [cols; "last_course_loc|"*courseLoc]
        if incourseware(currPage,dict)
            modName,secName,courseLoc = extractnames(currPage,allOutlines)
            cols = [cols; "new_module_name|"*modName]
            cols = [cols; "new_section_name|"*secName]
            cols = [cols; "new_course_loc|"*courseLoc]
        end
    end
        
    #Grab the module/section names and course location if current page is in courseware
    if toplevel && incourseware(currPage,dict) && haskey(allOutlines,dict["context"]["course_id"])
        modName,secName,courseLoc = extractnames(currPage,allOutlines)
        cols = [cols; "module_name|"*modName]
        cols = [cols; "section_name|"*secName]
        cols = [cols; "course_loc|"*courseLoc]
    end
    
    # Parse remaining fields
    for key in keys(dict)

        # If field is a scalar (single) string or number, just add it
        if (isa(dict[key],String) || isa(dict[key],Number)) && ~isempty(dict[key])
            cols = [cols; prefix*key*'|'*replace(string(dict[key]),"\n" => "")]
        
            # If field is a non-empty array, add each element
        elseif isa(dict[key],Array) && ~isempty(dict[key])  # not supporting array of dicts for now
            if ~isa(dict[key][1],Dict)
                cols = [cols; (prefix*key*'|').*replace.(dict[key],Ref("\n" => ""))]
            else
                cols = [cols; join(join.(makecols.(dict[key],Ref(allOutlines),prefix*key*'_')))]
            end

        # If field is a struct, recursively call makecols on the struct
        elseif isa(dict[key],Dict)
            cols = [cols; makecols(dict[key],allOutlines,prefix*key*'_')]
        end
        
    end
    
    return cols
    
end

# Function that parses out problem events
function extractproblem(event)

    # Remove uninteresting fields
    state = pop!(event,"state") # not useful?
    answers = pop!(event,"answers") # info in submission
    
    # Extract interesting fields and remove them from the struct
    submission = pop!(event,"submission")
    correct_map = pop!(event,"correct_map")
    problem_id_long = pop!(event,"problem_id")
    
    # Parse out the "submission" struct
    eventcols = []
    prob_id = ""
    for key in keys(submission)
        full_id = split(key,"_")
        sub_id = join(full_id[2:3],"_")
        for key2 in keys(submission[key])
            if !isempty(submission[key][key2])
                eventcols = [eventcols; "event_"*key2*"_"*sub_id*"|"*string(submission[key][key2])]
            end
        end
        if length(prob_id)<1
            prob_id = full_id[1]
        end
    end
    eventcols = [eventcols; "event_problem_id|"*prob_id; "event_problem_id_long|"*problem_id_long]
    
    # Parse out "correct_map"
    for key in keys(correct_map)
        full_id = split(key,"_")
        sub_id = join(full_id[2:3],"_")
        for key2 in keys(correct_map[key])
            if !(correct_map[key][key2]==nothing) && !isempty(correct_map[key][key2]) && !isa(correct_map[key][key2],Dict)
                eventcols = [eventcols; "event_"*key2*"_"*sub_id*"|"*string(correct_map[key][key2])]
            end
        end
    end
    
    return replace.(eventcols,Ref('\n' => ""))
end

# Function that indicates whether the given URL is in the courseware
function incourseware(URL,dict)
    URLparts = split(URL,'/')
    return (haskey(dict,"context") && haskey(dict["context"],"course_id") && 
        occursin(dict["context"]["course_id"]*"/courseware/",URL) && !occursin("login",URL) && length(URLparts)>7)
end

# Function that finds the section and module names for the given url
function extractnames(url,allOutlines)

    # Split up the URL and find the course ID
    url = split(url,'/')
    courseIdx = findfirst(url.=="courses")[1]+1
    courseID = url[courseIdx]
    
    # Find module and section fieldnames
    modID = replace(courseID,"course" => "block")*"+type@chapter+block@"*url[courseIdx+2]
    secID = replace(courseID,"course" => "block")*"+type@sequential+block@"*url[courseIdx+3]
    courseIDfull = replace(courseID,"course" => "block")*"+type@course+block@course"
    
    # Get module and section display names
    if haskey(allOutlines[courseID],modID)
        modName = allOutlines[courseID][modID]["display_name"]
    else
        modName = "unknown"
    end
    if haskey(allOutlines[courseID],secID)
        secName = allOutlines[courseID][secID]["display_name"]
    else
        secName = "unknown"
    end
    
    # Build course location string
    if secName=="unknown" || modName=="unknown"
        courseLoc = "000.000"
    else
        modOrder = allOutlines[courseID][courseIDfull]["children"]
        secOrder = allOutlines[courseID][modID]["children"]
        modLoc = findall(modOrder.==modID)
        secLoc = findall(secOrder.==secID)
        
        
        
        if length(modLoc)==0  || length(secLoc)==0
            courseLoc = "000.000"
        else
            courseLoc = lpad(modLoc[1],3,"0")*"."*lpad(secLoc[1],3,"0")
        end
        
    end
    
    return modName,secName,courseLoc
end