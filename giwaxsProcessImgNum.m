function [data, IPlinecut, OOPlinecut, processedImage] = giwaxsProcess(imgNum,varargin)
%INITIALPROCESS Summary of this function goes here
%   Detailed explanation goes here

p = inputParser;

%imgnum
defaultImgNum = NaN;
validImgNum = @(x) isnumeric(x);
addRequired(p,'ImgNum',validImgNum);

%Beam0
defaultBeam0 = [];
validBeam0 = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addOptional(p,'Beam0',defaultBeam0,validBeam0);

%Specular
defaultSpecular = [];
validSpecular = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addOptional(p,'Specular',defaultSpecular,validSpecular);

%Reshape data
defaultReshape = true;
validReshape = @(x) islogical(x) && isscalar(x);
addOptional(p,'Reshape',defaultReshape,validReshape);

%Reshape Qrange
defaultReshapeQr = [-0.45 2.55];
defaultReshapeQz = [-0.1 2.55];
validReshapeQ = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addOptional(p,'ReshapeQr',defaultReshapeQr,validReshapeQ);
addOptional(p,'ReshapeQz',defaultReshapeQz,validReshapeQ);

%Reshape points
defaultReshapePoints = [1000 1000];
validReshapePoints = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addOptional(p,'ReshapePoints',defaultReshapePoints,validReshapePoints);

%Interpolate data
defaultInterp = false;
validInterp = @(x) islogical(x) && isscalar(x);
addOptional(p,'Interpolate',defaultInterp,validInterp);

%Interpolate Qrange
defaultInterpQy = [-0.45 2.55];
defaultInterpQz = [-0.1 2.55];
validInterpQ = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addOptional(p,'InterpQy',defaultInterpQz,validReshapeQ);
addOptional(p,'InterpQz',defaultInterpQz,validReshapeQ);

%Inplane Cut q
defaultIPCutQ = [0.06 0.08];
validIPCutQ = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addOptional(p,'IPCutQ',defaultIPCutQ,validIPCutQ);

%Inplane fit
defaultIPFit = "";
validIPFit = @(x) isstring(x);
addOptional(p,'IPFit',defaultIPFit,validIPFit);

%Out of Plane Cut q
defaultOOPCutQ = [-0.01 0.01];
validOOPCutQ = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addOptional(p,'OOPCutQ',defaultOOPCutQ,validOOPCutQ);

%Out of Plane fit
defaultOOPFit = "";
validOOPFit = @(x) isstring(x);
addOptional(p,'OOPFit',defaultOOPFit,validOOPFit);

%Input Image Path
defaultImagePath = pwd;
validPath = @(x) isstring(x);
addOptional(p,'ImagePath',defaultImagePath,validPath);

%Output Path
defaultOutputPath = pwd;
addOptional(p,'OutputPath',defaultOutputPath,validPath);

%Gap fill
defaultGapFillPixelShift = 41;
validGapFill = @(x) isinteger(x) && isscalar(x) && (x > 0);
addOptional(p,'GapFillPixelShift',defaultGapFillPixelShift,validGapFill);

%params
defaultParams = 'diamond2024.mat';
validParams = @(x) isstring(x);
addOptional(p,'Params',defaultParams,validParams);

%save data
defaultSave = false;
validSave = @(x) islogical(x) && isscalar(x);
addOptional(p,'Save',defaultSave,validSave);

%color limits
defaultCLim = [1 10000];
validCLim = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addOptional(p,'CLim',defaultCLim,validCLim);

%Normalize colors to exposure
defaultScaleToExposure = false;
validScaleToExposure = @(x) islogical(x) && isscalar(x);
addOptional(p,'ScaleToExposure',defaultScaleToExposure,validScaleToExposure);

%colormap
defaultColormap = 'magma';
validColormap = @(x) isstring(x);
addOptional(p,'Colormap',defaultColormap,validColormap);

%Sample Set (e.g. user)
defaultSampleSet = [];
validSampleSet = @(x) isstring(x);
addOptional(p,'SampleSet',defaultSampleSet,validSampleSet);

% %OutputFilename
% defaultOutputFilename = num2str(imgnum);
% validOutputFilename = @(x) isstring(x);
% addOptional(p,'OutputFilename',defaultOutputFilename,validOutputFilename);

