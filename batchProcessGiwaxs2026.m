clear all
clc
close all

%% Paths
%Make sure the analysis code (and its Support Functions / Calibration
%Scripts) is on the MATLAB path. This script lives in the GIWAXS-Analysis
%folder, so derive the location from itself.
analysisDir = fileparts(mfilename('fullpath'));
addpath(genpath(analysisDir));

%% Beamtime
%Root of the beamtime data. This is the only path to set; every other path
%(raw data, output, sample table, calibrations, corrections) is derived from
%it by beamtimeConfig. SampleTable loads this beamtime's sample log.
beamtimeDir = "/Users/ianjacobs/Physics_Cambridge Dropbox/Dr I.E. Jacobs/Research/GIWAXS/February 2026 Beamtime";
data = SampleTable(beamtimeDir);

%% Data selection
%Pick the subset of measurements to process. Selection methods chain, e.g.:
%   subset = data.bySampleSet("Ian").bySample("1 PBTTT Undoped");
%   subset = data.byAttenuation(0);
%   subset = data.select('SampleSet',"Ian", 'IncidenceAngle',0.15);
%Use data.users() and data.samples() to see what is available.
subset = data.byImage(620152:620159);   %test set: Ian "1 PBTTT Undoped" mirror-8

%% Processing parameters
%Color limits for diffraction images; automatically scaled for attenuation
%and exposure time (set ScaleToExposure false to turn that off).
processPars.CLim = [1 10000];
processPars.ScaleToExposure = true;

%Colormap (function handle to the generating function).
processPars.Colormap = @magma;

processPars.IPCutQ = [0.1 0.12];

%q range and size (pixels) for the reshaped diffraction images.
processPars.ReshapeQr = [-0.5 3];
processPars.ReshapeQz = [0 3];
processPars.ReshapePoints = [1000,1000];

%Figure output format: "png" (high resolution raster) or "pdf" (vector).
processPars.PlotFormat = "png";

%Master save switch; set false to process without writing anything.
processPars.SaveData = true;

%When gap-filling, "average" both images where they overlap, or keep the
%"base" image and use the partner only to fill its gaps.
processPars.GapFillMode = "average";

%The large outputs are off by default to save disk space:
%  SaveProcessedData - the full gixsdata object (~80-90 MB/image)
%  SaveFig           - editable MATLAB .fig figures
processPars.SaveProcessedData = false;
processPars.SaveFig = false;

%Process the images across a parallel pool (parfor; needs the Parallel
%Computing Toolbox). Worth it for large batches; for a few images the pool
%startup outweighs the gain. Pool figures are not displayed.
processPars.Parallel = true;

%NOTE: there are additional parameters you can specify if necessary, see
%the giwaxsProcess function.

%% Process
%Runs giwaxsProcess over the selection; gap-fill pairs are combined into a
%single output, so each pair is processed once.
subset.process(processPars);
