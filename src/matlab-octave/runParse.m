%% Author: Lauren Milechin
%  Date:   06/27/2017

%   Given a log file location (dataLoc) and save location (saveLoc),
%   runNewParse will iterate through all the files in dataLoc, copy the
%   file to the current directory, unzip the file, read in the file and
%   parse the data, save the data to saveLoc, and delete the unzipped local
%   copy of the log. This driver file uses "newParse" as the parser. Dependency on pMATLAB.

%% set path to data logs
% set the path to the correct Open edX instance before running

% addpath to D4M
addpath('/Users/Lauren/Documents/SoftwareAndPackages/d4m/matlab_src/')

dataLoc='../data/raw/';
saveLoc = '../data/parsed/';
outlineLoc = '../data/';
fnames=dir([dataLoc 'tracking.log-*']);

outlineName = dir([outlineLoc 'outline*']);
outlineName=outlineName(end).name;

if ~exist(saveLoc,'dir')
    mkdir(saveLoc)
end
Nfile=length(fnames);
emptyFiles=zeros(length(fnames),1);
%myFiles = global_ind(zeros(Nfile,1,map([Np 1],{},0:Np-1)));
myFiles = 1:Nfile;

for i=myFiles
    tic
    fname=fnames(i).name;
    copyfile([dataLoc fname],'.');
    system(['gunzip ' fname]);
    A=parseFile(strrep(fname,'.gz',''),fullfile(outlineLoc,outlineName));
    %A=newParse(strrep(fname,'.gz',''));
    delete(strrep(fname,'.gz',''))
    if ~isempty(A)
        save([saveLoc strrep(fname,'.gz','.mat')],'A');
    else
        emptyFiles(i)=1;
    end
    toc
end

%bwsiSeparate
%
% load([saveLoc strrep(fnames(38),'.gz','.mat')],'A');
% julie=A(Row(A(:,['username|JMullen' nl])),:);
% instructor=julie;
% studentX=A(Row(A(:,['username|StudentX' nl])),:);
% student2=A(Row(A(:,['username|Student2' nl])),:);
% student1=A(Row(A(:,['username|Student1' nl])),:);
% save('truthData','instructor','student1','student2','studentX','A');

% fnames(logical(emptyFiles),:)=[];
% tic
% Aall=Assoc('','',1);
% for i=1:length(fnames)
%     fname=strrep(fnames(i).name,'.gz','.mat');
%     load([saveLoc fname]);
%     Aall=Aall+A;
% end
% toc
% 
% % Separate Studio
% %Astudio=Aall(Row(Aall(:,StartsWith(['referer|http://llx-dev1.llgrid.ll.mit.edu:' nl]))),:);
% Astudio=Aall(Row(Aall(:,StartsWith(['referer|http://llx.llgrid.ll.mit.edu:' nl]))),:);
% A=Aall-Astudio;
% 
% save('AllLogEvents','A','Astudio')
% 
% A=Aall(Row(Aall(:,['course_id|course-v1:LLX+LLX04+Q3_2016' char(10)])),:);
% 
% save('BYORevents','A')

% %%
% betaTesters=A(Row(A(:,['username|aklein' nl 'username|cbyun' nl])),:);
% 
% save('betaTesters','betaTesters')

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