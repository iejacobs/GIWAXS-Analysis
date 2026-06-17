function sampleTable = getSubSampleTable(sampleTable,varargin)
%GETSAMPLESFROMTABLE Summary of this function goes here
%   Detailed explanation goes here

p = inputParser;

%Sample Table Rows
addParameter(p,'SampleTableRows',NaN,@(x)isnumeric(x) || ismissing(x));

%imgnum
addParameter(p,'ImageNum',NaN,@(x)isnumeric(x) || ismissing(x));

%Sample Set (e.g. user)
addParameter(p,'SampleSet',"",@(x) (isstring(x) || ismissing(x)));

%SampleName
addParameter(p,'SampleName',"",@(x) isstring(x) || ismissing(x));

%Attenuation
addParameter(p,'Attenuation',NaN,@(x)isnumeric(x) || ismissing(x));

%ExposureTime
addParameter(p,'ExposureTime',NaN,@(x)isnumeric(x) || ismissing(x));

%IncidenceAngle
addParameter(p,'IncidenceAngle',NaN,@(x)isnumeric(x) || ismissing(x));

%Temperature
addParameter(p,'Temperature',NaN,@(x)isnumeric(x) || ismissing(x));

%BeamEnergy
addParameter(p,'BeamEnergy',NaN,@(x)isnumeric(x) || ismissing(x));

%Vg
addParameter(p,'Vg',NaN,@(x)isnumeric(x) || ismissing(x));

%Vd
addParameter(p,'Vd',NaN,@(x)isnumeric(x) || ismissing(x));

%ElectricalData
addParameter(p,'ElectricalData',"",@(x)isstring(x) || ismissing(x));

%Notes
addParameter(p,'Notes',"",@(x)isstring(x) || ismissing(x));

parse(p,varargin{:})

for i=1:length(p.Parameters)
    %special cases
    if strcmp(p.Parameters(i),"SampleTableRows") %sampletablerows parameter
        %if specified, retain only those rows
        if ~isnan(getfield(p.Results,p.Parameters{i}))
            sampleTable = sampleTable(p.Results.SampleTableRows,:);
        end

    %string based parameters
    elseif isstring(getfield(p.Results,p.Parameters{i})) 
        %if values is specified, then...
        if isempty(find(ismember(p.UsingDefaults,p.Parameters{i}),1))
            
            %get rows of table that equal desired values...
            ind = strcmp(getfield(sampleTable,p.Parameters{i}), getfield(p.Results,p.Parameters{i}));

            %if the string is empty, add in missing entries also
            if strcmp(getfield(p.Results,p.Parameters{i}),"")
                indMissing = ismissing(getfield(sampleTable,p.Parameters{i}));
                ind = or(ind, indMissing);
            end
            %retain only the matching rows
            sampleTable = sampleTable(ind,:);
        end
    
    %for other parameters...
    else
        %if not default values, then...
        if isempty(find(ismember(p.UsingDefaults,p.Parameters{i}),1))

            %get rows of table whose value is in the requested set. ismember
            %accepts either a scalar (equivalent to ==) or a vector/range
            %(e.g. ImageNum = 620152:620159), so a set of data can be matched
            ind = ismember(getfield(sampleTable,p.Parameters{i}), getfield(p.Results,p.Parameters{i}));

            %retain only the matching rows
            sampleTable = sampleTable(ind,:);
        end
    end
end
end

