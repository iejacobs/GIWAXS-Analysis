% calibrateBeam0.m
%
% Determine beam centre (beam0) vs dpsz2 from a detector scan.
%
% For each frame:
%   beam0  — 2D intensity-weighted centroid in a small ROI around the peak,
%            after background subtraction. More accurate than Gaussian fitting
%            for sub-pixel beams (σ ≈ 0.5 px) because it uses both the
%            overflow-excluded central region and the Gaussian tails.
%   Gaussian fits to x/y line profiles are computed and shown as diagnostics.
%            The x-fit (R²≈1) works well because overflow creates a symmetric
%            doublet that triangulates the centre. The y-fit is less reliable
%            for sub-pixel beams and is displayed as context only.
%
% Data:   pilatus2-617694.hdf5 — 7-frame dpsz2 scan (450→150 mm).
% Output: beam0_calibration.mat  (Calibration Data folder)
%
%   load('beam0_calibration.mat', 'beam0Cal')
%   beam0_x = polyval(beam0Cal.coeffsX, dpsz2_value)
%   beam0_y = polyval(beam0Cal.coeffsY, dpsz2_value)

%% Paths
scriptDir   = fileparts(mfilename('fullpath'));
BASE        = fileparts(scriptDir);
CAL_DIR     = fullfile(fileparts(BASE), 'February 2026 Beamtime', 'Calibration Data');
addpath(fullfile(BASE, 'Support Functions'));

HDF5_FILE   = fullfile(CAL_DIR, 'pilatus2-617694.hdf5');
OUTPUT_FILE = fullfile(CAL_DIR, 'beam0_calibration.mat');

%% Parameters
PIXEL_SIZE_MM   = 0.172;
WAVELENGTH_A    = 0.61990;
CROP_HALFWIDTH  = 80;     % px around argmax for Gaussian profile fitting
CENT_HALFWIDTH  = 15;     % px ROI for 2D centroid
CENT_THRESH     = 0.05;   % fraction of peak used as background threshold
N_PROJ          = 5;      % ± rows for y max-projection (Gaussian diagnostic)
OVERFLOW        = 1048575;

%% Load
[folder, fname] = fileparts(HDF5_FILE);
runNum  = regexp(fname, '(?<=-)\d+$', 'match', 'once');
nxsFile = fullfile(folder, "i07-" + runNum + ".nxs");
if ~isfile(nxsFile)
    error('calibrateBeam0:noNXS', 'NXS file not found: %s', nxsFile);
end
dpsz2_all = double(h5read(nxsFile, '/entry/instrument/dpsz2/value'));
raw       = h5read(HDF5_FILE, '/entry/data/data');   % [nx=1475, ny=1679, N]
nFrames   = size(raw, 3);
if numel(dpsz2_all) ~= nFrames
    error('calibrateBeam0:mismatch', ...
        'NXS has %d dpsz2 values but HDF5 has %d frames', numel(dpsz2_all), nFrames);
end
fprintf('Loaded %d frames  (dpsz2: %.0f → %.0f mm)\n', ...
    nFrames, dpsz2_all(1), dpsz2_all(end));

%% Per-frame analysis
beam0  = nan(nFrames, 2);
sigmas = nan(nFrames, 2);

