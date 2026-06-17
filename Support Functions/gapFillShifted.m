function [combined, combinedValid] = gapFillShifted(baseImg, partnerImg, baseValid, partnerValid, dRow, dCol, mode)
%GAPFILLSHIFTED Combine a gap-fill image pair into a single image.
%   [COMBINED, COMBINEDVALID] = GAPFILLSHIFTED(BASEIMG, PARTNERIMG, BASEVALID,
%   PARTNERVALID, DROW, DCOL, MODE) merges two exposures of the same sample
%   taken with the detector translated, so that the inter-module gaps (and bad
%   pixels) of one exposure fall on active pixels of the other.
%
%   BASEIMG/PARTNERIMG are the two (flat-field-corrected) frames and
%   BASEVALID/PARTNERVALID are their logical validity masks (true = real
%   measurement, false = gap/bad/masked). The partner is translated by
%   (DROW, DCOL): the base pixel (row, col) corresponds to the partner pixel
%   (row+DROW, col+DCOL), where the shift comes from the detector stage
%   motion (DCOL from dpsx, DROW from dpsy, divided by the pixel size).
%
%   MODE selects how pixels valid in BOTH frames are combined (default
%   "average"):
%     - "average" : mean of the two intensities (improves the statistics in
%                   the overlap region),
%     - "base"    : keep the base frame; the partner is used only to fill the
%                   base's gaps/bad pixels (matches gixsgui's gapfill).
%   For pixels valid in only one frame, that frame is used (the gap fill); for
%   pixels valid in neither, the output is NaN (stays masked). COMBINEDVALID is
%   true wherever at least one frame contributed.
%
%   See also giwaxsProcess, gapFillFromPartner.

if nargin < 7 || strlength(mode) == 0
    mode = "average";
end

[nr, nc] = size(baseImg);

% For every base pixel, find the matching (translated) partner pixel
[colGrid, rowGrid] = meshgrid(1:nc, 1:nr);
partnerRow = rowGrid + dRow;
partnerCol = colGrid + dCol;
inBounds   = partnerRow >= 1 & partnerRow <= nr & partnerCol >= 1 & partnerCol <= nc;

% Resample the partner image and its validity onto the base grid
partnerOnBase      = nan(nr, nc);
partnerValidOnBase = false(nr, nc);
srcIdx = sub2ind([nr nc], partnerRow(inBounds), partnerCol(inBounds));
partnerOnBase(inBounds)      = partnerImg(srcIdx);
partnerValidOnBase(inBounds) = partnerValid(srcIdx);

% Classify each pixel by which frames have a valid measurement there
bothValid   = baseValid & partnerValidOnBase;
baseOnly    = baseValid & ~partnerValidOnBase;
partnerOnly = ~baseValid & partnerValidOnBase;

combined = nan(nr, nc);
if strcmp(mode, "base")
    combined(bothValid) = baseImg(bothValid);                                  % keep base frame
else
    combined(bothValid) = (baseImg(bothValid) + partnerOnBase(bothValid)) / 2; % average overlap
end
combined(baseOnly)    = baseImg(baseOnly);
combined(partnerOnly) = partnerOnBase(partnerOnly);

combinedValid = baseValid | partnerValidOnBase;
end
