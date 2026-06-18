function exportFigure(f, figFilename, plotFormat)
%EXPORTFIGURE Export figure F to FIGFILENAME using the requested format.
%   Replaces the removed hgexport: "pdf" is written as vector graphics, "png"
%   at high resolution. The extension is appended from PLOTFORMAT ("png" or
%   "pdf"). Used by giwaxsProcess to save the standardized GIWAXS figures.
%
%   See also plotGiwaxsPattern, plotReshaped, plotLinecut, giwaxsProcess.

if strcmp(plotFormat, "pdf")
    exportgraphics(f, strcat(figFilename, ".pdf"), 'ContentType', 'vector');
else
    exportgraphics(f, strcat(figFilename, ".png"), 'Resolution', 300);
end
end