for i = 1:nFrames
    img      = double(raw(:,:,i));
    img_proc = img;
    img_proc(img == OVERFLOW | img < 0) = 0;

    if max(img_proc(:)) < 100
        warning('calibrateBeam0:noBeam', 'Frame %d: no beam signal — skipped', i);
        continue
    end

    % Rough peak (argmax of non-overflow image)
    [~, idx]  = max(img_proc(:));
    [xp, yp]  = ind2sub(size(img_proc), idx);
    nx = size(img, 1);  ny = size(img, 2);

    % --- 2D centroid (primary beam0 estimate) ---
    % Use background-subtracted weights in a small ROI around argmax.
    % More robust than Gaussian fitting for sub-pixel beams.
    cxLo = max(1,  xp - CENT_HALFWIDTH);
    cxHi = min(nx, xp + CENT_HALFWIDTH);
    cyLo = max(1,  yp - CENT_HALFWIDTH);
    cyHi = min(ny, yp + CENT_HALFWIDTH);
    roi  = img_proc(cxLo:cxHi, cyLo:cyHi);
    bg   = CENT_THRESH * max(roi(:));
    W    = max(roi - bg, 0);
    [gX, gY] = ndgrid((cxLo:cxHi)', (cyLo:cyHi)');
    wSum = sum(W(:));
    if wSum > 0
        xc = sum(gX(:) .* W(:)) / wSum;
        yc = sum(gY(:) .* W(:)) / wSum;
    else
        xc = double(xp);
        yc = double(yp);
    end
    beam0(i,:) = [xc, yc];

    % --- Gaussian fits (diagnostic only) ---
    xLo = max(1,  xp - CROP_HALFWIDTH);
    xHi = min(nx, xp + CROP_HALFWIDTH);
    yLo = max(1,  yp - CROP_HALFWIDTH);
    yHi = min(ny, yp + CROP_HALFWIDTH);
    xCoords = (xLo:xHi)';
    yCoords = (yLo:yHi)';

    % x-profile: column slice at y=yp (typically shows doublet due to overflow)
    px_raw   = img(xLo:xHi, yp);
    px_valid = px_raw > 0 & px_raw ~= OVERFLOW;
    parX     = fitGauss1D(xCoords(px_valid), double(px_raw(px_valid)));
    sigmas(i,1) = abs(parX(3));

    % y-profile: max-projection over ±N_PROJ rows (avoids central overflow)
    xProjLo = max(1,  xp - N_PROJ);
    xProjHi = min(nx, xp + N_PROJ);
    py_raw  = max(img_proc(xProjLo:xProjHi, yLo:yHi), [], 1)';
    py_valid = py_raw > 0;
    parY     = fitGauss1D(yCoords(py_valid), double(py_raw(py_valid)));
    sigmas(i,2) = abs(parY(3));

    fprintf('Frame %2d  dpsz2=%6.1f mm  beam0=[%.3f, %.3f]  sigma_x=%.2f px\n', ...
        i, dpsz2_all(i), beam0(i,1), beam0(i,2), sigmas(i,1));

    % ---- Diagnostic figure ----
    xFine = linspace(xCoords(1), xCoords(end), 400)';
    yFine = linspace(yCoords(1), yCoords(end), 400)';
    pxFit = parX(1)*exp(-(xFine-parX(2)).^2/(2*parX(3)^2)) + parX(4);
    pyFit = parY(1)*exp(-(yFine-parY(2)).^2/(2*parY(3)^2)) + parY(4);

    px_plot = double(px_raw);  px_plot(~px_valid) = NaN;

    figure('Name', sprintf('Frame %d  dpsz2=%.0f mm', i, dpsz2_all(i)), ...
           'NumberTitle', 'off', 'Position', [30 30 1500 700])
    tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact')
    sgtitle(sprintf('Frame %d   dpsz2 = %.1f mm', i, dpsz2_all(i)), ...
            'FontWeight', 'bold')

    % --- Full detector image ---
    nexttile([2 1])
    imagesc(log10(max(img_proc, 1)))
    colormap(gca, 'hot'); colorbar; axis image
    hold on
    plot(yc, xc, 'c+', 'MarkerSize', 18, 'LineWidth', 2.5)
    rectangle('Position', [yLo, xLo, yHi-yLo, xHi-xLo], ...
              'EdgeColor', 'g', 'LineWidth', 1.5, 'LineStyle', '--')
    hold off
    xlabel('y (px)'); ylabel('x (px)')
    title(sprintf('Full detector  beam0=[%.2f, %.2f]', xc, yc))

    % --- Crop zoom ---
    crop = img_proc(xLo:xHi, yLo:yHi);
    nexttile
    imagesc(yCoords, xCoords, log10(max(crop, 1)))
    colormap(gca, 'hot'); colorbar; axis image
    hold on
    plot(yc, xc, 'c+', 'MarkerSize', 14, 'LineWidth', 2)
    yline(xp, 'g--', 'LineWidth', 1)
    xline(yp, 'b--', 'LineWidth', 1)
    hold off
    xlabel('y (px)'); ylabel('x (px)')
    title('Crop (green=x slice, blue=y ref)')

    % --- x-profile ---
    nexttile
    plot(xCoords, px_plot, 'k.', 'MarkerSize', 6); hold on
    plot(xFine, pxFit, 'r-', 'LineWidth', 1.5)
    xline(xc, 'c--', 'LineWidth', 1.5)
    hold off
    xlabel('x (px)'); ylabel('counts')
    title(sprintf('x profile  x_0^{Gauss}=%.2f  x_0^{cent}=%.2f  \\sigma=%.2f px', ...
        parX(2), xc, abs(parX(3))))
    legend('data (overflow excluded)', 'Gaussian fit', 'centroid', 'Location', 'best')

    % --- y-profile ---
    nexttile
    plot(yCoords, py_raw, 'k.', 'MarkerSize', 6); hold on
    plot(yFine, pyFit, 'r-', 'LineWidth', 1.5)
    xline(yc, 'c--', 'LineWidth', 1.5)
    hold off
    xlabel('y (px)'); ylabel(sprintf('max counts (rows %d:%d)', xProjLo, xProjHi))
    title(sprintf('y profile  y_0^{Gauss}=%.2f  y_0^{cent}=%.2f', parY(2), yc))
    legend('data', 'Gaussian fit', 'centroid', 'Location', 'best')
