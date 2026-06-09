clear all
clc
close all

%Specify raw data and processed and data paths. Data will be saved in a
%subfolder for each user in the processed data folder.
processPars.ImagePath = "/Users/ianjacobs/Dropbox (Cambridge University)/Research/GIWAXS/January 2024 Beamtime/Raw Data/si35227-1/pilatus2"
processPars.OutputPath = "/Users/ianjacobs/Dropbox (Cambridge University)/Research/GIWAXS/January 2024 Beamtime/Processed Data/T-dep Gated/IDTBT device 1/160K/"

%Reprocess data from scratch. If false, uses data in OutputPath
reprocess = true;

%Specify sample table to use; for previous year's data this will change.
sampleTableFile = "sampleTable2024.mat"

%Specify data to process. Selects only data matching ALL conditions.
%Comment out any parameters which you don't which to use

%ImageNum = 501555;
SampleSet = "Ian";
SampleName = "IDTBT device 1"
%Attenuation = 0
%ExposureTime = 1
%IncidenceAngle = 0.2
Temperature = 160
%BeamEnergy = 12.5
%Vg = 0
%Vd = 0
%ElectricalData = ""
Notes = ""

%Reference image (for difference images)
RefImgNum = 502257;

%% Additional processing parameters

%Specify color limits for diffraction images. If current image is too dark,
%reduce these values; if too light, increase them. Note, these values are
%automatically scaled for attenuation and exposure time. To turn off
%automatic scaling set scaleToExposure to false
processPars.CLim = [0.1 1];
processPars.DiffCLim = [-5 5];
processPars.ScaleToExposure = false;

%Specify colormap to use in diffraction images. Third party color maps are
%supported, just provide function handle.
processPars.Colormap = @magma;

processPars.IPCutQ = [0.4 0.06];

%Specify q range for reshaped diffraction images. 
processPars.ReshapeQr = [-0.8 3.2];
processPars.ReshapeQz = [0 3.2];

%Specify reshaped image size (in pixels). Too high can lead to artifacts in
%reshaped images.
processPars.ReshapePoints = [900,900];

%If you don't want to save the data, set this to false
processPars.SaveData = true;

%NOTE: there are additional parameters you can specify if necessary, see
%giwaxsProcess function.


%% Process GIWAXS data

%load sample table
load(sampleTableFile)

%get sample table matching values set above
varnames = sampleTable.Properties.VariableNames;
for i = 1:length(varnames)
    if exist(varnames{i},"var")'
        if exist("pars","var")
            pars = {pars{:},varnames{i},eval(varnames{i})};
        else
            pars = {varnames{i},eval(varnames{i})};
        end
    end
end

%get matching subtable and display in console
refSampleTable = getSubSampleTable(sampleTable,"ImageNum",RefImgNum);
sampleTable = getSubSampleTable(sampleTable,pars{:});

%get processing parameter list
if exist("processPars","var")
    processParsNames = fieldnames(processPars);
    for i = 1:length(fieldnames(processPars))
        if exist("processParsList","var")
            processParsList = {processParsList{:},processParsNames{i},getfield(processPars,processParsNames{i})};
        else
            processParsList = {processParsNames{i},getfield(processPars,processParsNames{i})};
        end
    end
else
    processParsList = {};
end

%% process giwaxs data
if reprocess

    processPars.SubtractData = giwaxsProcess(refSampleTable,processParsList{:});
    processParsList = {processParsList{:},"SubtractData",processPars.SubtractData};

    for i = 1:height(sampleTable)
        close all
        [data,ipcut,oopcut] = giwaxsProcess(sampleTable(i,:),processParsList{:});
    end
end



