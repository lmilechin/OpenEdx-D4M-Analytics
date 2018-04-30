using D4M,JSON,JLD

function extractproblem(event)
    state = pop!(event,"state") # not useful?
    answers = pop!(event,"answers") # info in submission
    submission = pop!(event,"submission")
    correct_map = pop!(event,"correct_map")
    problem_id_long = pop!(event,"problem_id")
    
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
    
    for key in keys(correct_map)
        full_id = split(key,"_")
        sub_id = join(full_id[2:3],"_")
        for key2 in keys(correct_map[key])
            if !(correct_map[key][key2]==nothing) && !isempty(correct_map[key][key2]) && !isa(correct_map[key][key2],Dict)
                eventcols = [eventcols; "event_"*key2*"_"*sub_id*"|"*string(correct_map[key][key2])]
            end
        end
    end
    
    return replace.(eventcols,'\n',"")
end

function incourseware(URL,dict)
    URLparts = split(URL,'/')
    return (haskey(dict,"context") && haskey(dict["context"],"course_id") && 
        contains(URL,dict["context"]["course_id"]*"/courseware/") && !contains(URL,"login") && length(URLparts)>7)
end

function makecols(dict,allOutlines,prefix="")
    cols=[]
    
    delete!(dict,"agent")
    delete!(dict,"accept_language")
    
    toplevel = haskey(dict,"event_type")
    
    if toplevel && dict["event_type"] == "problem_graded" && dict["event_source"] == "browser"
        delete!(dict,"event")
    end
    
    if haskey(dict,"event") && isa(dict["event"],String) && contains(dict["event"],"POST")
        delete!(dict,"event")
    else
        try
            dict["event"]=JSON.parse(dict["event"])
        end
    end
    
    if toplevel && dict["event_type"] == "problem_check" && dict["event_source"] == "server"
        cols = [cols; extractproblem(dict["event"])]
    end
    
    currPage = ""
    
    if toplevel && dict["event_type"] == "edx.course.home.resume_course.clicked"
        lastPage = dict["referer"]
        currPage = dict["event"]["url"]
        dict["event_type"] = "navigation"
    elseif toplevel && (dict["event_type"] == "edx.ui.lms.link_clicked" || dict["event_type"] == "edx.ui.lms.outline.selected")
        lastPage = dict["event"]["current_url"]
        currPage = dict["event"]["target_url"]
        dict["event_type"] = "navigation"
    elseif toplevel && haskey(dict["context"],"path") && (dict["event_type"] == dict["context"]["path"]) && ~contains(dict["event_type"],"handler") && (["https://"*dict["host"]*dict["event_type"]] != dict["referer"])
        currPage = "https://"*dict["host"]*dict["event_type"]
        lastPage = dict["referer"]

        # Uncomment these if you get edx.course.home.resume_course.clicked 
        # or edx.ui.lms.* events and don't want them double counted
#        if incourseware(lastPage,dict) || incourseware(currPage,dict)
#            return ""
#        end
        dict["event_type"] = "navigation"
        dict["context"]["path"] = currPage
    elseif haskey(dict,"referer")
        currPage = dict["referer"]
    end
        
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
        
    if toplevel && incourseware(currPage,dict) && haskey(allOutlines,dict["context"]["course_id"])
        modName,secName,courseLoc = extractnames(currPage,allOutlines)
        cols = [cols; "module_name|"*modName]
        cols = [cols; "section_name|"*secName]
        cols = [cols; "course_loc|"*courseLoc]
    end
    
    for key in keys(dict)
        
        if (isa(dict[key],String) || isa(dict[key],Number)) && ~isempty(dict[key])
            cols = [cols; prefix*key*'|'*replace(string(dict[key]),"\n","")]
        elseif isa(dict[key],Array) && ~isempty(dict[key])  # not supporting array of dicts for now
            if ~isa(dict[key][1],Dict)
                cols = [cols; (prefix*key*'|').*replace.(dict[key],"\n","")]
            else
                cols = [cols; join(join.(makecols.(dict[key],allOutlines,prefix*key*'_')))]
            end
        elseif isa(dict[key],Dict)
            cols = [cols; makecols(dict[key],allOutlines,prefix*key*'_')]
        end
        
    end
    
    return cols
    
end

function makeAssoc(fname,log,allOutlines)
    
    unneeded=["/handler/xmodule_handler/problem_get","/handler/xmodule_handler/problem_show",
    "/handler/transcript/translation/en","/handler/xmodule_handler/goto_position",
    "/handler/xmodule_handler/save_user_state'","/jsi18n","/handler/xmodule_handler/problem_check",
    "/i18n.js","/xmodule/xmodule.js","problem_graded","page_close","\"username\": \"\""]

    for str in unneeded
        log = log[.~contains.(log,str)];
    end
    log = JSON.parse.(log);

    cols = makecols.(log,allOutlines)
    lens = length.(cols)

    rIDs = (fname[14:end]*'_').*lpad.([1:length(log);],4,0).*'\n';
    rIDs = split(join(repeat.(rIDs,lens),"")[1:end-1],'\n')

    cIDs = split(join(join.(cols[cols .!= ""],'\n'),'\n'),'\n')
    
    A = Assoc(rIDs, cIDs, 1)
    
end

function parseFile(fname,savename,outlineName)
    run(`cp $fname.gz ./`)
    lfname = fname[rsearch(fname,'/')+1:length(fname)]
    run(`gunzip -f $lfname.gz`)
    f = open(lfname)
    log = readlines(f)
    println(fname)
    outlines = JSON.parse.(readlines(outlineName))
    allOutlines = Dict{String,Any}()
    for o in outlines
        allOutlines[replace(replace(o["root"],"block","course"),"+type@course+course@course","")] = o["blocks"]
    end
    
    A = makeAssoc(lfname,log,allOutlines)
    run(`rm $lfname`)
    save(savename,"A",A)
    
    return savename
end

function extractnames(url,allOutlines)
    println(url)
    url = split(url,'/')
    courseIdx = find(url.=="courses")[1]+1
    courseID = url[courseIdx]
    
    modID = replace(courseID,"course","block")*"+type@chapter+block@"*url[courseIdx+2]
    println(modID)
    secID = replace(courseID,"course","block")*"+type@sequential+block@"*url[courseIdx+3]
    courseIDfull = replace(courseID,"course","block")*"+type@course+block@course"
    
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
    
    if secName=="unknown" || modName=="unknown"
        courseLoc = "000.000"
    else
        modOrder = allOutlines[courseID][courseIDfull]["children"]
        secOrder = allOutlines[courseID][modID]["children"]
        modLoc = find(modOrder.==modID)
        secLoc = find(secOrder.==secID)
        
        if length(modLoc)==0  || length(secLoc)==0
            courseLoc = "000.000"
        else
            courseLoc = lpad(modLoc[1],3,0)*"."*lpad(secLoc[1],3,0)
        end
        
    end
    
    return modName,secName,courseLoc
end