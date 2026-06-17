function data = applyDetectorCorrections(data, img, opts)
%APPLYDETECTORCORRECTIONS Apply flat field and gap/bad-pixel masks to a frame.
%   DATA = APPLYDETECTORCORRECTIONS(DATA, IMG, OPTS) loads the detector
%   correction images named in OPTS and applies them to the gixsdata object
%   DATA through gixsgui: the flat field is multiplied into the data, and the
%   module-gap and bad-pixel masks are combined into DATA.Mask. DATA is a
%   gixsdata handle object (typically a fresh copy of the parameter template);
%   it is modified in place and returned.
%
%   IMG is the detector frame (already loaded and oriented by readHDF5Image).
%
%   OPTS is a struct (pass giwaxsProcess's p.Results) with string fields:
%     FlatFieldFile - flat field image (single, multiplicative). Empty => ones.
%     GapMaskFile   - module-gap mask (1 = valid, 0 = gap). Empty => all valid.
%     BadPixelFile  - bad-pixel mask (1 = valid, 0 = bad).  Empty => all valid.
%   See detectorCorrectionConfig.m for the 2026 Pilatus 2M files.
%
%   See also giwaxsProcess, gapFillFromPartner, readHDF5Image.

% Flat field (multiplied into the data); ones if not supplied
if opts.FlatFieldFile ~= ""
    flatField = single(imread(opts.FlatFieldFile));
else
    flatField = ones(size(img), 'single');
end

% Module-gap and bad-pixel masks (1 = valid); all-valid if not supplied
gapMask = true(size(img));
if opts.GapMaskFile ~= ""
    gapMask = logical(imread(opts.GapMaskFile));
end
badMask = true(size(img));
if opts.BadPixelFile ~= ""
    badMask = logical(imread(opts.BadPixelFile));
end

% The flat field is zero in the module gaps and for ~1-2 px around them (its
% zeroed region is slightly wider than the gap mask). A pixel with a zero flat
% field has no valid correction - its corrected value is forced to 0 - so it
% must be masked too, otherwise it would count as valid and contribute 0 to a
% gap-fill average, halving the intensity in a thin ring around the gaps.
detectorMask = gapMask & badMask & (flatField > 0);

% Apply through gixsdata: gixsdata multiplies in the flat field and masks the
% gap/bad/negative pixels.
data.RawData   = img;
data.FlatField = flatField;
data.Mask      = detectorMask & (img >= 0);
end
