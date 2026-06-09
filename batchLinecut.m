clear
clc
close all

%load processed data from folder
processedDataPath = "/Users/ianjacobs/Dropbox (Cambridge University)/Research/GIWAXS/January 2024 Beamtime/Reprocessed Data New FF/Hio-Ieng/"
outputPath = fullfile(processedDataPath,"2Theta linecuts")

%linecut parameters
%1 = q, 2 = phi, 3 = qz, 4 = qx, 5 = qy, 6 = qr, 7 = 2theta, 
%8 = alphaf, 9 = chi, 10 = xpix, 11 = ypix
cuttype = 7; 
%image constraints [operator flag constraint- constraint+]
constr =    [1 3 0.1 3;...
             1 5 0.1 3];

nofpts = 1000;      % number of points in the linecut
dataflag = 2;       % 2 for corrected data; 1 for masked rawdata

makePlots = true;

%%Find image file(s)%%
%get list of tif files in ImagePath and find files matching imgnum
searchString = "_gixsguiData.mat";
filelist = dir(fullfile(processedDataPath,strcat("*",searchString)));
filename = string({filelist.name});
samplename = extractBefore(filename,searchString);
outputNameAndPath = fullfile(outputPath,samplename);
mkdir(outputPath);

%%
for i = 1%:length(filename)
    load(filename(i));
    takeLinecut(data,cuttype,constr,makePlots,outputNameAndPath(i));
    close all
    clear data
end

    




