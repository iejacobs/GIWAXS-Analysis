function [data, IPlinecut, OOPlinecut, processedImage] = giwaxsProcess(sampleTableRowOrImgNum,varargin)
%INITIALPROCESS Summary of this function goes here
%   Detailed explanation goes here

%ensure bundled helper folders are on the path (Support Functions, and the
%geometry-calibration functions used when UseCalibration is true)
fnDir = fileparts(mfilename('fullpath'));
addpath(fullfile(fnDir,'Support Functions'), fullfile(fnDir,'Calibration Scripts'));

p = inputParser;

% %imgnum
% defaultImgNum = NaN;
% validImgNum = @(x) isnumeric(x);
% addOptional(p,'ImgNum',validImgNum);

%Beam0
defaultBeam0 = [];
validBeam0 = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'Beam0',defaultBeam0,validBeam0);

%Specular
defaultSpecular = [];
validSpecular = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'Specular',defaultSpecular,validSpecular);

%SDD (sample-detector distance, mm) manual override
defaultSDD = [];
validSDD = @(x) isnumeric(x) && isscalar(x);
addParameter(p,'SDD',defaultSDD,validSDD);

%Use beam0/SDD geometry calibration derived from the .dat metadata
defaultUseCalibration = true;
validUseCalibration = @(x) islogical(x) && isscalar(x);
addParameter(p,'UseCalibration',defaultUseCalibration,validUseCalibration);

%Beam0 calibration file (beam0 vs detector position)
defaultBeam0CalFile = "beam0_calibration.mat";
validCalFile = @(x) isstring(x) && isscalar(x);
addParameter(p,'Beam0CalFile',defaultBeam0CalFile,validCalFile);

%SDD calibration file (SDD vs detector position)
defaultSDDCalFile = "sdd_calibration.mat";
addParameter(p,'SDDCalFile',defaultSDDCalFile,validCalFile);

%Metadata path (folder holding <imgNum>.dat); empty => use ImagePath
defaultMetadataPath = "";
addParameter(p,'MetadataPath',defaultMetadataPath,validCalFile);

%Frame number to extract from multi-frame (scan) HDF5 files; empty => first
%frame (with a warning if more frames exist)
defaultFrameNumber = [];
validFrameNumber = @(x) isnumeric(x) && (isempty(x) || (isscalar(x) && x >= 1 && mod(x,1) == 0));
addParameter(p,'FrameNumber',defaultFrameNumber,validFrameNumber);

%Reshape data
defaultReshape = true;
validReshape = @(x) islogical(x) && isscalar(x);
addParameter(p,'Reshape',defaultReshape,validReshape);

%Perform linecuts
defaultLinecuts = true;
validLinecuts = @(x) islogical(x) && isscalar(x);
addParameter(p,'DoLinecuts',defaultLinecuts,validLinecuts);

%Show plots
defaultMakePlots = true;
validMakePlots = @(x) islogical(x) && isscalar(x);
addParameter(p,'MakePlots',defaultMakePlots,validMakePlots);

%Reshape Qrange
defaultReshapeQr = [-0.45 2.55];
defaultReshapeQz = [-0.1 2.55];
validReshapeQ = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'ReshapeQr',defaultReshapeQr,validReshapeQ);
addParameter(p,'ReshapeQz',defaultReshapeQz,validReshapeQ);

%Reshape points
defaultReshapePoints = [1000 1000];
validReshapePoints = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'ReshapePoints',defaultReshapePoints,validReshapePoints);

%Interpolate data
defaultInterp = false;
validInterp = @(x) islogical(x) && isscalar(x);
addParameter(p,'Interpolate',defaultInterp,validInterp);

%Interpolate Qrange
defaultInterpQy = [-0.45 2.55];
defaultInterpQz = [-0.1 2.55];
validInterpQ = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'InterpQy',defaultInterpQz,validReshapeQ);
addParameter(p,'InterpQz',defaultInterpQz,validReshapeQ);

