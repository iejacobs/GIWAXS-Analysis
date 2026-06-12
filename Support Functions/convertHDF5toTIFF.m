function tiffPath = convertHDF5toTIFF(hdf5Path, outputDir, frameNumber)
% Read a GIWAXS image from an HDF5 file and write it as a 32-bit TIFF.
% For multi-frame (scan) files, frameNumber selects the frame (default 1).
% Returns the full path to the written TIFF file.
arguments
    hdf5Path    (1,1) string
    outputDir   (1,1) string = string(tempdir)
    frameNumber double {mustBeScalarOrEmpty} = []
end

img = readHDF5Image(hdf5Path, frameNumber);

[~, name] = fileparts(hdf5Path);
tiffPath = char(fullfile(outputDir, name + ".tif"));
writeInt32TIFF(img, tiffPath);
end