%SampleName
defaultSampleName = "";
validSampleName = @(x) isstring(x);
addOptional(p,'SampleName',defaultSampleName,validSampleName);

%Sample Table
defaultSampleTable = "sampleTable.mat";
validSampleTable = @(x) isstring(x);
addOptional(p,'SampleTable',defaultSampleTable,validSampleTable);

%plotFormat
defaultPlotFormat = "png";
validPlotFormat = @(x) strcmp(x,"png") || strcmp(x,"pdf");
addOptional(p,'PlotFormat',defaultPlotFormat,validPlotFormat);

%subtract data
defaultSubtractImgNum = [];
validSubtractImgNum = @(x) isnumeric(x);
addOptional(p,'SubtractImgNum',defaultSubtractImgNum,validSubtractImgNum);

%subtract data coefficient
defaultSubtractionCoefficient = 1;
validSubtractionCoefficient = @(x) isnumeric(x);
addOptional(p,'SubtractionCoefficient',defaultSubtractionCoefficient,validSubtractionCoefficient);

%plot scale
defaultPlotScale = "log";
validPlotScale = @(x) strcmp(x,"linear") || strcmp(x,"log");
addOptional(p,'PlotScale',defaultPlotScale,validPlotScale);

%Plot Style Linecut
defaultPlotStyleLinecut = "HalfCol";
validPlotStyleLinecut = @(x) isstring(x);
addOptional(p,'PlotStyleLinecut',defaultPlotStyleLinecut,validPlotStyleLinecut)

%Plot Style GIWAXS
defaultPlotStyleGIWAXS = "GIWAXS";
validPlotStyleGIWAXS = @(x) isstring(x);
addOptional(p,'PlotStyleGIWAXS',defaultPlotStyleGIWAXS,validPlotStyleGIWAXS)


parse(p,imgNum,varargin{:});

%load sample table
try
    load(p.Results.SampleTable);
catch
    try
        load(strcat(p.Results.SampleTable),'.mat');
    catch
        warning("No sample table loaded");
    end
end

% Create a new gixsdata object from parameter file
loaded_params = load(p.Results.Params);
data = copyhobj(loaded_params.params);

%load color limits
colorLimits = p.Results.CLim;

%set linear or log color scale
if strcmp(p.Results.PlotScale,"log")
    data.PlotScale = 2;
    colorLimits = log10(colorLimits);
else
    data.PlotScale = 1;
end

%sets output folder
outputPath = p.Results.OutputPath;




%if sampleTable exists...
if exist('sampleTable')
    %find imgNum entry in sampleTable
    sampleInd = find(sampleTable.ImageNum == imgNum);

    %..and imgnum is in the table...
    if ~isempty(sampleInd)
        %extract sample details and create detailed filename
        sampleName = sampleTable.SampleName(sampleInd);
        attenuation = sampleTable.Attenuation(sampleInd);
        exposureTime = sampleTable.ExposureTime(sampleInd);
        data.IncidentAngle = sampleTable.IncidenceAngle(sampleInd(1));
       
        %if beam0 is given in sample table use this value
        try 
            beam0 = sampleTable.Beam0(sampleInd);    
            b0exists = ~isnan(beam0);
            if and(b0exists(1),b0exists(2))
                data.Beam0 = beam0;
                data.Specular = data.Beam0 - [0 1];
            end
        catch
            warning(strcat("No Beam0 specified in Sample Table, using default value from parameter file ",p.Results.Params))
        end
        
    
        %set output filename
        outputFilename = strcat(sampleName,"_",...
            num2str(attenuation),"att_",...
            num2str(exposureTime),"sExp_",...
            num2str(imgNum));

        %set append output path to user name
        if ~isempty(sampleTable.SampleSet(sampleInd))
            outputPath = fullfile(p.Results.OutputPath,sampleTable.SampleSet(sampleInd));
        end

        %update color limits to exposure conditions if given, using the beam
        %transmission from the co-located .dat metadata ('transmission' field)
        if p.Results.ScaleToExposure
            datFile = fullfile(p.Results.ImagePath, num2str(imgNum) + ".dat");
            datParams = [];
            if isfile(datFile)
                datParams = readDatParams(datFile);
            end
            if ~isempty(datParams) && isfield(datParams,'transmission')
                colorLimits = getCLims(colorLimits,datParams.transmission,exposureTime,p.Results.PlotScale);
            else
                warning("giwaxsProcessImgNum:noTransmission", ...
                    "No 'transmission' metadata for image %d; colour limits not scaled.", imgNum);
            end
        end
    end
