function [rBins, intensity, qBins] = radialIntegrate(image, beam0, pixelSize_mm, wavelength_A, SDD_mm)
% Radially integrate a detector image around a beam centre.
%
% Overflow (1048575) and gap (<0) pixels are excluded from the average.
% Binning is by nearest-integer radius (1 px bins), using accumarray for
% efficiency.
%
% Inputs:
%   image        - 2D detector array (raw int32 or pre-masked double)
%   beam0        - [x, y] beam centre in 1-indexed pixel coords
%   pixelSize_mm - detector pixel size in mm (Pilatus 2: 0.172)
%   wavelength_A - X-ray wavelength in Angstrom
%   SDD_mm       - (optional) sample-detector distance in mm; if given,
%                  qBins is also returned in units of Angstrom^-1
%
% Outputs:
%   rBins     - radial bin centres (pixels), length N
%   intensity - mean intensity per radial bin, length N
%   qBins     - (optional) q values in Angstrom^-1, length N

arguments
    image        (:,:)
    beam0        (1,2) double
    pixelSize_mm (1,1) double
    wavelength_A (1,1) double
    SDD_mm       (1,1) double = NaN
end

OVERFLOW = 1048575;

img = double(image);
valid = img > 0 & img ~= OVERFLOW;

[nx, ny] = size(img);
[Y, X]   = meshgrid(1:ny, 1:nx);
radii    = sqrt((X - beam0(1)).^2 + (Y - beam0(2)).^2);

rIdx  = round(radii(valid)) + 1;   % 1-indexed bin
vals  = img(valid);
maxBin = max(rIdx);

intensity = accumarray(rIdx, vals, [maxBin, 1], @mean, 0);
rBins     = (0 : maxBin-1)';

% Convert to q if SDD given
if ~isnan(SDD_mm)
    twoTheta = atan(rBins .* pixelSize_mm ./ SDD_mm);
    qBins    = 4 .* pi .* sin(twoTheta ./ 2) ./ wavelength_A;
else
    qBins = [];
end
end
