function [SDD_mm, result] = fitAgBeSDD(rBins, intensity, pixelSize_mm, wavelength_A, options)
% Determine sample-to-detector distance (SDD) from a silver behenate (AgBe)
% radial intensity profile.
%
% AgBe gives a series of equally-spaced lamellar (00l) rings with
% d_n = d001/n (d001 = 58.380 Angstrom). For each ring order n the radius
% from beam0 on a flat detector normal to the beam follows the same model
% used by GIXSGUI's SDD calibration:
%
%       r_n = SDD * tan(2*theta_n),   2*theta_n = 2*asin(n*lambda/(2*d001))
%
% This function detects the ring peaks in a radial profile (obtained from
% radialIntegrate around the measured beam0), assigns them to consecutive
% AgBe orders, and fits SDD as the single free parameter (the rings are
% assumed concentric about the measured beam0). By default it pauses for
% you to confirm the order assignment before fitting.
%
% Inputs:
%   rBins        - radial bin centres (pixels), from radialIntegrate
%   intensity    - mean intensity per bin, from radialIntegrate
%   pixelSize_mm - detector pixel size in mm (Pilatus 2: 0.172)
%   wavelength_A - X-ray wavelength in Angstrom
%
% Name-Value options:
%   D001_A            - AgBe d001 spacing in Angstrom (default 58.380)
%   MaxR              - ignore bins beyond this radius, px (default Inf)
%   MinR              - ignore bins below this radius, px (default 20;
%                       skips the direct-beam/beamstop region)
%   SmoothWindow      - movmean window for peak detection, px (default 3)
%   MinPeakProminence - findpeaks prominence; 0 => auto = 0.5% of profile
%                       range within [MinR, MaxR] (default 0)
%   MinPeakDistance   - findpeaks min separation, px (default 15)
%   LatticeTol        - tolerance (fraction of ring spacing) when growing
%                       the consecutive equally-spaced AgBe ring chain;
%                       larger admits more peaks (default 0.15)
%   PeakLocations     - supply ring radii (px) directly, skipping detection
%   RingOrders        - override the auto order assignment with this vector
%                       of n values (one per detected/supplied peak)
%   Interactive       - pause with a confirmation dialog before fitting
%                       (default true; set false for scripted use)
%   MakePlot          - diagnostic plots (default true)
%
% Outputs:
%   SDD_mm  - best-fit SDD in mm
%   result  - struct with fields:
%               .SDD_mm, .SDD_std_mm   fitted SDD and its standard error
%               .orders                assigned ring orders n
%               .r_px                  detected peak radii (px)
%               .r_fit_px              model radii at the fitted SDD (px)
%               .d_A                   AgBe d-spacings used (Angstrom)
%               .twoTheta_rad          scattering angles 2*theta (rad)
%               .residual_px           r_px - r_fit_px
%               .rsq                   R^2 of the fit

arguments
    rBins        (:,1) double
    intensity    (:,1) double
    pixelSize_mm (1,1) double
    wavelength_A (1,1) double
    options.D001_A            (1,1) double  = 58.380
    options.MaxR              (1,1) double  = Inf
    options.MinR              (1,1) double  = 20
    options.SmoothWindow      (1,1) double  = 3
    options.MinPeakProminence (1,1) double  = 0
    options.MinPeakDistance   (1,1) double  = 15
    options.LatticeTol        (1,1) double  = 0.15
    options.PeakLocations     (1,:) double  = []
    options.RingOrders        (1,:) double  = []
    options.Interactive       (1,1) logical = true
    options.MakePlot          (1,1) logical = true
end

smoothed = movmean(intensity, options.SmoothWindow);
inWin    = rBins >= options.MinR & rBins <= options.MaxR;

% --- Locate ring peaks ------------------------------------------------
if isempty(options.PeakLocations)
    prom = options.MinPeakProminence;
    if prom <= 0
        prom = 0.005 * (max(smoothed(inWin)) - min(smoothed(inWin)));
    end
    [~, locs] = findpeaks(smoothed(inWin), rBins(inWin), ...
        'MinPeakProminence', prom, ...
        'MinPeakDistance',   options.MinPeakDistance);
    r_px = sort(locs(:));
else
    r_px = sort(options.PeakLocations(:));
end

if numel(r_px) < 2
    error('fitAgBeSDD:tooFewPeaks', ...
        ['Found %d ring peak(s); need >=2. Adjust MinPeakProminence/', ...
         'MinR/MaxR or pass PeakLocations.'], numel(r_px));
end

% --- Assign AgBe orders -----------------------------------------------
% AgBe lamellar rings are equally spaced (r_n ~ n*r1). Grow a consecutive
% equally-spaced chain outward from the smallest peak, allowing occasional
% missing orders (gap ~= integer*r1) but stopping at the first peak that
% does not fall on the lattice. This discards spurious peaks (wide-angle
% rings, detector features) beyond the AgBe series.
if isempty(options.RingOrders)
    keep    = 1;
    spacing = r_px(2) - r_px(1);
    for k = 2:numel(r_px)
        gap    = r_px(k) - r_px(keep(end));
        nsteps = round(gap / spacing);
        if nsteps >= 1 && abs(gap - nsteps*spacing) <= options.LatticeTol*spacing*nsteps
            keep(end+1) = k;                               %#ok<AGROW>
            spacing = (r_px(k) - r_px(keep(1))) / ...
                round((r_px(k) - r_px(keep(1))) / spacing);
        else
            break
        end
    end
    r_px = r_px(keep);
    % Refine spacing by least squares, then assign integer orders
    n0      = round(r_px / spacing);
    spacing = sum(r_px .* n0) / sum(n0.^2);
    orders  = round(r_px / spacing);
