function parameterFile = getParams(beamEnergy)
%GETPARAMS Summary of this function goes here
%   Detailed explanation goes here
if beamEnergy == 12.5
    parameterFile = "diamond2024_12p5keV.mat"
elseif beamEnergy == 20
    parameterFile = "diamond2024_20keV.mat"
else
    throw(MException("GIWAXS:NoParams","No parameter file available for given energy"))
end
end