%Inplane Cut q
defaultIPCutQ = [0.06 0.08];
validIPCutQ = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'IPCutQ',defaultIPCutQ,validIPCutQ);

%Inplane fit
defaultIPFit = "";
validIPFit = @(x) isstring(x);
addParameter(p,'IPFit',defaultIPFit,validIPFit);

%Out of Plane Cut q
defaultOOPCutQ = [-0.01 0.01];
validOOPCutQ = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'OOPCutQ',defaultOOPCutQ,validOOPCutQ);

%Out of Plane fit
defaultOOPFit = "";
validOOPFit = @(x) isstring(x);
addParameter(p,'OOPFit',defaultOOPFit,validOOPFit);

%Input Image Path
defaultImagePath = pwd;
validPath = @(x) isstring(x);
addParameter(p,'ImagePath',defaultImagePath,validPath);

%Output Path
defaultOutputPath = pwd;
addParameter(p,'OutputPath',defaultOutputPath,validPath);

%Gap fill
defaultGapFillPixelShift = 41;
validGapFill = @(x) isinteger(x) && isscalar(x) && (x > 0);
addParameter(p,'GapFillPixelShift',defaultGapFillPixelShift,validGapFill);

%parameter file
defaultParamFile = "";
validParamFile = @(x) isstring(x);
addParameter(p,'ParameterFile',defaultParamFile,validParamFile);

%parameter function
defaultParamFun = @getParams;
validParamFun = @(x) isa(x,"function_handle");
addParameter(p,'ParameterFunction',defaultParamFun,validParamFun);

%save data
defaultSave = true;
validSave = @(x) islogical(x) && isscalar(x);
addParameter(p,'SaveData',defaultSave,validSave);

%color limits
defaultCLim = [1 10000];
validCLim = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'CLim',defaultCLim,validCLim);

%color limits
defaultDiffCLim = [-100 100];
validDiffCLim = @(x) isnumeric(x) && isequal(size(x), [1,2]);
addParameter(p,'DiffCLim',defaultDiffCLim,validDiffCLim);

%Normalize colors to exposure
defaultScaleToExposure = false;
validScaleToExposure = @(x) islogical(x) && isscalar(x);
addParameter(p,'ScaleToExposure',defaultScaleToExposure,validScaleToExposure);

%colormap
defaultColormap = @magma;
validColormap = @(x) isa(x,"function_handle");
addParameter(p,'Colormap',defaultColormap,validColormap);

%colormap
defaultDiffColormap = @(x) flipud(brewermap(x,'RdBu'));
addParameter(p,'DiffColormap',defaultDiffColormap,validColormap);

%Sample Set (e.g. user)
defaultSampleSet = [];
validSampleSet = @(x) isstring(x);
addParameter(p,'SampleSet',defaultSampleSet,validSampleSet);

% %OutputFilename
% defaultOutputFilename = num2str(imgnum);
% validOutputFilename = @(x) isstring(x);
% addOptional(p,'OutputFilename',defaultOutputFilename,validOutputFilename);

%SampleName
defaultSampleName = "";
validSampleName = @(x) isstring(x);
addParameter(p,'SampleName',defaultSampleName,validSampleName);

%Sample Table
defaultSampleTable = "sampleTable.mat";
validSampleTable = @(x) isstring(x);
addParameter(p,'SampleTable',defaultSampleTable,validSampleTable);

%plotFormat
defaultPlotFormat = "png";
validPlotFormat = @(x) strcmp(x,"png") || strcmp(x,"pdf");
addParameter(p,'PlotFormat',defaultPlotFormat,validPlotFormat);

%subtract data
defaultSubtractData = [];
addParameter(p,'SubtractData',defaultSubtractData);

%subtract data coefficient
defaultSubtractionCoefficient = 1;
validSubtractionCoefficient = @(x) isnumeric(x);
addParameter(p,'SubtractionCoefficient',defaultSubtractionCoefficient,validSubtractionCoefficient);

