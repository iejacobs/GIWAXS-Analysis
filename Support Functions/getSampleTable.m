function sampleTable = getSampleTable(sampleTableFull,varargin)
%GETSAMPLETABLE Summary of this function goes here
%   Detailed explanation goes here
%select user data and remove unused vars

if nargin == 2
    imagenum = varargin{1};
elseif nargin == 4
    imagenum = varargin{1};
    atten = varargin{2};
    exptime = varargin{3};
end
if exist('imagenum')
    indices = sampleTableFull.ImageNum == imagenum;
    indices = sum(indices,2);
    indices = find(indices);
end
sampleTable = sampleTableFull(indices,:);


if exist('atten')
    sampleTable = sampleTable(sampleTable.Attenuation == atten,:);
end
if exist('exptime')
    sampleTable = sampleTable(sampleTable.ExposureTime == exptime,:);
end
% if invertOrder
%     sampleTable = flipud(sampleTable);
% end
end

