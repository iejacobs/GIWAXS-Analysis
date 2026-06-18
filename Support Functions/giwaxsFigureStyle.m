function giwaxsFigureStyle(fig, varargin)
%GIWAXSFIGURESTYLE Apply the standard GIWAXS figure formatting.
%   GIWAXSFIGURESTYLE(FIG) gives figure FIG the common GIWAXS look so every
%   plot is consistent: white background, a fixed canvas size, a uniform font,
%   axis line width, outward ticks, a box, and matching colorbar/line widths.
%   The plotting primitives (plotGiwaxsPattern, plotReshaped, plotLinecut) all
%   call this, so the format for every output is defined in this one place -
%   edit here to restyle all GIWAXS plots at once.
%
%   GIWAXSFIGURESTYLE(FIG, Name, Value, ...) overrides individual settings:
%     'FontSize'  (default 14)
%     'FontName'  (default "Helvetica")
%     'LineWidth' (default 1)      - axis (and colorbar) line width
%     'DataLineWidth' (default 1.5)- width of plotted data lines (linecuts)
%     'Size'      (default [12 10])- figure size in centimetres [width height]
%
%   See also plotGiwaxsPattern, plotReshaped, plotLinecut.

p = inputParser;
addParameter(p,'FontSize',14,@(x)isnumeric(x)&&isscalar(x));
addParameter(p,'FontName',"Helvetica",@(x)isstring(x)||ischar(x));
addParameter(p,'LineWidth',1,@(x)isnumeric(x)&&isscalar(x));
addParameter(p,'DataLineWidth',1.5,@(x)isnumeric(x)&&isscalar(x));
addParameter(p,'Size',[12 10],@(x)isnumeric(x)&&numel(x)==2);
parse(p,varargin{:});
r = p.Results;

% Figure: white background, fixed physical size (so exports are uniform)
set(fig,'Color','w','Units','centimeters');
pos = get(fig,'Position');
set(fig,'Position',[pos(1:2), r.Size(:)']);

% Axes: uniform font, line width, outward ticks, box, axis lines on top
ax = findall(fig,'type','axes');
set(ax,'FontSize',r.FontSize,'FontName',char(r.FontName), ...
    'LineWidth',r.LineWidth,'Box','on','TickDir','out','Layer','top');

% Data lines (e.g. linecuts)
set(findall(ax,'type','line'),'LineWidth',r.DataLineWidth);

% Colorbar (if present) matches the axis font/line width
cb = findall(fig,'type','colorbar');
if ~isempty(cb)
    set(cb,'FontSize',r.FontSize,'FontName',char(r.FontName),'LineWidth',r.LineWidth);
end
end
