function writeInt32TIFF(img, tiffPath)
% Write a 2-D image to a single-channel 32-bit signed-integer TIFF.

arguments
    img      (:,:) {mustBeNumeric}
    tiffPath (1,1) string
end

t = Tiff(char(tiffPath), 'w');
closer = onCleanup(@() t.close());
t.setTag('Photometric',         Tiff.Photometric.MinIsBlack);
t.setTag('ImageLength',         size(img, 1));
t.setTag('ImageWidth',          size(img, 2));
t.setTag('BitsPerSample',       32);
t.setTag('SampleFormat',        Tiff.SampleFormat.Int);
t.setTag('SamplesPerPixel',     1);
t.setTag('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
t.write(int32(img));
end
