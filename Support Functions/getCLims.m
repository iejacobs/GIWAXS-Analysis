function [climScaled] = getCLims(climInput,sampleTrans,sampleExposureTime,scaling,refTrans,refExposureTime)
%GETCLIMS Scale colour limits by beam transmission and exposure time.
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

    %assuming transmission of 1 and exposure time of 1s in reference
    scalingFactor = (sampleTrans./refTrans).*(sampleExposureTime/refExposureTime);

    climScaled = scalingFactor.*climInput;

    if scaling == 'log'
        climScaled = log10(climScaled);

        climScaled = max(climScaled,[0,0]);
    end
end

