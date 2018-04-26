using D4M,JSON
include("../../src/julia/parser.jl")

dataLoc = "../data/raw/noStudents/";
saveLoc = "../data/parsed/julia/"
fnames = readdir(dataLoc)
fnames = dataLoc.*replace.(fnames,".gz","")

savenames = replace.(fnames,dataLoc,saveLoc).*"-A.jld"

outlineLoc = "../data/"
outlinename = outlineLoc*readdir(outlineLoc)[end]

parseFile.(fnames,savenames,outlinename)