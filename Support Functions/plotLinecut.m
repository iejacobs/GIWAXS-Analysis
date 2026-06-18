function fig = plotLinecut(x, y, xLabel, scale)
%PLOTLINECUT Standardized 1D GIWAXS linecut.
%   FIG = PLOTLINECUT(X, Y, XLABEL) plots intensity Y vs X with the given
%   x-axis label, a "Intensity (a.u.)" y-axis, and the standard GIWAXS figure
%   format.
%
%   FIG = PLOTLINECUT(X, Y, XLABEL, SCALE) sets the y scale: "linear"
%   (default) or "log" (semilogy).
%
%   See also giwaxsFigureStyle, plotGiwaxsPattern, plotReshaped, giwaxsProcess.

arguments
    x double
    y double
    xLabel (1,1) string
    scale (1,1) string = "linear"
end

fig = figure;
if scale == "log"
    semilogy(x, y);
else
    plot(x, y);
end
xlabel(xLabel);
ylabel("Intensity (a.u.)");
axis tight
giwaxsFigureStyle(fig);
end
