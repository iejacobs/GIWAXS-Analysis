function [data, IPlinecut, OOPlinecut, processedImage] = giwaxsProcess(sampleTableRowOrImgNum,varargin)
%INITIALPROCESS Summary of this function goes here
%   Detailed explanation goes here

%ensure bundled helper folders are on the path (Support Functions, and the
%geometry-calibration functions used when UseCalibration is true)
fnDir = fileparts(mfilename('fullpath'));
addpath(fullfile(fnDir,'Support Functions'), fullfile(fnDir,'Calibration Scripts'));

%ensure the external toolbox dependencies are on the path, regardless of how
%this function is called: the gixsgui toolbox (gixsdata class, copyhobj,
%reshape_image, linecut, ...) and the magma colormap. Adjust these locations
%if the toolboxes are installed elsewhere.
gixsguiDir  = "/Users/ianjacobs/Physics_Cambridge Dropbox/Dr I.E. Jacobs/Research/Github/GIXSGUI";
colormapDir = "/Users/ianjacobs/Physics_Cambridge Dropbox/Dr I.E. Jacobs/Research/MATLAB/Utilities/matplotlib";
if isfolder(gixsguiDir)
    addpath(genpath(gixsguiDir));
end
if isfolder(colormapDir)
    addpath(colormapDir);
end

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

%Beamtime root folder. If set, the file paths below (and ParameterFile,
%Beam0CalFile, SDDCalFile) are read from beamtimeConfig.m in this folder's
%"Sample Metadata and Parameter Files" subfolder, filling in any not passed
%explicitly. See beamtimeConfig.
defaultBeamtime = "";
validBeamtime = @(x) isstring(x) && isscalar(x);
addParameter(p,'Beamtime',defaultBeamtime,validBeamtime);

%Detector correction images (applied through gixsdata). Empty => not applied.
%FlatField is multiplied into the data; the gap mask and bad-pixel mask
%(1=valid, 0=invalid) are combined into data.Mask. See beamtimeConfig.m.
defaultCorrectionFile = "";
validCorrectionFile = @(x) isstring(x) && isscalar(x);
addParameter(p,'FlatFieldFile',defaultCorrectionFile,validCorrectionFile);
addParameter(p,'GapMaskFile',defaultCorrectionFile,validCorrectionFile);
addParameter(p,'BadPixelFile',defaultCorrectionFile,validCorrectionFile);

%How to combine a gap-fill pair: "average" the overlap (default) or keep the
%"base" image and use the partner only to fill its gaps/bad pixels.
defaultGapFillMode = "average";
validGapFillMode = @(x) (isstring(x) || ischar(x)) && ismember(string(x),["average","base"]);
addParameter(p,'GapFillMode',defaultGapFillMode,validGapFillMode);

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

%save data (master switch for writing any output)
defaultSave = true;
validSave = @(x) islogical(x) && isscalar(x);
addParameter(p,'SaveData',defaultSave,validSave);

%save the full processed gixsdata object (<name>_gixsguiData.mat). This file
%is large (~80-90 MB/image: all q-maps + corrected data), so it is off by
%default; the lightweight PNGs and linecut text/data are still written.
defaultSaveProcessedData = false;
addParameter(p,'SaveProcessedData',defaultSaveProcessedData,validSave);

%save editable MATLAB figures (.fig). These are also large, so off by
%default; the PNG (or PDF) images are still written.
defaultSaveFig = false;
addParameter(p,'SaveFig',defaultSaveFig,validSave);

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

% Resolve the beamtime file paths. They may be passed explicitly, but when
% beamtime is given they are derived from beamtimeConfig(beamtime) (see
% beamtimeConfig) and used to fill in any path the caller did not set
% explicitly - so the batch script only has to specify beamtime.
opts = p.Results;
configFields = {'ImagePath','OutputPath','Beam0CalFile','SDDCalFile', ...
                'ParameterFile','FlatFieldFile','GapMaskFile','BadPixelFile'};