else
    orders = options.RingOrders(:);
    if numel(orders) ~= numel(r_px)
        error('fitAgBeSDD:orderCountMismatch', ...
            'RingOrders has %d entries but %d peaks were found.', ...
            numel(orders), numel(r_px));
    end
end
if numel(unique(orders)) ~= numel(orders) || any(orders < 1)
    error('fitAgBeSDD:badOrders', ...
        'Assigned orders are not unique positive integers: %s. Use RingOrders to fix.', ...
        mat2str(orders'));
end

d_A          = options.D001_A ./ orders;
twoTheta_rad = 2 * asin(orders * wavelength_A / (2 * options.D001_A));

% --- Show proposed assignment and (optionally) confirm ----------------
fprintf('\nProposed AgBe ring assignment (d001 = %.3f A, lambda = %.4f A):\n', ...
    options.D001_A, wavelength_A);
fprintf('%-6s  %-10s  %-12s\n', 'Order n', 'r (px)', 'd (A)');
for k = 1:numel(orders)
    fprintf('%-6d  %-10.2f  %-12.3f\n', orders(k), r_px(k), d_A(k));
end

if options.MakePlot
    showProfile(rBins, intensity, smoothed, r_px, orders, options);
end

if options.Interactive
    btn = questdlg(sprintf('Fit SDD to these %d rings?', numel(orders)), ...
        'AgBe SDD calibration', 'Fit', 'Cancel', 'Fit');
    if ~strcmp(btn, 'Fit')
        error('fitAgBeSDD:cancelled', 'Cancelled by user before fitting.');
    end
end

% --- Fit SDD (single parameter, least squares through origin) ---------
t      = tan(twoTheta_rad);          % r_mm = SDD * t
r_mm   = r_px * pixelSize_mm;
SDD_mm = sum(r_mm .* t) / sum(t.^2);

r_fit_mm    = SDD_mm * t;
residual_mm = r_mm - r_fit_mm;
N           = numel(r_px);
if N > 1
    SDD_std_mm = sqrt(sum(residual_mm.^2) / (N - 1) / sum(t.^2));
else
    SDD_std_mm = NaN;
end
ssRes = sum(residual_mm.^2);
ssTot = sum((r_mm - mean(r_mm)).^2);
rsq   = 1 - ssRes / ssTot;

% --- Report -----------------------------------------------------------
fprintf('\nFitted SDD = %.2f +/- %.2f mm   (R^2 = %.5f, %d rings)\n', ...
    SDD_mm, SDD_std_mm, rsq, N);
fprintf('%-6s  %-10s  %-10s  %-10s\n', 'Order', 'r meas px', 'r fit px', 'resid px');
for k = 1:N
    fprintf('%-6d  %-10.2f  %-10.2f  %-+10.2f\n', ...
        orders(k), r_px(k), r_fit_mm(k)/pixelSize_mm, residual_mm(k)/pixelSize_mm);
end

% --- Output struct ----------------------------------------------------
result.SDD_mm       = SDD_mm;
result.SDD_std_mm   = SDD_std_mm;
result.orders       = orders;
result.r_px         = r_px;
result.r_fit_px     = r_fit_mm / pixelSize_mm;
result.d_A          = d_A;
result.twoTheta_rad = twoTheta_rad;
result.residual_px  = residual_mm / pixelSize_mm;
result.rsq          = rsq;

if options.MakePlot
    showFit(twoTheta_rad, r_mm, SDD_mm, SDD_std_mm, rsq);
end
end

% =========================================================================
function showProfile(rBins, intensity, smoothed, r_px, orders, options)
figure('Name', 'AgBe radial profile')
plot(rBins, intensity, Color=[0.7 0.7 0.7]); hold on
plot(rBins, smoothed, 'k', LineWidth=1.2)
for k = 1:numel(r_px)
    xline(r_px(k), 'r--', sprintf('n=%d', orders(k)));
end
if isfinite(options.MaxR), xlim([0, options.MaxR]); end
xlabel('Radius (px)'); ylabel('Mean intensity')
title('AgBe rings detected around beam0')
legend('raw', 'smoothed', Location='northeast')
end

% =========================================================================
function showFit(twoTheta_rad, r_mm, SDD_mm, SDD_std_mm, rsq)
figure('Name', 'AgBe SDD fit')
t = tan(twoTheta_rad);
plot(t, r_mm, 'bo', MarkerFaceColor='b'); hold on
tt = linspace(0, max(t)*1.05, 50);
plot(tt, SDD_mm * tt, 'r-')
box on
xlabel('tan(2\theta)'); ylabel('Ring radius (mm)')
title(sprintf('r = SDD\\cdottan(2\\theta),  SDD = %.2f \\pm %.2f mm (R^2 = %.5f)', ...
    SDD_mm, SDD_std_mm, rsq))
legend('rings', 'fit', Location='northwest')
end
