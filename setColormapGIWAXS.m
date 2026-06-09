clear
clc
close all

% Data folder containing files you want to edit. Either use GUI or comment
% out line below and enter the path manually 
[dataFiles,dataPath] = uigetfile("*.fig",'MultiSelect','on');
%dataFolder = "/Users/ianjacobs/Dropbox (Cambridge University)/Research/GIWAXS/January 2024 Beamtime/Processed Data/Scott"

% Enter color limits you would like to use
colorLimits = [10 100000];

% Enter colormap you would like to use
cmap = 'turbo'

% Enter plot style you would like to use
plotStyle = "GIWAXS"


%% Batch process colormaps

%convert filenames and paths to strings
dataFiles = string(dataFiles);
dataPath = string(dataPath);

for i = 1:length(dataFiles)
    openfig(fullfile(dataPath,dataFiles(i)));
    colormap(feval(cmap,colorLimits(2)-colorLimits(1)));
    clim(log10(colorLimits));

    %save figure
    f = gcf;
    [~,figFilename,~] = fileparts(dataFiles(i));
    figFilename = strcat(figFilename,"_updatedColormap");
    figFilename = fullfile(dataPath,figFilename);
    s = hgexport('readstyle',plotStyle);
    s.Format = 'pdf';
    hgexport(f,figFilename,s);
    savefig(f,strcat(figFilename,".fig"),'compact');
end



