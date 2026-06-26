function [climScaled] = scaleClimsToExposure(climInput,sampleTrans,sampleExposureTime,scaling,refTrans,refExposureTime)
%SCALECLIMSTOEXPOSURE Scale colour limits by beam transmission and exposure time.
%   Replaces the older getCLims helper. The name is deliberately unique so it
%   cannot be shadowed by the legacy getCLims (which took an attenuation LEVEL
%   and looked the transmission up in attenuationTable.mat). Feeding the new
%   transmission fraction to that legacy function silently returned the limits
%   unscaled, which made high-attenuation images look dark "as if not scaled".
%
%   sampleTrans is the fractional beam transmission for the image, read from
%   the .dat metadata 'transmission' field (1 = no attenuation). refTrans and
%   refExposureTime are the reference conditions the input limits correspond
%   to (default: transmission 1, exposure 1 s).

    if nargin == 4
        refTrans = 1;
        refExposureTime = 1;
    end

    %nothing to scale by - leave the limits untouched
    if isempty(sampleTrans)
        climScaled = climInput;
        warning("Clim values not scaled; no transmission value provided.")
        return
    end

    if scaling == 'log'
        climInput = 10.^climInput;
    end

    %scale to
    scalingFactor = (sampleTrans./refTrans).*(sampleExposureTime/refExposureTime);

    climScaled = scalingFactor.*climInput;

    if scaling == 'log'
        climScaled = log10(climScaled);

        %climScaled = max(climScaled,[0,0]);
    end
end
