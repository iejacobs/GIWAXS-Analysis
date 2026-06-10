function [SDD_mm, result] = fitAgBeSDD(rBins, intensity, pixelSize_mm, wavelength_A, options)
% Fit AgBe ring positions in a radial intensity profile to determine SDD.
%
% For each candidate SDD, samples the (smoothed) intensity profile at the
% expected AgBe ring positions and scores by the mean sampled intensity,
% normalised by the local background. Only SDDs where ≥2 rings fall within
% the detector range are considered. The coarse winner is then refined with
% fminsearch.
%
% Inputs:
%   rBins        - radial bin centres (pixels)
%   intensity    - mean intensity per bin (from radialIntegrate)
%   pixelSize_mm - detector pixel size in mm (Pilatus 2: 0.172)
%   wavelength_A - X-ray wavelength in Angstrom
%
% Name-Value options:
%   SDDRange     - [min, max] search range in mm (default [50 2000])
%   SampleWidth  - half-width (px) to sample around each ring (default 15)
%   MakePlot     - diagnostic plot (default true)
%
% Outputs:
%   SDD_mm  - best-fit SDD in mm
%   result  - struct: .SDD_mm, .agbe_r_px, .agbe_labels, .agbe_d_A

arguments
    rBins        (:,1) double
    intensity    (:,1) double
    pixelSize_mm (1,1) double
    wavelength_A (1,1) double
    options.SDDRange    (1,2) double  = [50, 2000]
    options.SampleWidth (1,1) double  = 15
    options.MakePlot    (1,1) logical = true
end

% AgBe reflections: d-spacings (Å) in order of decreasing d (increasing q)
AGBE_D      = [2.359, 2.042, 1.444, 1.231, 1.180, 1.021, 0.937, 0.913];
AGBE_LABELS = {'111','200','220','311','222','400','331','420'};

ringRadii = @(sdd) sdd .* tan(2 .* asin(wavelength_A ./ (2 .* AGBE_D))) ./ pixelSize_mm;

maxR     = max(rBins);
smoothed = movmean(intensity, 20);

% Score = sum of net signal (peak minus local background) at expected rings.
% Local background is estimated from a window just below each ring
% (40–100 px), avoiding the decaying direct-scatter at small radii.
% Require ≥1 ring within the detector range.
function score = scoreFn(sdd)
    expected = ringRadii(sdd);
    inRange  = expected > 50 & expected < maxR * 0.98;
    if sum(inRange) < 1
        score = 0;
        return
    end
    sw    = options.SampleWidth;
    score = 0;
    for k = find(inRange)
        r_k   = expected(k);
        % Peak: max in ±sw window
        pkWin = rBins >= r_k - sw & rBins <= r_k + sw;
        if ~any(pkWin), continue; end
        peakVal = max(smoothed(pkWin));

        % Local background: window 3sw–6sw below the ring centre
        bgLo  = r_k - 6*sw;
        bgHi  = r_k - 3*sw;
        bgWin = rBins >= bgLo & rBins <= bgHi;
        if any(bgWin)
            bgVal = mean(smoothed(bgWin));
        else
            bgVal = peakVal;   % no room below → net = 0
        end
        if bgVal <= 0, bgVal = 1; end

        score = score + max(0, peakVal - bgVal);
    end
    score = score / sum(inRange);
end

% Coarse grid search (MAXIMISE score)
sddGrid = linspace(options.SDDRange(1), options.SDDRange(2), 500);
scores  = arrayfun(@(s) scoreFn(s), sddGrid);

if max(scores) == 0
    error('fitAgBeSDD:noRingsInRange', ...
        'No SDD in search range [%.0f %.0f] mm gives ≥2 AgBe rings within detector', ...
        options.SDDRange(1), options.SDDRange(2));
end

[~, bestIdx] = max(scores);
sdd0 = sddGrid(bestIdx);

% Refine with fminsearch (minimise –score)
sddOpt = fminsearch(@(s) -scoreFn(s(1)), sdd0, ...
    optimset('TolX', 0.1, 'MaxFunEvals', 2000, 'Display', 'off'));
SDD_mm = sddOpt(1);

% Report
expected_best = ringRadii(SDD_mm);
fprintf('\nBest-fit SDD = %.2f mm\n', SDD_mm);
fprintf('%-6s  %-8s  %-14s  %s\n', 'Ring','d (A)','Expected r (px)','In range');
for k = 1:numel(AGBE_D)
    er = expected_best(k);
    inrng = er < maxR;
    fprintf('%-6s  %-8.3f  %-14.1f  %s\n', ...
        AGBE_LABELS{k}, AGBE_D(k), er, string(inrng));
end

% Result struct
result.SDD_mm      = SDD_mm;
result.agbe_r_px   = expected_best;
result.agbe_labels = AGBE_LABELS;
result.agbe_d_A    = AGBE_D;

% Diagnostic plot
if options.MakePlot
    figure
    tiledlayout(2,1)

    nexttile
    plot(rBins, intensity, Color=[0.7 0.7 0.7]); hold on
    plot(rBins, smoothed, 'k', LineWidth=1.5)
    inRange = expected_best < maxR;
    for k = find(inRange)
        xline(expected_best(k), 'r--', AGBE_LABELS{k})
    end
    xlabel('Radius (px)'); ylabel('Mean intensity')
    title(sprintf('AgBe radial profile — SDD = %.1f mm', SDD_mm))
    legend('raw','smoothed', Location='northeast')

    nexttile
    plot(sddGrid, scores, 'k')
    xline(SDD_mm, 'r--', sprintf('%.1f mm', SDD_mm))
    xlabel('SDD (mm)'); ylabel('Score (peak/bg ratio)')
    title('Grid search score')
end
end
