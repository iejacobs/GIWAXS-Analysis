function info = setGeometryFromCalibration(data, params, beam0CalFile, sddCalFile)
% Set beam centre, sample-detector distance and beam energy on a gixsdata
% object from parsed .dat metadata plus the geometry calibrations.
%
% For Diamond I07 data each measurement has a co-located <imgNum>.dat file
% holding the detector stage positions (dpsz2, dpsx, dpsy) and beam energy.
% The caller parses that file (see readDatParams) and passes the resulting
% params struct here; this helper applies the beam0 and SDD calibrations
% (see calibrateBeam0.m / calibrateSDD.m) to populate:
%
%   data.Beam0     = getBeam0FromParams(params, beam0CalFile)
%   data.Specular  = data.Beam0 - [0 1]
%   data.SDD       = getSDDFromParams(params, sddCalFile)
%   data.XEnergy   = params.dcm1energy
%
% data is a gixsdata handle object and is modified in place. Any step that
% fails (calibration error) emits a warning and is skipped, leaving the
% corresponding field at its prior value rather than throwing, so callers
% can safely fall back to other geometry sources.
%
% Inputs:
%   data         - gixsdata handle object to update
%   params       - parsed .dat metadata struct (from readDatParams)
%   beam0CalFile - path to beam0_calibration.mat (default
%                  "beam0_calibration.mat" on the MATLAB path)
%   sddCalFile   - path to sdd_calibration.mat (default
%                  "sdd_calibration.mat" on the MATLAB path)
%
% Output:
%   info - struct with fields:
%            .ok      true if at least one geometry field was set
%            .applied string array of fields set (e.g. "Beam0","SDD","XEnergy")
%
% See also getBeam0FromParams, getSDDFromParams, readDatParams.

arguments
    data
    params       (1,1) struct
    beam0CalFile (1,1) string = "beam0_calibration.mat"
    sddCalFile   (1,1) string = "sdd_calibration.mat"
end

info.ok      = false;
info.applied = strings(1, 0);

% run number, if known, makes the warnings below traceable to an image
if isfield(params, 'runNumber')
    imgLabel = num2str(params.runNumber);
else
    imgLabel = 'unknown';
end

% Beam centre from the beam0 calibration
try
    data.Beam0    = getBeam0FromParams(params, beam0CalFile);
    data.Specular = data.Beam0 - [0 1];
    info.applied(end+1) = "Beam0";
catch ME
    warning('setGeometryFromCalibration:beam0Failed', ...
        'Beam0 calibration failed for image %s: %s', imgLabel, ME.message);
end

% Sample-detector distance from the SDD calibration
try
    data.SDD = getSDDFromParams(params, sddCalFile);
    info.applied(end+1) = "SDD";
catch ME
    warning('setGeometryFromCalibration:sddFailed', ...
        'SDD calibration failed for image %s: %s', imgLabel, ME.message);
end

% Beam energy from the .dat (drives XWavelength used in q-conversion)
if isfield(params, 'dcm1energy')
    data.XEnergy = params.dcm1energy;
    info.applied(end+1) = "XEnergy";
end

info.ok = ~isempty(info.applied);
end
