function [outputArg1,outputArg2] = convertHDF5toTIFF(filename,inputArg2)
%CONVERTHDF5TOTIFF Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    inputArg1
    inputArg2
end

datastruct = struct();

datastruct.Groups(1).Name = "entry";

datastruct.Groups(1).Groups(1).Name = "data";

datastruct.Groups(1).Groups(1).Datasets(1).Name = "data";
datastruct.Groups(1).Groups(1).Datasets(1).Value = h5read(filename, "/entry/data/data");


arguments (Output)
    outputArg1
    outputArg2
end

outputArg1 = inputArg1;
outputArg2 = inputArg2;
end