if opts.Beamtime ~= ""
    cfg = beamtimeConfig(opts.Beamtime);
    for ci = 1:numel(configFields)
        f = configFields{ci};
        if any(strcmp(p.UsingDefaults, f)) && isfield(cfg, f)
            opts.(f) = cfg.(f);
        end
    end
end

% Create a new gixsdata object from parameter file
if ~strcmp(opts.ParameterFile,"")
    loaded_params = load(opts.ParameterFile);
elseif exist('sampleTableRow')
    loaded_params = load(getParams(sampleTableRow.BeamEnergy));
else
    throw(MException("giwaxsProcess:NoParameterFile","Must specify parameter file if processing using imgnum"))
end

data = copyhobj(loaded_params.params);

%load color limits
colorLimits = opts.CLim;

%set linear or log color scale
if strcmp(opts.PlotScale,"log")
    data.PlotScale = 2;
    colorLimits = log10(colorLimits);
else
    data.PlotScale = 1;
end

%sets output folder
outputPath = opts.OutputPath;


%If just specifying imgNum, we need to load the sampleTable from file
if ~exist('sampleTableRow')
%load sample table and extract correct row
    try
        load(opts.SampleTable);
        %find imgNum entry in sampleTable
        sampleInd = find(sampleTable.ImageNum == imgNum);
        sampleTable = sampleTable(sampleInd,:);
    catch
        try
            load(strcat(opts.SampleTable),'.mat');
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
        outputPath = fullfile(opts.OutputPath,sampleTable.SampleSet);
    end

    %NB: colour-limit scaling to transmission/exposure happens later, once
    %the .dat metadata has been read (see the ScaleToExposure block below)


else
    %if not in sample table, use given sample name (defaults to imgNum if
    %unspecified)
    sampleName = opts.SampleName;

    if isempty(sampleName)
        outputFilename = num2str(imgNum);
    else
        outputFilename = strcat(sampleName,"_",imgNum);
    end
end

%if a different sample set is specified append subfolder to this path
if ~isempty(opts.SampleSet)
    %redefine outputpath to save in user folder if specified
    outputPath = fullfile(opts.OutputPath,opts.SampleSet);
end

%create folder if needed
if ~isfolder(outputPath)
    mkdir(outputPath);
end


%%Find image file(s)%%
%get list of tif files in ImagePath and find files matching imgnum
filelist = dir(fullfile(opts.ImagePath,"*.tif"));
filename = {filelist.name};
sampleInd = contains(filename,num2str(imgNum));
imgfile = filename(sampleInd);

% If no TIF found, check for HDF5 (.hdf5 or .h5)
if isempty(imgfile)
    hdf5list = [dir(fullfile(opts.ImagePath,"*.hdf5")); ...
                dir(fullfile(opts.ImagePath,"*.h5"))];
    hdf5names = {hdf5list.name};
    hdf5ind = contains(hdf5names, num2str(imgNum));
    hdf5files = hdf5names(hdf5ind);
    if isscalar(hdf5files)
        hdf5FullPath = string(fullfile(opts.ImagePath, hdf5files{1}));
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
    filledImg = mgapfillArb(fullfile(opts.ImagePath,imgfile{1}),fullfile(opts.ImagePath,imgfile{2}));
    imagesc(filledImg)

    %save the gap filled data in outputPath
    if opts.SaveData
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
    [img, nFrames] = readHDF5Image(hdf5FullPath, opts.FrameNumber);
    if nFrames > 1 && isempty(opts.FrameNumber)
        warning("GIWAXSProcess:MultiFrameHDF5", ...
            "HDF5 file for image %d contains %d frames; processing frame 1. " + ...
            "Pass FrameNumber to select another.", imgNum, nFrames);
    end

    % gap-fill partner for this row (if the sample table names one)
    partnerImageNum = NaN;
    if exist('sampleTableRow','var') && ...
            ismember('GapFillPartner', sampleTableRow.Properties.VariableNames)
        partnerImageNum = sampleTableRow.GapFillPartner;
    end

    % Apply the detector corrections (flat field + gap/bad-pixel masks via
    % gixsdata), then gap-fill from the mirror partner if there is one. Both
    % steps are factored into helpers; see applyDetectorCorrections and
    % gapFillFromPartner.
    data = applyDetectorCorrections(data, img, opts);
    [data, imageWasGapFilled] = gapFillFromPartner(data, imgNum, partnerImageNum, ...
        loaded_params.params, opts);

    %save the (gap-filled, or single) extracted frame as TIFF
    if opts.SaveData
        if imageWasGapFilled
            writeInt32TIFF(int32(round(data.RawData)), fullfile(outputPath, strcat(outputFilename, "_gapFilled.tif")));
        else
            writeInt32TIFF(img, fullfile(outputPath, strcat(outputFilename, ".tif")));
        end
    end
