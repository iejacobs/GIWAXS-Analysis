classdef SampleTable
%SAMPLETABLE A beamtime's GIWAXS sample log, with subset selection + batch run.
%   Wraps the per-beamtime sample table (the plain MATLAB table saved in
%   sampleTable<year>.mat) and adds chainable selection helpers and a one-call
%   batch-processing method, so a processing run on a subset of the measured
%   data reads as, e.g.:
%
%       data = SampleTable(beamtimeDir);
%       data.bySampleSet("Ian").bySample("1 PBTTT Undoped").process(processPars);
%
%   The underlying table (.Data) keeps the usual schema (ImageNum, SampleSet,
%   SampleName, Attenuation, ..., GapFillPartner). Selection reuses
%   getSubSampleTable; processing reuses giwaxsProcess (one output per gap-fill
%   pair). This is a value class: selection methods return a new SampleTable,
%   so they chain without mutating the original.
%
%   See also getSubSampleTable, giwaxsProcess, beamtimeConfig.

    properties
        Data                         % the underlying MATLAB table
        Beamtime (1,1) string = ""   % beamtime root folder (for processing)
    end

    methods
        function obj = SampleTable(beamtime, dataTbl)
            %SAMPLETABLE Construct from a beamtime folder, or wrap a table.
            %   SampleTable(BEAMTIME) loads that beamtime's sample table (via
            %   beamtimeConfig). SampleTable(BEAMTIME, DATATBL) wraps a given
            %   table while keeping BEAMTIME (used by the selection methods).
            arguments
                beamtime (1,1) string
                dataTbl = []
            end
            obj.Beamtime = beamtime;
            if istable(dataTbl)
                obj.Data = dataTbl;
            else
                cfg = beamtimeConfig(beamtime);
                loaded = load(cfg.SampleTableFile);
                obj.Data = loaded.sampleTable;
            end
        end

        %% Selection (chainable; each returns a new SampleTable)
        function obj = select(obj, varargin)
            %SELECT Filter by name-value pairs (see getSubSampleTable).
            %   Strings match exactly; numerics accept a scalar or a set/range
            %   (e.g. 'ImageNum', 620152:620159 or 'Attenuation', [0 3]).
            obj = SampleTable(obj.Beamtime, getSubSampleTable(obj.Data, varargin{:}));
        end
        function obj = bySampleSet(obj, sampleSet)   % e.g. user
            obj = obj.select('SampleSet', string(sampleSet));
        end
        function obj = bySample(obj, sampleName)
            obj = obj.select('SampleName', string(sampleName));
        end
        function obj = byAttenuation(obj, attenuation)
            obj = obj.select('Attenuation', attenuation);
        end
        function obj = byImage(obj, imageNum)
            obj = obj.select('ImageNum', imageNum);
        end
        function obj = byTemperature(obj, temperature)
            obj = obj.select('Temperature', temperature);
        end

        %% Discovery / display
        function u = users(obj)
            %USERS Unique sample sets (users) present, excluding missing.
            u = SampleTable.uniquePresent(obj.Data.SampleSet);
        end
        function s = samples(obj)
            %SAMPLES Unique sample names present, excluding missing.
            s = SampleTable.uniquePresent(obj.Data.SampleName);
        end
        function n = height(obj)
            %HEIGHT Number of measurements (rows).
            n = height(obj.Data);
        end
        function summary(obj)
            %SUMMARY Print a breakdown of the selection.
            fprintf('SampleTable - %d measurements (beamtime: %s)\n', height(obj.Data), obj.Beamtime);
            fprintf('  %d gap-fill pairs\n', obj.nGapFillPairs());
            u = obj.users();
            fprintf('  %d users: %s\n', numel(u), join(u, ', '));
            s = obj.samples();
            fprintf('  %d samples\n', numel(s));
        end
        function disp(obj)
            %DISP Custom display: a one-line summary then a table preview.
            n = height(obj.Data);
            fprintf('  SampleTable  (%d measurements, %d gap-fill pairs; beamtime: %s)\n', ...
                n, obj.nGapFillPairs(), obj.Beamtime);
            if ~isempty(obj.users)
                fprintf('  users: %s\n', join(obj.users, ', '));
            end
            fprintf('\n');
            if n > 12
                disp(head(obj.Data));
                fprintf('  ... (%d rows total)\n\n', n);
            else
                disp(obj.Data);
            end
        end

        %% Batch processing
        function varargout = process(obj, varargin)
            %PROCESS Run giwaxsProcess over the selection (one output per pair).
            %   PROCESS(OBJ, PROCESSPARS) or PROCESS(OBJ, Name,Value,...) passes
            %   the processing options to giwaxsProcess. The beamtime is supplied
            %   automatically, so giwaxsProcess resolves the data/calibration/
            %   correction paths from beamtimeConfig. Gap-fill partners are
            %   combined into a single output, so each pair is processed once.
            %   If an output is requested, returns a cell of the processed
            %   gixsdata objects.
            opts = SampleTable.optionsToNameValue(varargin);

            hasGapFill = ismember('GapFillPartner', obj.Data.Properties.VariableNames);
            alreadyProcessed = false(height(obj.Data), 1);
            results = {};

            for i = 1:height(obj.Data)
                if alreadyProcessed(i)
                    continue
                end
                close all
                d = giwaxsProcess(obj.Data(i,:), 'Beamtime', obj.Beamtime, opts{:});
                alreadyProcessed(i) = true;
                if nargout > 0
                    results{end+1} = d; %#ok<AGROW>
                end

                % a gap-fill partner is combined into the same output; if that
                % partner is also in this selection, skip it (avoid duplicates)
                if hasGapFill && ~isnan(obj.Data.GapFillPartner(i))
                    alreadyProcessed(obj.Data.ImageNum == obj.Data.GapFillPartner(i)) = true;
                end
            end

            if nargout > 0
                varargout{1} = results;
            end
        end
    end

    methods (Access = private)
        function n = nGapFillPairs(obj)
            if ismember('GapFillPartner', obj.Data.Properties.VariableNames)
                n = nnz(~isnan(obj.Data.GapFillPartner)) / 2;
            else
                n = 0;
            end
        end
    end

    methods (Static, Access = private)
        function v = uniquePresent(col)
            % unique values of a column, dropping <missing>
            v = unique(col);
            v = v(~ismissing(v));
        end
        function nv = optionsToNameValue(args)
            % accept a single processPars struct or raw name-value pairs
            if isscalar(args) && isstruct(args{1})
                s = args{1};
                fn = fieldnames(s);
                vals = struct2cell(s);
                nv = cell(1, 2*numel(fn));
                nv(1:2:end) = fn;
                nv(2:2:end) = vals;
            else
                nv = args;
            end
        end
    end
end
