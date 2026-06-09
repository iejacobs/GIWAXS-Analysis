function linecutData = takeLinecut(data,cuttype,constraint,makePlots,fileNameAndPath,varargin)
%TAKELINECUT Summary of this function goes here
%   Detailed explanation goes here

if nargin < 7
    dataflag = 2;
end
if nargin < 6
    numPts = 1000;
end
if nargin < 5
    fileNameAndPath = "";
end
if nargin < 4
   makePlots = true;
end
if nargin < 3
    throw(MException("takeLinecut:MissingArgs","Must specify data, cuttype, and constraint"))
end

plotStyle = "HalfCol";

[x,y] = linecut(data,cuttype,constraint,numPts,dataflag);
linecutData.x = x;
linecutData.y = y;

    %% Plot linecut
if makePlots
    figure
    semilogy(x,y)
    xlabel(flagToAxisLabel(cuttype));
    ylabel('Intensity (a.u.)');
    axis tight
end

%% Save OOPlane linecut to ASCII file
if ~strcmp(fileNameAndPath,"")
    %save data to ascii file
    linecut_data = [x,y];
    save(strcat(fileNameAndPath,"_",flagToString(cuttype),"_Linecut.txt"),...
        'linecut_data','-ascii');

    %save full data struct with fit to .mat file
    save(strcat(fileNameAndPath,"_",flagToString(cuttype),"_Linecut.mat"),...
        'linecutData');
    
    if makePlots
        %save fit plot to file
        f = gcf;
        figFilename = strcat(fileNameAndPath,"_",flagToString(cuttype),"_Linecut_plot.pdf");
        s = hgexport('readstyle',plotStyle);
        s.Format = 'pdf';
        hgexport(f,figFilename,s);
    end
end
end

