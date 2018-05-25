%% Author: Lauren Milechin
%  Date:   06/27/2017

%   Given a log file location (dataLoc) and save location (saveLoc),
%   runParse will iterate through all the files in dataLoc, copy the
%   file to the current directory, unzip the file, read in the file and
%   parse the data, save the data to saveLoc, and delete the unzipped local
%   copy of the log.
%   Dependency on jsonlab if running in Octave.

%% Set and add paths

% =============================================================================
% NOTE:  You will need to update the next 2 lines to reflect the correct path to
%        the location where you installed d4m and jsonLab on your system.
%        Set D4M_Loc equal to the full path to d4m/matlab_src
%        Set jsonlabLoc equal to the full path to jsonlab
% =============================================================================

D4M_Loc = '/Users/Lauren/Documents/SoftwareAndPackages/d4m/matlab_src/';
jsonlabLoc = '/Users/Lauren/Documents/SoftwareAndPackages/jsonlab/'; % only needed for octave

% =============================================================================
% Set location of parser, raw data, and Outline
% Set location where parsed data should be saved
% For this example, these reletive paths should not need editing
% =============================================================================
parserLoc = '../../src/matlab-octave/';
dataLoc='../data/raw/';
saveLoc = '../data/parsed/matlab-octave/';
outlineLoc = '../data/';

% Some global variables that should be the same throughout process
global newline;
newline = sprintf('\n');
global isOctave;
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;

% Add paths to required packages and parser
addpath(D4M_Loc)
addpath(parserLoc)
fnames=dir([dataLoc 'tracking.log-*']);
if isOctave
    addpath(jsonlabLoc)
end

% Grab course outlines and create outline struct
if ~isempty(outlineLoc)
    outlineName = dir([outlineLoc 'outline*']);
    outlineName=outlineName(end).name;
else
    outlineName = '';
end
allOutlines = makeoutlines(fullfile(outlineLoc,outlineName));

% Create save location, if it doesn't already exist
if ~exist(saveLoc,'dir')
    mkdir(saveLoc)
end

% Parse each file
for i=1:length(fnames)
    tic
    fname=fnames(i).name;

    % Extract zipped file here
    if isOctave
        copyfile([dataLoc fname],'.');
        gunzip(fname);
    else
        gunzip([dataLoc fname],'.');
    end

    % Parse file into associative array
    A=parseFile(strrep(fname,'.gz',''),allOutlines);
    
    % Delete local copy
    delete(strrep(fname,'.gz',''))
    
    % Save associative array if it is not empty
    if ~isempty(A)
        save([saveLoc strrep(fname,'.gz','.mat')],'A');
    else
        emptyFiles(i)=1;
    end
    toc
end

%%	
% Copyright and Licensing: This collection of code is released under a BSD license.
% 
% Copyright 2017 MIT Lincoln Laboratory. All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without modification, 
% are permitted provided that the following conditions are met:
%
%    Redistributions of source code must retain the above copyright notice, this 
%      list of conditions and the following disclaimer.
%    Redistributions in binary form must reproduce the above copyright notice, this 
%      list of conditions and the following disclaimer in the documentation and/or 
%      other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS 
% OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
% SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
% BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
% ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
% SUCH DAMAGE.
%
% The views and conclusions contained in the software and documentation are those 
% of the authors and should not be interpreted as representing official policies, 
% either expressed or implied, of MIT Lincoln Laboratory.
%