% %% plot full ratio diff patterns
% 
% diffRatioClim = [-100 100]
% 
% 
% subplotdim = [4 5];
% 
% for i = 1:height(sampleTable)
% 
%     outputFilename = strcat(sampleTable.SampleName(i),"_",...%num2str(sampleTable.Vg(i)),"Vg_",...
%     num2str(sampleTable.ImageNum(i)),"_";
%     %num2str(measureTime(i)),"s_gating");
% 
% 
%     subdata = copyhobj(data(i));
%     subdata.PlotScale = 1;
%     subdata.RawData = 100.* (subdata.RawData - scaleFactor(i).*ref_data.RawData) ./ subdata.RawData;
% 
% %         %symlog scaling
% %         C = 0.001
% %         subdata.RawData = sign(subdata.RawData).*(log10(1+abs(subdata.RawData)./(10^C)));
% 
%     qmaps(subdata);
%     subdata.PlotAxisLabel = 2; 
% 
%     figure
%     imagesc(subdata);
%     caxis(diffRatioClim);
%     colormap(magma(1000))
%     if exist("measureTime")
%         title(strcat("V_I_G = ",num2str(sampleTable.Vg(i))," V, t = ",num2str(measureTime(i))," s"))
%     else
%         title(sampleTable(:,i).Sample)
%     end
%     colormap(diffColors)
%     c = colorbar
%     c.Label.String = "Intensity change (%)";
% 
% %         for j=1:length(c.Ticks)
% %             c.TickLabels{j} = num2str(10.^(str2num(c.TickLabels{j}))-1);
% % 
% %         end
% 
% 
% 
%     if savePlots
%         %save fit plot to file
%         f = gcf;
%         ratioDiffFigFilename(i) = fullfile(outputpath,SampleSet,strcat(outputFilename,"_RatioDiffImage"));
% 
%         s = hgexport('readstyle',plotStyle);
%         s.Format = 'pdf';
%         hgexport(f,strcat(ratioDiffFigFilename(i),'.pdf'),s);
% 
%         savefig(f,strcat(ratioDiffFigFilename(i),".fig"),'compact')
%        % exportgraphics(f,strcat(figFilename,'.pdf'),'ContentType','vector')
%         %exportgraphics(f,strcat(figFilename,'.png'),'Resolution',300)
%         %    symlog(gca,'z',0)
%     end
% end
% 
% 
% %% Multifigure plot of raw data
% 
% figFiles = dir(fullfile(outputpath,SampleSet,"*.fig"));
% figFilenames = {figFiles.name};
% dataInd = contains(figFilenames, "GIWAXSpattern.");
% dataFolder = {figFiles(dataInd).folder};
% dataFilename = {figFiles(dataInd).name};
% 
% dataFilename = natsort(dataFilename);
% 
% separateDopeDedope = true;
% 
% if subplotDiff
%     subplotFig = figure;
%     tlo = tiledlayout(subplotFig, 'flow');
% 
%     for i = 1:height(sampleTable)
% 
%         if separateDopeDedope && (i == reverseIndex+1)
%             dedopeFig = figure;
%             tlo = tiledlayout(dedopeFig, 'flow','TileSpacing','Tight');
%         end
% 
% 
%         fig(i) = openfig(fullfile(dataFolder{i},dataFilename{i}),'invisible');
%         ax(i) = gca;
%         ylabel('')
%         xlabel('')
%         colorbar('off')
%         colormap(ax(i),magma)
%         if exist("measureTime")
%             title(strcat("V_I_G = ",num2str(sampleTable.Vg(i))," V, t = ",num2str(measureTime(i))," s"))
%         else
%             title(sampleTable(:,i).Sample)
%         end
% 
% 
%         %rescale -0.5 to 2 in x, 0 to 2.5 in z
%         xlim([90 1352])
%         ylim([707 1586])
% 
% 
%         ax(i).Parent = tlo;
%         if i==1
%             ax(i).Layout.TileSpan = [2 2];
%             refFigFilename =  string(fullfile(dataFolder{i},dataFilename{i}));
% %         elseif separateDopeDedope && (i == reverseIndex+1)
% %             ax(i).Layout.TileSpan = [2 2];
% %             refFigFilename(2) =  string(fullfile(dataFolder{i},dataFilename{i}));
%         else
%             ax(i).Layout.Tile = i;
%         end
%         drawnow
% 
%     end
% 
%     figs = [subplotFig dedopeFig];
% 
%     for i=1:length(figs)
%         ax = figs(i).Children.Children(1);
%         cb = colorbar(ax);
%         cb.Layout.Tile = 'east'
%         cb.Label.String = 'log_{10}(counts)'
% 
%         xlabel(figs(i).Children,'q_y (A^{-1})','FontSize',8);
%         ylabel(figs(i).Children,'q_z (A^{-1})','FontSize',8);
%     end
% 
%     if savePlots
%         subplotStyle = 'FullPage'
%         s = hgexport('readstyle',subplotStyle);
% 
%         %save fit plot to file
%         if separateDopeDedope
%             descString = ["_RawImages_Dope_Full","_RawImages_Dedope_Full"];
%         else
%             figs = subplotFig
%             descString = "_RawImages_Full"
%         end
% 
%         for i = 1:length(figs)
%             f = figs(i);
%             figFilename = fullfile(outputpath,SampleSet,strcat(SampleSet,descString(i)));
%             s.Format = 'pdf';
%             hgexport(f,figFilename,s);
%         end
% 
%     end
% end
% 
% 
% %% Multifigure plot of difference data
% close all
% 
% figFiles = dir(fullfile(outputpath,SampleSet,"*.fig"));
% figFilenames = {figFiles.name};
% %refInd = contains(figFilenames, strcat(num2str(RefImgNum),"_GIWAXSpattern."));
% %refFigFilename = fullfile(figFiles(refInd).folder,figFiles(refInd).name);
% 
% dataInd = contains(figFilenames, "_RatioDiffImage");
% dataFolder = {figFiles(dataInd).folder};
% ratioDiffFigFilename = {figFiles(dataInd).name};
% 
% separateDopeDedope = true;
% 
% reffFilename = refFigFilename;
% 
% if subplotDiff
%     subplotFig = figure;
%     tlo = tiledlayout(subplotFig, 'flow');
% 
%     for i = 1:height(sampleTable)
% 
%         if separateDopeDedope && (i == reverseIndex+1)
%             dedopeFig = figure;
%             tlo = tiledlayout(dedopeFig, 'flow','TileSpacing','Tight');
%         end
% 
%         if i == 1
%             fig(i) = openfig(refFigFilename,'invisible');
%             ax(i) = gca;
%             ylabel('')
%             xlabel('')
%             colorbar('off')
%             title("Reference, t=0")
%             colormap(ax(i), magma)
%             if exist("measureTime")
%                 title(strcat("V_I_G = ",num2str(sampleTable.Vg(i))," V, t = ",num2str(measureTime(i))," s"))
%             else
%                 title(sampleTable(i,:).Sample)
%             end
% 
%         else
%             fig(i) = openfig(strcat(ratioDiffFigFilename{i}),'invisible');
%             ax(i) = gca;
%             ylabel('')
%             xlabel('')
%             colorbar('off')
%             colormap(ax(i), diffColors)
%             caxis(diffRatioClim)
%             if exist("measureTime")
%                 title(strcat("V_I_G = ",num2str(sampleTable.Vg(i))," V, t = ",num2str(measureTime(i))," s"))
%             else
%                 title(sampleTable(i,:).Sample)
%             end
%         end
% 
%         %rescale -0.5 to 2 in x, 0 to 2 in z
%         xlim([90 1352])
%         ylim([707 1586])
% 
% 
%         ax(i).Parent = tlo;
%         if i==1
%             ax(i).Layout.TileSpan = [2 2];
% %         elseif separateDopeDedope && (i == reverseIndex+1)
% %             ax(i).Layout.TileSpan = [2 2];
%         else
%             ax(i).Layout.Tile = i;
%         end
%         drawnow
% 
%     end
% 
%     figs = [subplotFig dedopeFig];
% 
%     for i=1:length(figs)
%         ax = figs(i).Children.Children(1);
%         cb = colorbar(ax);
%         cb.Layout.Tile = 'east'
%         cb.Label.String = 'log_{10}(counts)'
% 
%         xlabel(figs(i).Children,'q_y (A^{-1})','FontSize',8);
%         ylabel(figs(i).Children,'q_z (A^{-1})','FontSize',8);
%     end
% 
%     if savePlots
%         subplotStyle = 'FullPage'
%         s = hgexport('readstyle',subplotStyle);
% 
%         %save fit plot to file
%         if separateDopeDedope
%             descString = ["_DifferenceImages_Dope_Full","_DifferenceImages_Dedope_Full"];
%         else
%             figs = subplotFig
%             descString = "_DifferenceImages_Full"
%         end
% 
%         for i = 1:length(figs)
%             f = figs(i);
%             figFilename = fullfile(outputpath,SampleSet,strcat(SampleSet,descString(i)));
%             s.Format = 'pdf';
%             hgexport(f,figFilename,s);
%         end
% 
%     end
% end
% 
% 
% 
% 