else
    %if not in sample table, use given sample name (defaults to imgNum if
    %unspecified)
    sampleName = p.Results.SampleName;

    if isempty(sampleName)
        outputFilename = num2str(imgNum);
    else
        outputFilename = strcat(sampleName,"_",imgNum);
    end
end

%if a different sample set is specified append subfolder to this path
if ~isempty(p.Results.SampleSet)
    %redefine outputpath to save in user folder if specified
    outputPath = fullfile(p.Results.OutputPath,p.Results.SampleSet);
end

%create folder if needed
mkdir(outputPath);





%%Find image file(s)%%
%get list of tif files in ImagePath and find files matching imgnum
filelist = dir(fullfile(p.Results.ImagePath,"*.tif"));
filename = {filelist.name};
sampleInd = contains(filename,num2str(imgNum));
imgfile = filename(sampleInd);

%if we have 2 image files matching imgNum, gap fill the images
if length(imgfile) == 2
    %sort
    imgfile = sort(imgfile);

    %gap fill
    filledImg = mgapfillArb(fullfile(p.Results.ImagePath,imgfile{1}),fullfile(p.Results.ImagePath,imgfile{2}));

    %save the gap filled data in outputPath
    if p.Results.Save
        gapFillFilename = convertStringsToChars(fullfile(outputPath,strcat(outputFilename,"_gapFilled.tif")));
        imwrite2tif(filledImg,[],gapFillFilename,"double")
    end

%more than 2 images or no images generates an error
elseif length(imgfile) > 2
    ME = MException("GIWAXSProcess:TooManyImages","More than two image files found matching imgnum");
    throw(ME)
elseif length(imgfile) < 1
    ME = MException("NoImages","No image files found matching imgnum");
    throw(ME)
end

% Load image (gap filled if we have it) to gixsgui
if exist("gapFillFilename")
    data.ImFile = gapFillFilename;
    data.Mask = ones(size(data.ImFile));
else
    data.ImFile = char(fullfile(p.Results.ImagePath,imgfile{1}));
end

%update beam0 and specular if given in arguments. overwrites values given
%in sampletable!
if ~isempty(p.Results.Beam0)
    data.Beam0 = p.Results.Beam0;
    if ~isempty(p.Results.Specular)
        data.Specular = p.Results.Specular;
    else
        data.Specular = data.Beam0 - [0 1];
    end
end

%update q maps if Beam0 or specular have changed
qmaps(data);

if ~isempty(p.Results.SubtractImgNum) && p.Results.SubtractImgNum ~= imgNum

    %process background image identically to sample image
    bkgdata = giwaxsProcess(p.Results.SubtractImgNum,varargin{:})

    data.RawData = data.RawData - p.Results.SubtractionCoefficient.*bkgdata.RawData;
end



%% Display the image with qz qy axis
data.PlotAxisLabel = 2; 
figure
imagesc(data);
caxis(colorLimits);
colormap(feval(p.Results.Colormap,1000))
title('')
if p.Results.Save
    f = gcf;
    figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern"));
    s = hgexport('readstyle',p.Results.PlotStyleGIWAXS);
    s.Format = 'pdf';
    hgexport(f,figFilename,s);
    savefig(f,strcat(figFilename,".fig"),'compact');
end

