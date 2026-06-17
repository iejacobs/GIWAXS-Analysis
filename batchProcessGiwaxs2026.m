clear all
clc
close all

%% Paths
%Make sure the analysis code (and its Support Functions / Calibration
%Scripts) is on the MATLAB path. This script lives in the GIWAXS-Analysis
%folder, so derive the location from itself.
analysisDir = fileparts(mfilename('fullpath'));
addpath(genpath(analysisDir));

%Root of the beamtime data. This is the only path to change for a new
%beamtime; every other path is derived from it by beamtimeConfig (in
%GIWAXS-Analysis), which giwaxsProcess loads itself via the BeamtimeDir
%parameter set below.
beamtimeDir = "/Users/ianjacobs/Physics_Cambridge Dropbox/Dr I.E. Jacobs/Research/GIWAXS/February 2026 Beamtime";
processPars.Beamtime = beamtimeDir;

%The batch additionally needs the sample table to choose which images to
%process; take its path (and all others) from beamtimeConfig.
cfg = beamtimeConfig(beamtimeDir);
sampleTableFile = cfg.SampleTableFile; 

%% Data selection
%Specify data to process. Selects only data matching ALL conditions.
%Comment out any parameters which you don't wish to use. Numeric
%parameters accept a single value or a set/range (e.g. a range of image
%numbers, or [0 1] for two attenuations).

ImageNum = 620152:620159;     %test set: Ian "1 PBTTT Undoped" mirror-8
%SampleSet = "Ian"
%SampleName = "1 PBTTT Undoped"
%Attenuation = 0
%ExposureTime = 1
%IncidenceAngle = 0.15
%Temperature = 290
%BeamEnergy = 20
%Vg = 0
%Vd = 0
%ElectricalData = ""
%Notes = ""

%% Additional processing parameters

%Specify color limits for diffraction images. If current image is too dark,
%reduce these values; if too light, increase them. Note, these values are
%automatically scaled for attenuation and exposure time. To turn off
%automatic scaling set ScaleToExposure to false
processPars.CLim = [1 10000];
processPars.ScaleToExposure = true;

%Specify colormap to use in diffraction images. Give a function handle to
%the generating function (third party color maps are supported).
processPars.Colormap = @magma;

processPars.IPCutQ = [0.1 0.12];

%Specify q range for reshaped diffraction images.
processPars.ReshapeQr = [-0.8 3.2];
processPars.ReshapeQz = [0 3.2];

%Specify reshaped image size (in pixels). Too high can lead to artifacts in
%reshaped images.
processPars.ReshapePoints = [900,900];

%Figure output format: "png" (high resolution raster) or "pdf" (vector).
processPars.PlotFormat = "png";

%If you don't want to save anything, set this to false
processPars.SaveData = true;

%When gap-filling, use either the base image or average both images where
%data is valid
processPars.GapFillMode = "average";


%By default only the lightweight outputs are written (PNG images and linecut
%text/data). The large files are off by default to save disk space:
%  SaveProcessedData - the full gixsdata object (<name>_gixsguiData.mat,
%                      ~80-90 MB/image)
%  SaveFig           - editable MATLAB .fig figures
%Set either to true if you need them.
processPars.SaveProcessedData = false;
processPars.SaveFig = false;

%NOTE: there are additional parameters you can specify if necessary, see
%giwaxsProcess function.


%% Process GIWAXS data

%load sample table
load(sampleTableFile)

%get sample table matching values set above
varnames = sampleTable.Properties.VariableNames;
for i = 1:length(varnames)
    if exist(varnames{i})'
        if exist("pars")
            pars = {pars{:},varnames{i},eval(varnames{i})};
        else
             pars = {varnames{i},eval(varnames{i})};
        end
    end
end

%get matching subtable and display in console
sampleTable = getSubSampleTable(sampleTable,pars{:})

%get processing parameter list
if exist("processPars")
    processParsNames = fieldnames(processPars);
    for i = 1:length(fieldnames(processPars))
        if exist("processParsList")
            processParsList = {processParsList{:},processParsNames{i},getfield(processPars,processParsNames{i})};
        else
            processParsList = {processParsNames{i},getfield(processPars,processParsNames{i})};
        end
    end
else
    processParsList = {};
end

%process giwaxs data. Gap-fill pairs (two exposures combined into one image
%by giwaxsProcess) must only produce a single output, so once a row is
%processed its gap-fill partner is marked done and skipped.
hasGapFill = ismember('GapFillPartner', sampleTable.Properties.VariableNames);
alreadyProcessed = false(height(sampleTable),1);

for i = 1:height(sampleTable)
    if alreadyProcessed(i)
        continue
    end
    close all

    [data,ipcut,oopcut] = giwaxsProcess(sampleTable(i,:),processParsList{:});
    alreadyProcessed(i) = true;

    %if this row is half of a gap-fill pair, its partner was combined into
    %the same output - mark it processed so we don't produce a duplicate
    if hasGapFill && ~isnan(sampleTable.GapFillPartner(i))
        partnerRow = find(sampleTable.ImageNum == sampleTable.GapFillPartner(i));
        alreadyProcessed(partnerRow) = true;
    end
end
