function params = readDatParams(datFile)
% Parse metadata from a Diamond Light Source SRS beamline .dat file.
%
% Returns a struct with all key=value pairs from the <MetaDataAtStart>
% block. Numeric scalars → double; bracketed arrays/matrices → double
% array via jsondecode; single-quoted text → string; JSON objects
% (rois etc.) → decoded struct; unrecognised values → string.
%
% The SRS header fields SRSRUN, SRSDAT, SRSTIM are also extracted as
% params.runNumber, params.runDate, and params.runTime.
%
% Key calibration fields in the returned struct:
%   dpsx, dpsy, dpsz, dpsz2   - detector stage positions (mm)
%   diff1detdist               - diffractometer detector distance (mm)
%   dcm1energy                 - beam energy (keV)
%   dcm1lambda                 - wavelength (Angstrom)
%   p2_rois                    - beam monitor ROI struct (approx beam centre)

arguments
    datFile (1,1) string {mustBeFile}
end

text = fileread(datFile);

% SRS header: run number, date, time
params = struct();
headerTokens = regexp(text, 'SRSRUN=(\d+),SRSDAT=(\d+),SRSTIM=(\d+)', ...
    'tokens', 'once');
if ~isempty(headerTokens)
    params.runNumber = str2double(headerTokens{1});
    params.runDate   = string(headerTokens{2});   % yyyymmdd
    params.runTime   = string(headerTokens{3});   % hhmmss
end

% Extract <MetaDataAtStart> block
startTag = '<MetaDataAtStart>';
endTag   = '</MetaDataAtStart>';
startIdx = strfind(text, startTag);
endIdx   = strfind(text, endTag);
if isempty(startIdx) || isempty(endIdx)
    error('readDatParams:noMetadata', ...
        'No <MetaDataAtStart> block found in "%s"', datFile);
end
block = text(startIdx(1) + numel(startTag) : endIdx(1) - 1);

% Parse key=value lines
lines = strtrim(splitlines(string(block)));
for i = 1:numel(lines)
    line = lines(i);
    if line == ""
        continue
    end
    eqPos = strfind(line, "=");
    if isempty(eqPos)
        continue
    end
    key = strtrim(extractBefore(line, eqPos(1)));
    val = strtrim(extractAfter(line, eqPos(1)));

    fieldName = matlab.lang.makeValidName(key);
    params.(fieldName) = parseValue(val);
end
end

% -------------------------------------------------------------------------
function val = parseValue(str)
if str == ""
    val = str;
    return
end
c = char(str);

% Single-quoted string: 'text'
if c(1) == ''''
    val = string(c(2:end-1));
    return
end

% JSON array [...]  or object {...}
if c(1) == '[' || c(1) == '{'
    try
        val = jsondecode(c);
        return
    catch
    end
end

% Numeric scalar
num = str2double(str);
if ~isnan(num)
    val = num;
    return
end

% Plain string
val = str;
end
