function [climScaled] = getCLims(climInput,sampleAtten,sampleExposureTime,scaling,refAtten,refExposureTime)
%GETCLIMS Summary of this function goes here
%   Detailed explanation goes here

    if nargin == 4
        refAtten = 0;
        refExposureTime = 1;
    end

    if scaling == 'log'
        climInput = 10.^climInput;
    end

    load("attenuationTable.mat");

    ind = attenuation == refAtten;
    refTrans = transmission(ind);

    ind = attenuation == sampleAtten;
    sampleTrans = transmission(ind);

    %assuming transmission of 1 and exposure time of 1s in reference
    scalingFactor = (sampleTrans./refTrans).*(sampleExposureTime/refExposureTime);

    climScaled = scalingFactor.*climInput;

    if scaling == 'log'
        climScaled = log10(climScaled);
        
        climScaled = max(climScaled,[0,0]);
    end

    if isempty(climScaled)
        climScaled = climInput;
        warning("Clim values not scaled, check sample attenuation and verify " + ...
            "corresponding entry exists in attenuationTable.mat")
    end
end