%plot scale
defaultPlotScale = "log";
validPlotScale = @(x) strcmp(x,"linear") || strcmp(x,"log");
addParameter(p,'PlotScale',defaultPlotScale,validPlotScale);

%Plot Style Linecut
defaultPlotStyleLinecut = "HalfCol";
validPlotStyleLinecut = @(x) isstring(x);
addParameter(p,'PlotStyleLinecut',defaultPlotStyleLinecut,validPlotStyleLinecut)

%Plot Style GIWAXS
defaultPlotStyleGIWAXS = "GIWAXS";
validPlotStyleGIWAXS = @(x) isstring(x);
addParameter(p,'PlotStyleGIWAXS',defaultPlotStyleGIWAXS,validPlotStyleGIWAXS)


if istable(sampleTableRowOrImgNum)
    if height(sampleTableRowOrImgNum) == 1
        sampleTableRow = sampleTableRowOrImgNum;
        imgNum = sampleTableRow.ImageNum;
    else
        throw(MException("giwaxsProcess:TooManySamples","First parameter must a single sampleTable row"))
    end
elseif isnumeric(sampleTableRowOrImgNum)
    imgNum = sampleTableRowOrImgNum;
else
    throw(MException("giwaxsProcess:InvalidInput","First parameter must be imgNum or a single sampleTable row"))
end

parse(p,varargin{:});


% Create a new gixsdata object from parameter file
if ~strcmp(p.Results.ParameterFile,"")
    loaded_params = load(p.Results.ParameterFile);
elseif exist('sampleTableRow')
    loaded_params = load(getParams(sampleTableRow.BeamEnergy));
else
    throw(MException("giwaxsProcess:NoParameterFile","Must specify parameter file if processing using imgnum"))
end

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


%If just specifying imgNum, we need to load the sampleTable from file
if ~exist('sampleTableRow')
%load sample table and extract correct row
    try
        load(p.Results.SampleTable);
        %find imgNum entry in sampleTable
        sampleInd = find(sampleTable.ImageNum == imgNum);
        sampleTable = sampleTable(sampleInd,:);
    catch
        try
            load(strcat(p.Results.SampleTable),'.mat');
            %find imgNum entry in sampleTable
            sampleInd = find(sampleTable.ImageNum == imgNum);
            sampleTable = sampleTable(sampleInd,:);
        catch
            warning("No sample table loaded");
        end
    end
else
    sampleTable = sampleTableRow;
end

%if sampleTable exists...
if exist('sampleTable') && height(sampleTable) == 1

    
    %extract sample details and create detailed filename
    sampleName = sampleTable.SampleName;
    attenuation = sampleTable.Attenuation;
    exposureTime = sampleTable.ExposureTime;
    data.IncidentAngle = sampleTable.IncidenceAngle;

    %set output filename
    outputFilename = strcat(sampleName,"_",...
        num2str(attenuation),"att_",...
        num2str(exposureTime),"sExp_",...
        num2str(imgNum));

    %if temperature is given, add this to filename
    if ~isnan(sampleTable.Temperature)
        sampleTemp = sampleTable.Temperature;
        
        outputFilename = strcat(outputFilename,"_",num2str(sampleTemp),"K");
    end

    %set append output path to user name
    if ~isempty(sampleTable.SampleSet)
        outputPath = fullfile(p.Results.OutputPath,sampleTable.SampleSet);
    end

    %update color limits to exposure conditions if given
    if p.Results.ScaleToExposure
        colorLimits = getCLims(colorLimits,attenuation,exposureTime,p.Results.PlotScale);
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

% If no TIF found, check for HDF5 (.hdf5 or .h5)
if isempty(imgfile)
    hdf5list = [dir(fullfile(p.Results.ImagePath,"*.hdf5")); ...
                dir(fullfile(p.Results.ImagePath,"*.h5"))];
    hdf5names = {hdf5list.name};
    hdf5ind = contains(hdf5names, num2str(imgNum));
    hdf5files = hdf5names(hdf5ind);
    if isscalar(hdf5files)
        hdf5FullPath = string(fullfile(p.Results.ImagePath, hdf5files{1}));
        imgfile = hdf5files;
        isHDF5 = true; %#ok<NASGU> tested via exist() below
    elseif length(hdf5files) > 1
        ME = MException("GIWAXSProcess:TooManyImages","More than one HDF5 file found matching imgnum");
        throw(ME)
    end
