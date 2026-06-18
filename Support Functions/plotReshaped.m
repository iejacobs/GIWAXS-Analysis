function fig = plotReshaped(X, Y, image, plotScale, colorLimits, colormapFun, xLabel, yLabel)
%PLOTRESHAPED Standardized reshaped/interpolated q-space GIWAXS image.
%   FIG = PLOTRESHAPED(X, Y, IMAGE, PLOTSCALE, COLORLIMITS, COLORMAPFUN,
%   XLABEL, YLABEL) plots a reshaped or interpolated intensity map IMAGE over
%   the q-axes X, Y (equal aspect, normal y-direction), with the given axis
%   labels, colour limits and colormap, and applies the standard GIWAXS figure
%   format. PLOTSCALE is 1 (linear) or 2 (log: log10 of the intensity).
%   COLORMAPFUN is a handle to a colormap-generating function (e.g. @magma).
%
%   See also giwaxsFigureStyle, plotGiwaxsPattern, plotLinecut, giwaxsProcess.

arguments
    X double
    Y double
    image double
    plotScale (1,1) double
    colorLimits (1,2) double
    colormapFun (1,1) function_handle
    xLabel (1,1) string
    yLabel (1,1) string
end

fig = figure;
if plotScale == 1
    imagesc(X, Y, image, [1 4]);
else
    imagesc(X, Y, log10(image), [1 4]);
end
axis equal
axis tight
set(gca, 'ydir', 'norm');
xlabel(xLabel);
ylabel(yLabel);
clim(colorLimits);
colormap(colormapFun(1000));
giwaxsFigureStyle(fig);
end
