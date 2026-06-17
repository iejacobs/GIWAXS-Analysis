function [data, imageWasGapFilled] = gapFillFromPartner(data, imgNum, partnerImageNum, templateParams, opts)
%GAPFILLFROMPARTNER Gap-fill a corrected frame from its mirror partner.
%   [DATA, IMAGEWASGAPFILLED] = GAPFILLFROMPARTNER(DATA, IMGNUM, PARTNERIMAGENUM,
%   TEMPLATEPARAMS, OPTS) combines the already-corrected base gixsdata object
%   DATA with its gap-fill partner image. A gap-fill pair is two exposures of
%   the same sample taken with the detector translated slightly, so that the
%   inter-module gaps (and bad pixels) of one exposure fall on active pixels of
%   the other.
%
%   If PARTNERIMAGENUM is NaN, DATA is returned unchanged and IMAGEWASGAPFILLED
%   is false. Otherwise the partner HDF5 (matching PARTNERIMAGENUM in
%   OPTS.ImagePath) is loaded and corrected the same way as the base (via
%   applyDetectorCorrections, using a fresh copy of TEMPLATEPARAMS), the two
%   corrected frames are merged by gapFillShifted using OPTS.GapFillMode, and
%   DATA is repackaged with the combined image (flat field already applied, so
%   FlatField is reset to unity and Mask marks only the pixels invalid in both
%   frames). The combined image keeps the base image's geometry.
%
%   OPTS (giwaxsProcess's p.Results) provides ImagePath, MetadataPath,
%   FrameNumber, GapFillMode, and the correction-file fields used by
%   applyDetectorCorrections.
%
%   See also applyDetectorCorrections, gapFillShifted, giwaxsProcess.

imageWasGapFilled = false;
if isnan(partnerImageNum)
    return
end

% Locate the partner's HDF5 file (same folder, matching image number)
hdf5list  = [dir(fullfile(opts.ImagePath,"*.hdf5")); dir(fullfile(opts.ImagePath,"*.h5"))];
hdf5names = {hdf5list.name};
partnerFileMatch = hdf5names(contains(hdf5names, num2str(partnerImageNum)));
if ~isscalar(partnerFileMatch)
    warning("GIWAXSProcess:noPartner", ...
        "Gap-fill partner %d not found for image %d; processing single image.", ...
        partnerImageNum, imgNum);
    return
end

% Load the partner frame and apply the same detector corrections as the base
partnerImg  = readHDF5Image(string(fullfile(opts.ImagePath, partnerFileMatch{1})), opts.FrameNumber);
partnerData = applyDetectorCorrections(copyhobj(templateParams), partnerImg, opts);

% The detector translation between the two exposures determines how far a fixed
% scattering feature moves on the detector: dpsx is the horizontal stage
% (-> column shift), dpsy the vertical stage (-> row shift). Convert the
% millimetre translation to pixels using the detector pixel size.
metadataFolder = opts.MetadataPath;
if metadataFolder == ""
    metadataFolder = opts.ImagePath;
end
baseMetadata    = readDatParams(fullfile(metadataFolder, num2str(imgNum) + ".dat"));
partnerMetadata = readDatParams(fullfile(metadataFolder, num2str(partnerImageNum) + ".dat"));
pixelSizeMM       = data.PixelSize(1);
columnShiftPixels = round((partnerMetadata.dpsx - baseMetadata.dpsx) / pixelSizeMM);
rowShiftPixels    = round((partnerMetadata.dpsy - baseMetadata.dpsy) / pixelSizeMM);

% Merge the two corrected, masked frames (average or base, per opts)
[combined, combinedValid] = gapFillShifted( ...
    data.MaskedData, partnerData.MaskedData, ...
    logical(data.Mask), logical(partnerData.Mask), ...
    rowShiftPixels, columnShiftPixels, opts.GapFillMode);

% Repackage for the downstream pipeline: the flat field is already applied, so
% reset it to unity and store the combined image, masking only the pixels that
% were invalid in BOTH frames.
combined(~combinedValid) = 0;
data.RawData   = combined;
data.FlatField = ones(size(combined), 'single');
data.Mask      = combinedValid;
imageWasGapFilled = true;
end
