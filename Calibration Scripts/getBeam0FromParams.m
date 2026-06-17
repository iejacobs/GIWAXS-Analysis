function beam0 = getBeam0FromParams(params, beam0Cal)
% Return the beam centre (beam0) for a measurement from its dpsz2 position.
%
% The beam0 position drifts linearly with the detector stage position
% dpsz2. calibrateBeam0.m fits that relationship and saves the coefficients
% in beam0_calibration.mat, along with the reference detector x/y stage
% positions (refDpsx, refDpsy) at which beam0 was calibrated. This function
% applies that calibration to a single measurement, additionally shifting
% beam0 for any difference in the detector x/y position (dpsx, dpsy):
%
%   beam0_x = polyval(coeffsX, dpsz2) - (dpsx - refDpsx)/pixelSize_mm
%   beam0_y = polyval(coeffsY, dpsz2) - (dpsy - refDpsy)/pixelSize_mm
%
% Inputs:
%   params   - parameter struct loaded from a .dat file (readDatParams) or
%              .nxs file. Must contain a dpsz2 field (detector stage
%              position, mm); dpsx and dpsy (detector x/y positions, mm) are
%              used for the translation shift when present. A bare numeric
%              dpsz2 value is also accepted (no x/y shift applied).
%   beam0Cal - calibration source (optional). Either a beam0Cal struct (as
%              saved by calibrateBeam0.m) or the path to the .mat file that
%              contains it. Defaults to "beam0_calibration.mat" on the path.
%
% Output:
%   beam0    - [x, y] beam centre in detector pixels. If dpsz2 holds N
%              values, beam0 is N-by-2 (one row per value).
%
% Example:
%   params = readDatParams("scan-617694.dat");
%   beam0  = getBeam0FromParams(params, "beam0_calibration.mat");

arguments
    params
    beam0Cal = "beam0_calibration.mat"
end

% Resolve dpsz2 (and, when available, dpsx/dpsy) from the params struct
dpsx = [];
dpsy = [];
if isstruct(params)
    if ~isfield(params, 'dpsz2')
        error('getBeam0FromParams:noDpsz2', ...
            'params has no "dpsz2" field; cannot determine beam0.');
    end
    dpsz2 = double(params.dpsz2);
    if isfield(params, 'dpsx')
        dpsx = double(params.dpsx);
    end
    if isfield(params, 'dpsy')
        dpsy = double(params.dpsy);
    end
elseif isnumeric(params)
    dpsz2 = double(params);
else
    error('getBeam0FromParams:badParams', ...
        'params must be a struct or numeric dpsz2 value.');
end

% Resolve the calibration (load from file if a path was given)
if ischar(beam0Cal) || isstring(beam0Cal)
    calData = load(beam0Cal, 'beam0Cal');
    beam0Cal = calData.beam0Cal;
elseif ~isstruct(beam0Cal)
    error('getBeam0FromParams:badCal', ...
        'beam0Cal must be a struct or a path to the calibration .mat file.');
end

% Apply the linear calibration: beam0 = polyval(coeffs, dpsz2)
dpsz2 = dpsz2(:);
beam0 = [polyval(beam0Cal.coeffsX, dpsz2), polyval(beam0Cal.coeffsY, dpsz2)];

% Shift for detector x/y translation relative to the calibration reference.
% A +mm move of the detector stage shifts the direct beam to a higher pixel
% (verified against the 620151 direct-beam frame: beam moves from the
% calibration's [219.7,1657.7] to [230,1647] as dpsx/dpsy change), hence the
% addition. (Skipped if dpsx/dpsy or the reference are absent.)
px = beam0Cal.pixelSize_mm;
if ~isempty(dpsx) && isfield(beam0Cal, 'refDpsx')
    beam0(:,1) = beam0(:,1) + (dpsx(:) - beam0Cal.refDpsx) / px;
end
if ~isempty(dpsy) && isfield(beam0Cal, 'refDpsy')
    beam0(:,2) = beam0(:,2) + (dpsy(:) - beam0Cal.refDpsy) / px;
end
end
