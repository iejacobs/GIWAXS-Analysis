function [beam0, dpsz2, refDpsx, refDpsy] = findBeam0DirectBeam(hdf5File)
% Extract beam0 pixel positions from a direct beam HDF5 scan over dpsz2.
%
% Reads per-frame dpsz2 values from the paired NXS file (auto-located as
% i07-<runNum>.nxs in the same directory). For each frame where the beam
% is present (max non-masked intensity > 100 counts), computes an
% intensity-weighted centroid to find beam0.
%
% Returns:
%   beam0   - N×2 array of [x, y] beam centre positions (1-indexed pixels)
%               x = first array dimension, y = second array dimension
%   dpsz2   - N×1 vector of dpsz2 motor positions (mm), one per frame
%   refDpsx - detector x stage position (mm) during the scan. This is the
%               reference dpsx the calibrated beam0 corresponds to; a
%               measurement taken at a different dpsx is shifted accordingly.
%   refDpsy - detector y stage position (mm) during the scan (reference dpsy)
%
% Frames with no beam signal are excluded from both outputs. dpsx and dpsy
% are held fixed during a beam0 calibration scan, so the first value is
% returned as the reference.

arguments
    hdf5File (1,1) string {mustBeFile}
end

OVERFLOW = 1048575;

% Locate paired NXS file: pilatus2-XXXXXX.hdf5 → i07-XXXXXX.nxs
[folder, fname] = fileparts(hdf5File);
runNum  = regexp(fname, '(?<=-)\d+$', 'match', 'once');
nxsFile = fullfile(folder, "i07-" + runNum + ".nxs");
if ~isfile(nxsFile)
    error('findBeam0DirectBeam:noNXS', ...
        'NXS file not found: %s', nxsFile);
end

% Per-frame dpsz2 from NXS
dpsz2_all = h5read(nxsFile, '/entry/instrument/dpsz2/value');

% Reference detector x/y stage positions (held fixed during the scan)
refDpsx = double(h5read(nxsFile, '/entry/instrument/dpsx/value'));
refDpsy = double(h5read(nxsFile, '/entry/instrument/dpsy/value'));
refDpsx = refDpsx(1);
refDpsy = refDpsy(1);

% Load detector frames
raw     = h5read(hdf5File, '/entry/data/data');
nFrames = size(raw, 3);

if numel(dpsz2_all) ~= nFrames
    error('findBeam0DirectBeam:frameMismatch', ...
        'NXS has %d dpsz2 values but HDF5 has %d frames', ...
        numel(dpsz2_all), nFrames);
end

beam0 = zeros(0, 2);
dpsz2 = zeros(0, 1);

for i = 1:nFrames
    img = double(raw(:,:,i));
    img(img == OVERFLOW | img < 0) = 0;

    frameMax = max(img(:));
    if frameMax < 100
        continue
    end

    thresh = 0.5 * frameMax;
    mask   = img > thresh;
    [xi, yi] = find(mask);
    w = img(mask);
    wsum = sum(w);

    beam0(end+1, :) = [sum(xi .* w) / wsum,  sum(yi .* w) / wsum]; %#ok<AGROW>
    dpsz2(end+1)    = dpsz2_all(i);                                  %#ok<AGROW>

    fprintf('Frame %2d  dpsz2=%6.1f mm  beam0=[%.2f, %.2f]\n', ...
        i, dpsz2_all(i), beam0(end,1), beam0(end,2));
end

if isempty(beam0)
    error('findBeam0DirectBeam:noBeam', ...
        'No frames with beam signal found in %s', hdf5File);
end
end
