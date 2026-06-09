function tiffPath = convertHDF5toTIFF(hdf5Path, outputDir)
% Read a GIWAXS image from an HDF5 file and write it as a 32-bit TIFF.
% Returns the full path to the written TIFF file.
arguments
    hdf5Path (1,1) string
    outputDir (1,1) string = string(tempdir)
end

img = int32(squeeze(h5read(hdf5Path, "/entry/data/data")));

[~, name] = fileparts(hdf5Path);
tiffPath = char(fullfile(outputDir, name + ".tif"));

t = Tiff(tiffPath, 'w');
closer = onCleanup(@() t.close());
t.setTag('Photometric',      Tiff.Photometric.MinIsBlack);
t.setTag('ImageLength',      size(img, 1));
t.setTag('ImageWidth',       size(img, 2));
t.setTag('BitsPerSample',    32);
t.setTag('SampleFormat',     Tiff.SampleFormat.Int);
t.setTag('SamplesPerPixel',  1);
t.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
t.write(img);
end