%% Reshape
if p.Results.Reshape
    % --- Define reshaping parameter for (qz vs qr) 
    param_reshape.X = 6;  % qr
    param_reshape.Y = 3;  % qz
    param_reshape.XNOfPts = p.Results.ReshapePoints(1); % number of points for X axis
    param_reshape.YNOfPts = p.Results.ReshapePoints(2); % number of points for y axis
    
    param_reshape.XRange = p.Results.ReshapeQr;  % range for x
    param_reshape.YRange = p.Results.ReshapeQz;  % range for y
    
    % % --- Define reshaping parameter for (qz vs chi) 
    % param_reshape.X = 9;  % chi
    % param_reshape.Y = 3;  % qz
    % param_reshape.XNOfPts = 300; % number of points for X axis
    % param_reshape.YNOfPts = 300; % number of points for y axis
    % param_reshape.XRange = [-90,90];  % range for x
    % param_reshape.YRange = [0,2];  % range for y
    
    % --- reshape 
    dataflag = 2;       % 2 for corrected data; 1 for masked rawdata
    [processedImage.reshape.X,processedImage.reshape.Y,processedImage.reshape.Image,countdata] = reshape_image(data,param_reshape,dataflag);
    
    % --- plot reshaped image
    figure
    if data.PlotScale == 1
        imagesc(processedImage.reshape.X,processedImage.reshape.Y,processedImage.reshape.Image,[1,4]);
    else
        imagesc(processedImage.reshape.X,processedImage.reshape.Y,log10(processedImage.reshape.Image),[1,4]);
    end
    axis equal
    axis tight
    set(gca,'ydir','norm');
    xlabel('q_r (A^{-1})');
    ylabel('q_z (A^{-1})');
    %title('Reshaped image (log scale)');
    caxis(colorLimits);
    colormap(feval(p.Results.Colormap,1000))
    
    
    if p.Results.Save
        f = gcf;
        figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern_reshape"));
        s = hgexport('readstyle',p.Results.PlotStyleGIWAXS);
        s.Format = 'pdf';
        hgexport(f,figFilename,s);
        savefig(f,strcat(figFilename,".fig"),'compact');
    end
end

% --- plot counter data
% figure
% imagesc(x,y,countdata)
% axis ij
% set(gca,'ydir','norm');
% xlabel('q_r (A^{-1})');
% ylabel('q_z (A^{-1})');
% title('Counter for reshaped image')

%% Interpolate (for image subtraction)
if p.Results.Interpolate
    % --- Define reshaping parameter for (qz vs qr) 
    param_reshape.X = 5;  % qy
    param_reshape.Y = 3;  % qz
    param_reshape.XNOfPts = 800; % number of points for X axis
    param_reshape.YNOfPts = 800; % number of points for y axis
    
    param_reshape.XRange = p.Results.InterpQy;  % range for x
    param_reshape.YRange = p.Results.InterpQz;  % range for y
    
    % % --- Define reshaping parameter for (qz vs chi) 
    % param_reshape.X = 9;  % chi
    % param_reshape.Y = 3;  % qz
    % param_reshape.XNOfPts = 300; % number of points for X axis
    % param_reshape.YNOfPts = 300; % number of points for y axis
    % param_reshape.XRange = [-90,90];  % range for x
    % param_reshape.YRange = [0,2];  % range for y
    
    % --- reshape 
    dataflag = 2;       % 2 for corrected data; 1 for masked rawdata
    [processedImage.interp.X,processedImage.interp.Y,processedImage.interp.Image,countdata] = reshape_image(data,param_reshape,dataflag);
    
    % --- plot reshaped image
    figure
    if data.PlotScale == 1
        imagesc(processedImage.interp.X,processedImage.interp.Y,processedImage.interp.Image,[1,4]);
    else
        imagesc(processedImage.interp.X,processedImage.interp.Y,log10(processedImage.interp.Image),[1,4]);
    end
    axis equal
    axis tight
    set(gca,'ydir','norm');
    xlabel('q_y (A^{-1})');
    ylabel('q_z (A^{-1})');
    %title('Reshaped image (log scale)');
    caxis(colorLimits);
    colormap(feval(p.Results.Colormap,1000))
    
    
    if p.Results.Save
        f = gcf;
        figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern_interpolated"));
        s = hgexport('readstyle',p.Results.PlotStyleGIWAXS);
        s.Format = 'pdf';
        hgexport(f,figFilename,s);
        savefig(f,strcat(figFilename,".fig"),'compact');
    end
end

% --- plot counter data
% figure
% imagesc(x,y,countdata)
% axis ij
% set(gca,'ydir','norm');
% xlabel('q_r (A^{-1})');
% ylabel('q_z (A^{-1})');
% title('Counter for reshaped image')


