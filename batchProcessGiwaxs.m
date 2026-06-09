clear all
clc
close all

%Specify raw data and processed and data paths. Data will be saved in a
%subfolder for each user in the processed data folder.
processPars.ImagePath = "/Users/ianjacobs/Dropbox (Cambridge University)/Research/GIWAXS/January 2024 Beamtime/Raw Data/si35227-1/pilatus2"
processPars.OutputPath = "/Users/ianjacobs/Dropbox (Cambridge University)/Research/GIWAXS/January 2024 Beamtime/Reprocessed Data New FF"

%Specify sample table to use; for previous year's data this will change.
sampleTableFile = "sampleTable2024.mat"

%Specify data to process. Selects only data matching ALL conditions.
%Comment out any parameters which you don't which to use

ImageNum = 501555;
SampleSet = "Hio-Ieng";
%SampleName = ""
%Attenuation = 0
%ExposureTime = 1
%IncidenceAngle = 0.2
%Temperature = 290
%BeamEnergy = 12.5
%Vg = 0
%Vd = 0
%ElectricalData = ""
%Notes = ""

%% Additional processing parameters

%Specify color limits for diffraction images. If current image is too dark,
%reduce these values; if too light, increase them. Note, these values are
%automatically scaled for attenuation and exposure time. To turn off
%automatic scaling set scaleToExposure to false
processPars.CLim = [1 10000];
processPars.ScaleToExposure = true;

%Specify colormap to use in diffraction images. Third party color maps are
%supported, just give the name of the generating function.
processPars.Colormap = "magma"

processPars.IPCutQ = [0.1 0.12];

%Specify q range for reshaped diffraction images. 
processPars.ReshapeQr = [-0.8 3.2];
processPars.ReshapeQz = [0 3.2];

%Specify reshaped image size (in pixels). Too high can lead to artifacts in
%reshaped images.
processPars.ReshapePoints = [900,900];

%If you don't want to save the data, set this to false
processPars.SaveData = true;

%NOTE: there are additional parameters you can specify if necessary, see
%giwaxsProcess function.


%% Process GIWAXS data

%load sample table
load(sampleTableFile)

%get sample table matching values set above
varnames = sampleTable.Properties.VariableNames;
for i = 1:length(varnames)
    if exist(varnames{i})'
        if exist("pars")
            pars = {pars{:},varnames{i},eval(varnames{i})};
        else
             pars = {varnames{i},eval(varnames{i})};
        end
    end
end

%get matching subtable and display in console
sampleTable = getSubSampleTable(sampleTable,pars{:})

%get processing parameter list
if exist("processPars")
    processParsNames = fieldnames(processPars);
    for i = 1:length(fieldnames(processPars))
        if exist("processParsList")
            processParsList = {processParsList{:},processParsNames{i},getfield(processPars,processParsNames{i})};
        else
            processParsList = {processParsNames{i},getfield(processPars,processParsNames{i})};
        end
    end
else
    processParsList = {};
end

%process giwaxs data
for i = 1:height(sampleTable)
    close all

    [data,ipcut,oopcut] = giwaxsProcess(sampleTable(i,:),processParsList{:});
end
