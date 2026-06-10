function SDD_mm = getSDDFromParams(params, sddCal)
% Return the sample-to-detector distance (SDD) for a measurement from its
% dpsz2 position.
%
% calibrateSDD.m fits SDD against the detector stage position dpsz2 from a
% set of silver behenate ring measurements and saves the linear relation in
% sdd_calibration.mat. This function applies that calibration to a single
% measurement:
%
%   SDD = polyval(sddCal.coeffs, dpsz2)
%
% Inputs:
%   params - parameter struct loaded from a .dat file (readDatParams) or
%            .nxs file. Must contain a dpsz2 field (detector stage position,
%            mm). A bare numeric dpsz2 value is also accepted.
%   sddCal - calibration source (optional). Either an sddCal struct (as
%            saved by calibrateSDD.m) or the path to the .mat file that
%            contains it. Defaults to "sdd_calibration.mat" on the path.
%
% Output:
%   SDD_mm - sample-to-detector distance in mm. If dpsz2 holds N values,
%            SDD_mm is N-by-1 (one per value).
%
% Example:
%   params = readDatParams("scan-617700.dat");
%   SDD    = getSDDFromParams(params, "sdd_calibration.mat");
%
% See also getBeam0FromParams.

arguments
    params
    sddCal = "sdd_calibration.mat"
end

% Resolve the dpsz2 value(s) from the params struct (or accept it directly)
if isstruct(params)
    if ~isfield(params, 'dpsz2')
        error('getSDDFromParams:noDpsz2', ...
            'params has no "dpsz2" field; cannot determine SDD.');
    end
    dpsz2 = double(params.dpsz2);
elseif isnumeric(params)
    dpsz2 = double(params);
else
    error('getSDDFromParams:badParams', ...
        'params must be a struct or numeric dpsz2 value.');
end

% Resolve the calibration (load from file if a path was given)
if ischar(sddCal) || isstring(sddCal)
    calData = load(sddCal, 'sddCal');
    sddCal  = calData.sddCal;
elseif ~isstruct(sddCal)
    error('getSDDFromParams:badCal', ...
        'sddCal must be a struct or a path to the calibration .mat file.');
end

if any(isnan(sddCal.coeffs))
    error('getSDDFromParams:noFit', ...
        ['The SDD calibration has no dpsz2 fit (needs >=2 AgBe runs). ', ...
         'Re-run calibrateSDD.m with multiple runs.']);
end

% Apply the linear calibration
SDD_mm = polyval(sddCal.coeffs, dpsz2(:));
end
