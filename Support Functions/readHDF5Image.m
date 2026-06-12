function [img, nFrames] = readHDF5Image(hdf5Path, frameNumber)
% Read a detector image from a Diamond I07 HDF5 file (/entry/data/data).
%
% Scan files hold one frame per scan point, so the dataset may be 2-D
% (single exposure) or 3-D (N frames). frameNumber selects the frame to
% return; empty (default) returns the first frame. The caller can use
% nFrames to warn when other frames exist.
%
% Inputs:
%   hdf5Path    - path to the HDF5 file
%   frameNumber - frame to extract (optional, default [] = first frame)
%
% Outputs:
%   img     - 2-D int32 detector image
%   nFrames - number of frames in the file

arguments
    hdf5Path    (1,1) string {mustBeFile}
    frameNumber double {mustBeScalarOrEmpty} = []
end

raw     = h5read(hdf5Path, "/entry/data/data");
nFrames = size(raw, 3);

if isempty(frameNumber)
    frameNumber = 1;
end
if frameNumber < 1 || frameNumber > nFrames || mod(frameNumber, 1) ~= 0
    error('readHDF5Image:badFrame', ...
        'FrameNumber %g out of range: "%s" has %d frame(s).', ...
        frameNumber, hdf5Path, nFrames);
end

img = int32(raw(:, :, frameNumber));
end
