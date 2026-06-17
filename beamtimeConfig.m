function cfg = beamtimeConfig(beamtimeDir)
%BEAMTIMECONFIG File paths for a GIWAXS beamtime, derived from its root folder.
%   CFG = BEAMTIMECONFIG(BEAMTIMEDIR) returns a struct of all the paths used by
%   the batch script and by giwaxsProcess, derived from the beamtime root
%   BEAMTIMEDIR:
%     ImagePath       - raw HDF5 + co-located .dat metadata (the visit folder)
%     OutputPath      - processed-data output (per-user subfolders)
%     SampleTableFile - the beamtime's sample table
%     Beam0CalFile, SDDCalFile - geometry calibrations (beam centre, SDD)
%     ParameterFile   - gixsdata detector template
%     FlatFieldFile, GapMaskFile, BadPixelFile - Pilatus 2M correction images
%                       (shared), applied through gixsdata
%
%   The raw-data visit subfolder and the sample table are auto-detected (each
%   must be unique under the beamtime). Beam0/SDD/parameter use the standard
%   names in the standard subfolders; the shared correction images are fixed
%   below. Edit those entries if a beamtime's layout or detector differs.
%
%   See also giwaxsProcess.

arguments
    beamtimeDir (1,1) string
end

metaDir = fullfile(beamtimeDir, "Sample Metadata and Parameter Files");

%% Data and output
% Raw-data visit subfolder: the single directory under "Raw Data"
rawDir = fullfile(beamtimeDir, "Raw Data");
visit  = dir(rawDir);
visit  = visit([visit.isdir] & ~ismember({visit.name}, {'.','..'}));
if numel(visit) ~= 1
    error("beamtimeConfig:visit", ...
        "Expected exactly one visit subfolder under ""%s"", found %d.", rawDir, numel(visit));
end
cfg.ImagePath = fullfile(rawDir, visit.name);

% Processed data is saved in a per-user subfolder here
cfg.OutputPath = fullfile(beamtimeDir, "Processed Data");

% Sample table: the single sampleTable*.mat in the metadata folder
st = dir(fullfile(metaDir, "sampleTable*.mat"));
if numel(st) ~= 1
    error("beamtimeConfig:sampleTable", ...
        "Expected exactly one sampleTable*.mat in ""%s"", found %d.", metaDir, numel(st));
end
cfg.SampleTableFile = fullfile(metaDir, st.name);

%% Geometry calibration and detector template
cfg.Beam0CalFile  = fullfile(beamtimeDir, "Calibration Data", "beam0_calibration.mat");
cfg.SDDCalFile    = fullfile(beamtimeDir, "Calibration Data", "sdd_calibration.mat");
% energy-agnostic gixsdata template (pixel size, geometry; beam0/SDD/energy are
% NaN and filled per image from the .dat metadata + calibration at run time)
cfg.ParameterFile = fullfile(metaDir, "pilatus2.mat");

%% Pilatus 2M detector correction images (shared), applied through gixsdata
detectorCorrectionImages = "/Users/ianjacobs/Physics_Cambridge Dropbox/Dr I.E. Jacobs/Research/GIWAXS/Pilatus2m";

% Flat field (single precision, multiplicative; mean ~0.9, 0 inside the gaps)
cfg.FlatFieldFile = fullfile(detectorCorrectionImages, "Pilatus2m_I07_July24_flatfield.tif");

% Detector module-gap mask (logical, 1 = valid pixel, 0 = gap).
% Padded variants that also mask the noisy gap-edge pixels are available in
% the same folder: pilatus2m_mask_padded1px.tif / pilatus2m_mask_padded2px.tif
cfg.GapMaskFile = fullfile(detectorCorrectionImages, "pilatus2m_mask_padded2px.tif");

% Bad-pixel mask (logical, 1 = valid pixel, 0 = bad/dead pixel). Updated from
% the July-2024 map to also flag the 3 stuck/hot pixels at [1657, 749:751]
% (always at the overflow value) found in the Feb-2026 data.
cfg.BadPixelFile = fullfile(detectorCorrectionImages, "Pilatus2m_I07_Feb26_badPixels.tif");
end
