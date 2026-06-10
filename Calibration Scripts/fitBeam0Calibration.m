function cal = fitBeam0Calibration(dpsz2, beam0, options)
% Fit a linear calibration of beam0 pixel position vs dpsz2 motor position.
%
% Fits independent linear models:
%   beam0_x = ax * dpsz2 + bx
%   beam0_y = ay * dpsz2 + by
%
% Usage:
%   cal = fitBeam0Calibration(dpsz2, beam0)
%   cal = fitBeam0Calibration(dpsz2, beam0, MakePlot=true)
%
%   beam0AtTarget = cal.evaluate(dpsz2_target)
%
% Inputs:
%   dpsz2  - N×1 vector of dpsz2 motor positions (mm)
%   beam0  - N×2 array of [beam0_x, beam0_y] pixel positions
%
% Output fields:
%   cal.coeffsX    - [slope, intercept] for beam0_x (pixels/mm, pixels)
%   cal.coeffsY    - [slope, intercept] for beam0_y
%   cal.r2X        - R² for beam0_x fit
%   cal.r2Y        - R² for beam0_y fit
%   cal.dpsz2      - input dpsz2 values
%   cal.beam0      - input beam0 values
%   cal.evaluate   - function handle: evaluate(dpsz2_val) → [beam0_x, beam0_y]

arguments
    dpsz2 (:,1) double
    beam0 (:,2) double
    options.MakePlot (1,1) logical = false
end

if numel(dpsz2) < 2
    error('fitBeam0Calibration:insufficientData', ...
        'At least 2 calibration points are required.');
end
if numel(dpsz2) ~= height(beam0)
    error('fitBeam0Calibration:sizeMismatch', ...
        'dpsz2 and beam0 must have the same number of rows.');
end

cal.dpsz2 = dpsz2;
cal.beam0  = beam0;

cal.coeffsX = polyfit(dpsz2, beam0(:,1), 1);
cal.coeffsY = polyfit(dpsz2, beam0(:,2), 1);

cal.r2X = computeR2(beam0(:,1), polyval(cal.coeffsX, dpsz2));
cal.r2Y = computeR2(beam0(:,2), polyval(cal.coeffsY, dpsz2));

cal.evaluate = @(z) [polyval(cal.coeffsX, z), polyval(cal.coeffsY, z)];

fprintf('beam0_x = %.4f * dpsz2 + %.2f  (R²=%.4f)\n', ...
    cal.coeffsX(1), cal.coeffsX(2), cal.r2X);
fprintf('beam0_y = %.4f * dpsz2 + %.2f  (R²=%.4f)\n', ...
    cal.coeffsY(1), cal.coeffsY(2), cal.r2Y);

if options.MakePlot
    dpsz2Fine = linspace(min(dpsz2), max(dpsz2), 200)';
    figure
    tiledlayout(1,2)

    nexttile
    plot(dpsz2, beam0(:,1), 'o', dpsz2Fine, polyval(cal.coeffsX, dpsz2Fine), '-')
    xlabel('dpsz2 (mm)'); ylabel('beam0_x (px)')
    title(sprintf('beam0\\_x  R²=%.4f', cal.r2X))
    legend('data','linear fit', Location='best')

    nexttile
    plot(dpsz2, beam0(:,2), 'o', dpsz2Fine, polyval(cal.coeffsY, dpsz2Fine), '-')
    xlabel('dpsz2 (mm)'); ylabel('beam0_y (px)')
    title(sprintf('beam0\\_y  R²=%.4f', cal.r2Y))
    legend('data','linear fit', Location='best')
end
end

% -------------------------------------------------------------------------
function r2 = computeR2(y, yfit)
ssTot = sum((y - mean(y)).^2);
ssRes = sum((y - yfit).^2);
r2 = 1 - ssRes/ssTot;
end
