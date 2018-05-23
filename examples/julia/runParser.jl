
# Load packages and parser
using D4M,JSON
include("../../src/julia/parser.jl")

# Set paths for raw data and parsed data
dataLoc = "../data/raw/"
saveLoc = "../data/parsed/julia/"

# Get filenames
fnames = filter!(r".gz",readdir(dataLoc))
fnames = dataLoc.*replace.(fnames,".gz","")

# Form savenames
savenames = replace.(fnames,dataLoc,saveLoc).*"-A.jld"

# Get outline file
outlineLoc = "../data/"
outlinename = outlineLoc*filter!(r"outline",readdir(outlineLoc))[end]

# Parse data
parseFile.(fnames,savenames,outlinename)