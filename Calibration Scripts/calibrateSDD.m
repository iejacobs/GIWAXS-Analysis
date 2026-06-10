% calibrateSDD.m
%
% Full sample-to-detector distance (SDD) calibration from silver behenate
% (AgBe) ring measurements. For each AgBe run this chains:
%
%   readDatParams      -> beamline parameters (dpsz2, dpsx, dpsy, lambda)
%   getBeam0FromParams -> beam centre from the beam0 calibration
%   radialIntegrate    -> radial intensity profile around beam0
%   fitAgBeSDD         -> SDD from the AgBe lamellar ring positions
%
% SDD is then fitted against the detector stage position dpsz2 so that the
% distance for any future measurement can be predicted from its dpsz2:
%
%   SDD = polyval(sddCal.coeffs, dpsz2_value)
%
% Requires: beam0_calibration.mat (run calibrateBeam0.m first).
% Output:   sdd_calibration.mat (Calibration Data folder).

%% Paths
scriptDir = fileparts(mfilename('fullpath'));
BASE      = fileparts(scriptDir);
CAL_DIR   = fullfile(fileparts(BASE), 'February 2026 Beamtime', 'Calibration Data');
addpath(scriptDir);                           % calibration functions
addpath(fullfile(BASE, 'Support Functions')); % shared utilities (readDatParams, ...)

BEAM0_CAL   = fullfile(CAL_DIR, 'beam0_calibration.mat');
OUTPUT_FILE = fullfile(CAL_DIR, 'sdd_calibration.mat');

%% Parameters
PIXEL_SIZE_MM = 0.172;
AGBE_RUNS     = ["617687", "617688", "617689", "617690"];  % AgBe .dat run numbers
INTERACTIVE   = true;    % pause to confirm the AgBe ring assignment per run
MAKE_PLOTS    = true;    % per-run diagnostic plots from fitAgBeSDD

%% Checks
if ~isfile(BEAM0_CAL)
    error('calibrateSDD:noBeam0Cal', ...
        'Beam0 calibration not found: %s\nRun calibrateBeam0.m first.', BEAM0_CAL);
end

nRuns = numel(AGBE_RUNS);
dpsz2  = nan(nRuns, 1);
SDD    = nan(nRuns, 1);
SDDstd = nan(nRuns, 1);
beam0  = nan(nRuns, 2);
perRun = struct('run', {}, 'result', {});

%% Process each AgBe run
for i = 1:nRuns
    run     = AGBE_RUNS(i);
    datFile = fullfile(CAL_DIR, run + ".dat");
    imgFile = fullfile(CAL_DIR, "pilatus2-" + run + ".hdf5");

    params     = readDatParams(datFile);
    beam0(i,:) = getBeam0FromParams(params, BEAM0_CAL);
    dpsz2(i)   = params.dpsz2;

    img = double(h5read(imgFile, '/entry/data/data'));
    img = img(:,:,1);   % single-frame AgBe exposure

    [rBins, intensity] = radialIntegrate(img, beam0(i,:), PIXEL_SIZE_MM, params.dcm1lambda);

    fprintf('\n===== AgBe run %s  (dpsz2 = %.0f mm) =====\n', run, dpsz2(i));
    [SDD(i), result] = fitAgBeSDD(rBins, intensity, PIXEL_SIZE_MM, params.dcm1lambda, ...
        Interactive=INTERACTIVE, MakePlot=MAKE_PLOTS);
    SDDstd(i)        = result.SDD_std_mm;
    perRun(i).run    = run;
    perRun(i).result = result;
end

%% Fit SDD vs dpsz2
[dpsz2, order] = sort(dpsz2);
SDD    = SDD(order);
SDDstd = SDDstd(order);
beam0  = beam0(order, :);
perRun = perRun(order);

if nRuns >= 2
    coeffs = polyfit(dpsz2, SDD, 1);
    resid  = SDD - polyval(coeffs, dpsz2);
else
    coeffs = [NaN, NaN];   % need >=2 runs for a dpsz2 relation
    resid  = 0;
end

%% Save
sddCal.coeffs       = coeffs;          % SDD = coeffs(1)*dpsz2 + coeffs(2)
sddCal.dpsz2        = dpsz2;
sddCal.SDD_mm       = SDD;
sddCal.SDD_std_mm   = SDDstd;
sddCal.beam0        = beam0;
sddCal.runs         = AGBE_RUNS(order);
sddCal.pixelSize_mm = PIXEL_SIZE_MM;
sddCal.perRun       = perRun;
sddCal.beam0CalFile = string(BEAM0_CAL);
sddCal.dateCreated  = datetime('now');
save(OUTPUT_FILE, 'sddCal');

%% Report
fprintf('\n================ SDD calibration ================\n');
fprintf('%-8s  %-10s  %-14s\n', 'run', 'dpsz2 (mm)', 'SDD (mm)');
for i = 1:nRuns
    fprintf('%-8s  %-10.0f  %.2f +/- %.2f\n', ...
        sddCal.runs(i), dpsz2(i), SDD(i), SDDstd(i));
end
if nRuns >= 2
    fprintf('\nSDD = %.4f * dpsz2 + %.2f mm   (max resid %.2f mm)\n', ...
        coeffs(1), coeffs(2), max(abs(resid)));
end
fprintf('\nCalibration saved: %s\n', OUTPUT_FILE);
fprintf('Usage:  load(''sdd_calibration.mat'', ''sddCal'')\n');
fprintf('        SDD = polyval(sddCal.coeffs, dpsz2_value)\n');

%% Summary plot
if MAKE_PLOTS && nRuns >= 2
    figure('Name', 'SDD vs dpsz2')
    errorbar(dpsz2, SDD, SDDstd, 'o', MarkerFaceColor='b'); hold on
    xx = linspace(min(dpsz2), max(dpsz2), 50);
    plot(xx, polyval(coeffs, xx), 'r-')
    box on
    xlabel('dpsz2 (mm)'); ylabel('SDD (mm)')
    title(sprintf('SDD = %.4f\\cdotdpsz2 + %.2f mm', coeffs(1), coeffs(2)))
    legend('AgBe fits', 'linear fit', Location='northwest')
end