%% Inplane linecut
% --- define constraint
constr = horzcat([1 3],p.Results.IPCutQ);
% --- perform linecut. 
xflag = 1;          % qy linecut
nofpts = 1000;      % number of points in the linecut
dataflag = 2;       % 2 for corrected data; 1 for masked rawdata
[x,y] = linecut(data,xflag,constr,nofpts,dataflag); %
IPlinecut.x = x;
IPlinecut.y = y;

%% plot linecut
figure
plot(x,y)
xlabel('q_y (A^{-1})');
ylabel('Intensity (a.u.)');
axis tight

%% Inplane linecut fitting
if p.Results.IPFit ~= ""
    IPlinecut.fitFun = p.Results.IPFit;
    fitFuncCall = strcat(p.Results.IPFit,"(x, y)");
    [IPlinecut.fit, IPlinecut.gof] = eval(fitFuncCall);
    
    IPlinecut.coeffs = coeffvalues(IPlinecut.fit);
    IPlinecut.coeffNames = coeffnames(IPlinecut.fit);

end
    
%     d_pipi = abs(2.*pi/fc(1));
%     d_chain = abs(2.*pi/fc(2));
%     
%     g_pipi = sqrt(2.*abs(fc(3).*d_pipi))/(2.*pi)

%% Save inplane linecut
if p.Results.Save
    %save data to ascii file
    IPlinecut_data = [x,y];
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_Qy",...
        num2str(p.Results.IPCutQ(1)),"to",num2str(p.Results.IPCutQ(2)),".txt")),...
        'IPlinecut_data','-ascii');

    %safe full data struct with fit to .mat file
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_Qy",...
        num2str(p.Results.IPCutQ(1)),"to",num2str(p.Results.IPCutQ(2)),".mat")),...
        'IPlinecut');
    
    %save fit plot to file
    f = gcf;
    figFilename = fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_plot"));
    s = hgexport('readstyle',p.Results.PlotStyleLinecut);
    s.Format = 'pdf';
    hgexport(f,figFilename,s);
end

%% OOP linecut
% --- define constraint
constr = horzcat([2 5],p.Results.OOPCutQ);
% --- perform linecut. 
xflag = 3;          % qy linecut
nofpts = 1000;      % number of points in the linecut
dataflag = 2;       % 2 for corrected data; 1 for masked rawdata
[x,y] = linecut(data,xflag,constr,nofpts,dataflag); %
OOPlinecut.x = x;
OOPlinecut.y = y;


%% Plot linecut
figure
semilogy(x,y)
xlabel('q_z (A^{-1})');
ylabel('Intensity (a.u.)');
axis tight

%% OOP linecut fitting
if p.Results.OOPFit ~= ""
    OOPlinecut.fitFun = p.Results.OOPFit;
    fitFuncCall = strcat(p.Results.OOPFit,"(x, y)");
    [OOPlinecut.fit, OOPlinecut.gof] = eval(fitFuncCall);
    
    OOPlinecut.coeffs = coeffvalues(OOPlinecut.fit);
    OOPlinecut.coeffNames = coeffnames(OOPlinecut.fit);
end

%% Save OOPlane linecut to ASCII file
if p.Results.Save
    %save data to ascii file
    OOPlinecut_data = [x,y];
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_Qx",...
        num2str(p.Results.OOPCutQ(1)),"to",num2str(p.Results.OOPCutQ(2)),".txt")),...
        'OOPlinecut_data','-ascii');

    %safe full data struct with fit to .mat file
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_Qx",...
        num2str(p.Results.OOPCutQ(1)),"to",num2str(p.Results.OOPCutQ(2)),".mat")),...
        'OOPlinecut');
    
    %save fit plot to file
    f = gcf;
    figFilename = fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_plot"));
    s = hgexport('readstyle',p.Results.PlotStyleLinecut);
    s.Format = 'pdf';
    hgexport(f,figFilename,s);
end

%% Save processed gixsgui file so we can reopen it later if needed
if p.Results.Save
    save(fullfile(outputPath,strcat(outputFilename,"_gixsguiData.mat")),'data')
end

end

