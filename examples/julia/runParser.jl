using D4M,JSON
include("../../src/julia/parser.jl")

dataLoc = "../data/raw/"
saveLoc = "../data/parsed/julia/"
fnames = filter!(r".gz",readdir(dataLoc))
fnames = dataLoc.*replace.(fnames,".gz","")

savenames = replace.(fnames,dataLoc,saveLoc).*"-A.jld"

outlineLoc = "../data/"
outlinename = outlineLoc*filter!(r"outline",readdir(outlineLoc))[end]
println(outlinename)

parseFile.(fnames,savenames,outlinename)