end

%if we have 2 image files matching imgNum, gap fill the images
if length(imgfile) == 2
    %sort
    imgfile = sort(imgfile);

    %gap fill
    filledImg = mgapfillArb(fullfile(p.Results.ImagePath,imgfile{1}),fullfile(p.Results.ImagePath,imgfile{2}));
    imagesc(filledImg)

    %save the gap filled data in outputPath
    if p.Results.SaveData
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
if exist("gapFillFilename","var")
    data.ImFile = gapFillFilename;
    data.Mask = ones(size(data.ImFile));
elseif exist("isHDF5","var")
    %load the HDF5 frame directly into the gixsdata object
    [img, nFrames] = readHDF5Image(hdf5FullPath, p.Results.FrameNumber);
    if nFrames > 1 && isempty(p.Results.FrameNumber)
        warning("GIWAXSProcess:MultiFrameHDF5", ...
            "HDF5 file for image %d contains %d frames; processing frame 1. " + ...
            "Pass FrameNumber to select another.", imgNum, nFrames);
    end
    data.RawData = img;

    %save the extracted frame as TIFF alongside the other outputs
    if p.Results.SaveData
        writeInt32TIFF(img, fullfile(outputPath, strcat(outputFilename, ".tif")));
    end
else
    data.ImFile = char(fullfile(p.Results.ImagePath,imgfile{1}));
end


%derive Beam0, SDD and beam energy from the .dat metadata + calibrations.
%lowest automatic precedence: the sample table and Beam0/SDD arguments below
%override these values. Warns and falls back if metadata/calibration missing.
if p.Results.UseCalibration
    metaPath = p.Results.MetadataPath;
    if metaPath == ""
        metaPath = p.Results.ImagePath;
    end
    setGeometryFromCalibration(data, imgNum, metaPath, ...
        p.Results.Beam0CalFile, p.Results.SDDCalFile);
end

%if beam0 is given in sample table use this value
try
    beam0 = sampleTable.Beam0;
    b0exists = ~isnan(beam0);
    if and(b0exists(1),b0exists(2))
        data.Beam0 = beam0;
        data.Specular = data.Beam0 - [0 1];
    end
catch
    warning(strcat("No Beam0 specified in Sample Table, using default value from parameters"))
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

%SDD given as argument overrides the calibration-derived value
if ~isempty(p.Results.SDD)
    data.SDD = p.Results.SDD;
end

%update q maps if Beam0 or specular have changed
qmaps(data);


%subtract background data if provided
if ~isempty(p.Results.SubtractData)
    plotDiffImages = true;
    %process background image identically to sample image
    %bkgdata = giwaxsProcess(p.Results.SubtractImgNum,varargin{:})

    %take difference normalized to background intensity.
    data.RawData = 100.*(data.RawData - ...
        p.Results.SubtractionCoefficient.*p.Results.SubtractData.RawData)...
        ./ p.Results.SubtractData.RawData;
else
    plotDiffImages = false;
end



%% Display the image with qz qy axis
if p.Results.MakePlots

    if plotDiffImages
        data.PlotAxisLabel = 1; %linear scaling
        figure
        imagesc(data);
        caxis(p.Results.DiffCLim)
        colormap(feval(p.Results.DiffColormap,1000));
        title('')
        c = colorbar
        c.Label.String = "Intensity change (%)";

        if p.Results.SaveData
            f = gcf;
            figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern"));
            s = hgexport('readstyle',p.Results.PlotStyleGIWAXS);
            s.Format = 'pdf';
            hgexport(f,figFilename,s);
            savefig(f,strcat(figFilename,".fig"),'compact');
        end


    else
        data.PlotAxisLabel = 2; 
        figure
        imagesc(data);
        caxis(colorLimits);
        colormap(feval(p.Results.Colormap,1000))
        title('')
        if p.Results.SaveData
            f = gcf;
            figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern"));
            s = hgexport('readstyle',p.Results.PlotStyleGIWAXS);
            s.Format = 'pdf';
            hgexport(f,figFilename,s);
            savefig(f,strcat(figFilename,".fig"),'compact');
        end
    end