else
    data.ImFile = char(fullfile(opts.ImagePath,imgfile{1}));
end


%resolve the metadata folder holding <imgNum>.dat (defaults to ImagePath)
%and parse it once: both the geometry calibration and the colour-limit
%scaling (beam transmission) are derived from this metadata.
metaPath = opts.MetadataPath;
if metaPath == ""
    metaPath = opts.ImagePath;
end
datFile = fullfile(metaPath, num2str(imgNum) + ".dat");
datParams = [];
if isfile(datFile)
    datParams = readDatParams(datFile);
else
    warning("giwaxsProcess:noDat", ...
        "No metadata file ""%s"" for image %d.", datFile, imgNum);
end

%derive Beam0, SDD and beam energy from the .dat metadata + calibrations.
%lowest automatic precedence: the sample table and Beam0/SDD arguments below
%override these values. Warns and falls back if metadata/calibration missing.
if opts.UseCalibration && ~isempty(datParams)
    setGeometryFromCalibration(data, datParams, ...
        opts.Beam0CalFile, opts.SDDCalFile);
end

%scale colour limits to the acquisition conditions using the beam
%transmission from the .dat metadata ('transmission' field) and exposure
%time (1 = no attenuation, exposure 1 s in the reference).
if opts.ScaleToExposure && exist('exposureTime','var')
    if ~isempty(datParams) && isfield(datParams,'transmission')
        colorLimits = getCLims(colorLimits, datParams.transmission, ...
            exposureTime, opts.PlotScale);
    else
        warning("giwaxsProcess:noTransmission", ...
            "No 'transmission' field in metadata for image %d; " + ...
            "colour limits not scaled.", imgNum);
    end
end

%a Beam0 given in the sample table (column present and non-NaN) overrides
%the calibration-derived value. Otherwise the value set above from the
%metadata calibration is kept (setGeometryFromCalibration warns if that
%could not be determined), so no warning is needed here.
if ismember('Beam0', sampleTable.Properties.VariableNames)
    beam0 = sampleTable.Beam0;
    b0exists = ~isnan(beam0);
    if numel(b0exists) >= 2 && b0exists(1) && b0exists(2)
        data.Beam0 = beam0;
        data.Specular = data.Beam0 - [0 1];
    end
end
%update beam0 and specular if given in arguments. overwrites values given
%in sampletable!
if ~isempty(opts.Beam0)
    data.Beam0 = opts.Beam0;
    if ~isempty(opts.Specular)
        data.Specular = opts.Specular;
    else
        data.Specular = data.Beam0 - [0 1];
    end
end

%SDD given as argument overrides the calibration-derived value
if ~isempty(opts.SDD)
    data.SDD = opts.SDD;
end

%update q maps if Beam0 or specular have changed
qmaps(data);


%subtract background data if provided
if ~isempty(opts.SubtractData)
    plotDiffImages = true;
    %process background image identically to sample image
    %bkgdata = giwaxsProcess(opts.SubtractImgNum,varargin{:})

    %take difference normalized to background intensity.
    data.RawData = 100.*(data.RawData - ...
        opts.SubtractionCoefficient.*opts.SubtractData.RawData)...
        ./ opts.SubtractData.RawData;