end

%% Linear calibration
validMask = ~any(isnan(beam0), 2);
dpsz2     = dpsz2_all(validMask);
beam0v    = beam0(validMask, :);
cal       = fitBeam0Calibration(dpsz2(:), beam0v, MakePlot=true);

%% Save
beam0Cal.coeffsX      = cal.coeffsX;
beam0Cal.coeffsY      = cal.coeffsY;
beam0Cal.r2X          = cal.r2X;
beam0Cal.r2Y          = cal.r2Y;
beam0Cal.dpsz2        = dpsz2(:);
beam0Cal.beam0        = beam0v;
beam0Cal.sigma        = sigmas(validMask, :);
beam0Cal.pixelSize_mm = PIXEL_SIZE_MM;
beam0Cal.wavelength_A = WAVELENGTH_A;
beam0Cal.hdf5File     = string(HDF5_FILE);
beam0Cal.dateCreated  = datetime('now');
save(OUTPUT_FILE, 'beam0Cal');

fprintf('\nCalibration saved: %s\n', OUTPUT_FILE);
fprintf('beam0_x = %.5f * dpsz2 + %.3f  (R² = %.5f)\n', ...
    cal.coeffsX(1), cal.coeffsX(2), cal.r2X);
fprintf('beam0_y = %.5f * dpsz2 + %.3f  (R² = %.5f)\n', ...
    cal.coeffsY(1), cal.coeffsY(2), cal.r2Y);
fprintf('\nUsage after loading:\n');
fprintf('  load(''beam0_calibration.mat'', ''beam0Cal'')\n');
fprintf('  beam0_x = polyval(beam0Cal.coeffsX, dpsz2_value)\n');
fprintf('  beam0_y = polyval(beam0Cal.coeffsY, dpsz2_value)\n');

%% -----------------------------------------------------------------------
function params = fitGauss1D(x, y)
% Fit f(x) = A*exp(-(x-x0)^2/(2*s^2)) + bg via fminsearch.
% Centre is constrained to stay within the data range.
if numel(x) < 3
    params = [0, mean(x), 1, mean(y)];
    return
end
bg0    = min(y);
A0     = max(y) - bg0;
[~,pk] = max(y);
x0_0   = x(pk);
above  = y > bg0 + A0/2;
if sum(above) >= 2
    xs = x(above);
    s0 = max((max(xs) - min(xs)) / 2.355, 0.5);
else
    s0 = 5;
end
xRange = max(x) - min(x);
gauss  = @(p) abs(p(1)) .* exp(-(x - p(2)).^2 ./ (2*p(3)^2)) + abs(p(4));
pen    = @(p) 1e8 * max(0, abs(p(2) - x0_0) - xRange)^2;
cost   = @(p) sum((gauss(p) - y).^2) + pen(p);
params = fminsearch(cost, [A0, x0_0, s0, bg0], ...
    optimset('Display', 'off', 'TolX', 0.005, 'TolFun', 1, 'MaxFunEvals', 20000));
params([1, 3, 4]) = abs(params([1, 3, 4]));  % enforce A, sigma, bg >= 0
end
