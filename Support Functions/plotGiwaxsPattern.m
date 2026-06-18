function fig = plotGiwaxsPattern(data, colorLimits, colormapFun, colorbarLabel)
%PLOTGIWAXSPATTERN Standardized 2D detector-space GIWAXS pattern.
%   FIG = PLOTGIWAXSPATTERN(DATA, COLORLIMITS, COLORMAPFUN) plots the gixsdata
%   object DATA (using its current PlotAxisLabel / PlotScale) with the given
%   colour limits and colormap, and applies the standard GIWAXS figure format.
%   COLORMAPFUN is a handle to a colormap-generating function (e.g. @magma).
%
%   FIG = PLOTGIWAXSPATTERN(..., COLORBARLABEL) also adds a colorbar with the
%   given label (used for difference images, e.g. "Intensity change (%)").
%
%   See also giwaxsFigureStyle, plotReshaped, plotLinecut, giwaxsProcess.

arguments
    data
    colorLimits (1,2) double
    colormapFun (1,1) function_handle
    colorbarLabel (1,1) string = ""
end

fig = figure;
imagesc(data);                       % gixsdata imagesc method
clim(colorLimits);
colormap(colormapFun(1000));
title('');
if colorbarLabel ~= ""
    c = colorbar;
    c.Label.String = colorbarLabel;
end
giwaxsFigureStyle(fig);
end