else
    plotDiffImages = false;
end



%% Display the image with qz qy axis
if opts.MakePlots

    if plotDiffImages
        data.PlotAxisLabel = 1; %linear scaling
        figure
        imagesc(data);
        caxis(opts.DiffCLim)
        colormap(feval(opts.DiffColormap,1000));
        title('')
        c = colorbar
        c.Label.String = "Intensity change (%)";

        if opts.SaveData
            f = gcf;
            figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern"));
            exportFigure(f,figFilename,opts.PlotFormat);
            if opts.SaveFig
                savefig(f,strcat(figFilename,".fig"));
            end
        end


    else
        data.PlotAxisLabel = 2; 
        figure
        imagesc(data);
        caxis(colorLimits);
        colormap(feval(opts.Colormap,1000))
        title('')
        if opts.SaveData
            f = gcf;
            figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern"));
            exportFigure(f,figFilename,opts.PlotFormat);
            if opts.SaveFig
                savefig(f,strcat(figFilename,".fig"));
            end
        end
    end
end
%% Reshape
if opts.Reshape && ~plotDiffImages
    % --- Define reshaping parameter for (qz vs qr) 
    param_reshape.X = 6;  % qr
    param_reshape.Y = 3;  % qz
    param_reshape.XNOfPts = opts.ReshapePoints(1); % number of points for X axis
    param_reshape.YNOfPts = opts.ReshapePoints(2); % number of points for y axis
    
    param_reshape.XRange = opts.ReshapeQr;  % range for x
    param_reshape.YRange = opts.ReshapeQz;  % range for y
    
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
    if opts.MakePlots
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
        colormap(feval(opts.Colormap,1000))
        
        
        if opts.SaveData
            f = gcf;
            figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern_reshape"));
            exportFigure(f,figFilename,opts.PlotFormat);
            if opts.SaveFig
                savefig(f,strcat(figFilename,".fig"));
            end
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
if opts.Interpolate
    % --- Define reshaping parameter for (qz vs qr) 
    param_reshape.X = 5;  % qy
    param_reshape.Y = 3;  % qz
    param_reshape.XNOfPts = 800; % number of points for X axis
    param_reshape.YNOfPts = 800; % number of points for y axis
    
    param_reshape.XRange = opts.InterpQy;  % range for x
    param_reshape.YRange = opts.InterpQz;  % range for y
    
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
    if opts.MakePlots
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
        colormap(feval(opts.Colormap,1000))
        
        
        if opts.SaveData
            f = gcf;
            figFilename = fullfile(outputPath,strcat(outputFilename,"_GIWAXSpattern_interpolated"));
            exportFigure(f,figFilename,opts.PlotFormat);
            if opts.SaveFig
                savefig(f,strcat(figFilename,".fig"));
            end
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

if opts.DoLinecuts

%% Inplane linecut
% --- define constraint
constr = horzcat([1 3],opts.IPCutQ);
% --- perform linecut. 
xflag = 1;          % qy linecut
nofpts = 1000;      % number of points in the linecut
dataflag = 2;       % 2 for corrected data; 1 for masked rawdata
[x,y] = linecut(data,xflag,constr,nofpts,dataflag); %
IPlinecut.x = x;
IPlinecut.y = y;

%% plot linecut
if opts.MakePlots
    figure
    plot(x,y)
    xlabel('q_y (A^{-1})');
    ylabel('Intensity (a.u.)');
    axis tight
end

%% Inplane linecut fitting
if opts.IPFit ~= ""
    IPlinecut.fitFun = opts.IPFit;
    fitFuncCall = strcat(opts.IPFit,"(x, y)");
    [IPlinecut.fit, IPlinecut.gof] = eval(fitFuncCall);
    
    IPlinecut.coeffs = coeffvalues(IPlinecut.fit);
    IPlinecut.coeffNames = coeffnames(IPlinecut.fit);