end
%% Reshape
if p.Results.Reshape && ~plotDiffImages
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
    if p.Results.MakePlots
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
        
        
        if p.Results.SaveData
            f = gcf;
            figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern_reshape"));
            s = hgexport('readstyle',p.Results.PlotStyleGIWAXS);
            s.Format = 'pdf';
            hgexport(f,figFilename,s);
            savefig(f,strcat(figFilename,".fig"),'compact');
        end
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
    if p.Results.MakePlots
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
        
        
        if p.Results.SaveData
            f = gcf;
            figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern_interpolated"));
            s = hgexport('readstyle',p.Results.PlotStyleGIWAXS);
            s.Format = 'pdf';
            hgexport(f,figFilename,s);
            savefig(f,strcat(figFilename,".fig"),'compact');
        end
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

if p.Results.DoLinecuts

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
if p.Results.MakePlots
    figure
    plot(x,y)
    xlabel('q_y (A^{-1})');
    ylabel('Intensity (a.u.)');
    axis tight
end

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
if p.Results.SaveData
    %save data to ascii file
    IPlinecut_data = [x,y];
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_Qy",...
        num2str(p.Results.IPCutQ(1)),"to",num2str(p.Results.IPCutQ(2)),".txt")),...
        'IPlinecut_data','-ascii');

    %safe full data struct with fit to .mat file
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_Qy",...
        num2str(p.Results.IPCutQ(1)),"to",num2str(p.Results.IPCutQ(2)),".mat")),...
        'IPlinecut');
    
    if p.Results.MakePlots
        %save fit plot to file
        f = gcf;
        figFilename = fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_plot"));
        s = hgexport('readstyle',p.Results.PlotStyleLinecut);
        s.Format = 'pdf';
        hgexport(f,figFilename,s);
    end
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
if p.Results.MakePlots
    figure
    semilogy(x,y)
    xlabel('q_z (A^{-1})');
    ylabel('Intensity (a.u.)');
    axis tight
end

%% OOP linecut fitting
if p.Results.OOPFit ~= ""
    OOPlinecut.fitFun = p.Results.OOPFit;
    fitFuncCall = strcat(p.Results.OOPFit,"(x, y)");
    [OOPlinecut.fit, OOPlinecut.gof] = eval(fitFuncCall);
    
    OOPlinecut.coeffs = coeffvalues(OOPlinecut.fit);
    OOPlinecut.coeffNames = coeffnames(OOPlinecut.fit);
end

%% Save OOPlane linecut to ASCII file
if p.Results.SaveData
    %save data to ascii file
    OOPlinecut_data = [x,y];
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_Qx",...
        num2str(p.Results.OOPCutQ(1)),"to",num2str(p.Results.OOPCutQ(2)),".txt")),...
        'OOPlinecut_data','-ascii');

    %safe full data struct with fit to .mat file
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_Qx",...
        num2str(p.Results.OOPCutQ(1)),"to",num2str(p.Results.OOPCutQ(2)),".mat")),...
        'OOPlinecut');
    
    if p.Results.MakePlots
        %save fit plot to file
        f = gcf;
        figFilename = fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_plot"));
        s = hgexport('readstyle',p.Results.PlotStyleLinecut);
        s.Format = 'pdf';
        hgexport(f,figFilename,s);
    end
end
end

%% Save processed gixsgui file so we can reopen it later if needed
if p.Results.SaveData
    save(fullfile(outputPath,strcat(outputFilename,"_gixsguiData.mat")),'data')
end

end

