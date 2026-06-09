function sampleTable = makeSampleTable(numRows)
    varNames = {'ImageNum','SampleSet','SampleName','Attenuation','ExposureTime','IncidenceAngle','Temperature','BeamEnergy','Vg','Vd','ElectricalData','Notes'};
    varTypes = {'int32','string','string','doublenan','doublenan','doublenan','doublenan','doublenan','doublenan','doublenan','string','string'};
    sampleTable = table('Size',[numRows, size(varNames, 2)],'VariableTypes',varTypes,'VariableNames',varNames);
end