end
    
%     d_pipi = abs(2.*pi/fc(1));
%     d_chain = abs(2.*pi/fc(2));
%     
%     g_pipi = sqrt(2.*abs(fc(3).*d_pipi))/(2.*pi)

%% Save inplane linecut
if opts.SaveData
    %save data to ascii file
    IPlinecut_data = [x,y];
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_Qy",...
        num2str(opts.IPCutQ(1)),"to",num2str(opts.IPCutQ(2)),".txt")),...
        'IPlinecut_data','-ascii');

    %safe full data struct with fit to .mat file
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_Qy",...
        num2str(opts.IPCutQ(1)),"to",num2str(opts.IPCutQ(2)),".mat")),...
        'IPlinecut');
    
    if opts.MakePlots
        %save fit plot to file
        f = gcf;
        figFilename = fullfile(outputPath,strcat(outputFilename,"_Linecut_InPlane_plot"));
        exportFigure(f,figFilename,opts.PlotFormat);
    end
end

%% OOP linecut
% --- define constraint
constr = horzcat([2 5],opts.OOPCutQ);
% --- perform linecut. 
xflag = 3;          % qy linecut
nofpts = 1000;      % number of points in the linecut
dataflag = 2;       % 2 for corrected data; 1 for masked rawdata
[x,y] = linecut(data,xflag,constr,nofpts,dataflag); %
OOPlinecut.x = x;
OOPlinecut.y = y;


%% Plot linecut
if opts.MakePlots
    figure
    semilogy(x,y)
    xlabel('q_z (A^{-1})');
    ylabel('Intensity (a.u.)');
    axis tight
end

%% OOP linecut fitting
if opts.OOPFit ~= ""
    OOPlinecut.fitFun = opts.OOPFit;
    fitFuncCall = strcat(opts.OOPFit,"(x, y)");
    [OOPlinecut.fit, OOPlinecut.gof] = eval(fitFuncCall);
    
    OOPlinecut.coeffs = coeffvalues(OOPlinecut.fit);
    OOPlinecut.coeffNames = coeffnames(OOPlinecut.fit);
end

%% Save OOPlane linecut to ASCII file
if opts.SaveData
    %save data to ascii file
    OOPlinecut_data = [x,y];
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_Qx",...
        num2str(opts.OOPCutQ(1)),"to",num2str(opts.OOPCutQ(2)),".txt")),...
        'OOPlinecut_data','-ascii');

    %safe full data struct with fit to .mat file
    save(fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_Qx",...
        num2str(opts.OOPCutQ(1)),"to",num2str(opts.OOPCutQ(2)),".mat")),...
        'OOPlinecut');
    
    if opts.MakePlots
        %save fit plot to file
        f = gcf;
        figFilename = fullfile(outputPath,strcat(outputFilename,"_Linecut_OutOfPlane_plot"));
        exportFigure(f,figFilename,opts.PlotFormat);
    end
end
end

%% Save processed gixsgui file so we can reopen it later if needed
if opts.SaveData && opts.SaveProcessedData
    %the gixsdata object holds a graphics handle, which triggers a benign
    %"figure saved to MAT-file" warning; suppress it just for this save
    warnState = warning('off','MATLAB:Figure:FigureSavedToMATFile');
    save(fullfile(outputPath,strcat(outputFilename,"_gixsguiData.mat")),'data')
    warning(warnState);
end

end


function exportFigure(f, figFilename, plotFormat)
%EXPORTFIGURE Export figure f to figFilename using the requested format.
%   Replaces the removed hgexport: PDFs are written as vector graphics, PNGs
%   at high resolution. The extension is appended from plotFormat ("png" or
%   "pdf").
if strcmp(plotFormat,"pdf")
    exportgraphics(f, strcat(figFilename,".pdf"), 'ContentType','vector');
else
    exportgraphics(f, strcat(figFilename,".png"), 'Resolution', 300);
end
end

