chorus.models.TypeAheadSearchResult = chorus.models.SearchResult.extend({
    constructorName: "TypeAheadSearchResult",
    urlTemplate: "search/type_ahead/",
    numResultsPerPage: 3,

    results: function() {
        var typeAhead = this.get('typeAhead');

        if (!typeAhead) { return []; }
        return _.compact(_.map(typeAhead.results, function(result) {
            switch (result.entityType) {
                case "user":
                    return new chorus.models.User(result);
                case "workspace":
                    return new chorus.models.Workspace(result);
                case "workfile":
                    return new chorus.models.Workfile(result);
                case "hdfs_file":
                    return new chorus.models.HdfsEntry(result);
                case "dataset":
                    return new chorus.models.Dataset(result);
                case "oracle_dataset":
                    return new chorus.models.Dataset(result);
                case "chorus_view":
                    return new chorus.models.ChorusView(result);
                case "gpdb_data_source":
                    return new chorus.models.GpdbDataSource(result);
                case "hdfs_data_source":
                    return new chorus.models.HdfsDataSource(result);
                case "gnip_instance":
                    return new chorus.models.GnipInstance(result);
                case "oracle_data_source":
                    return new chorus.models.OracleDataSource(result);
                case "attachment":
                    return new chorus.models.Attachment(result);
                case "tag":
                    return new chorus.models.Tag(result);
                default:
                    break;
            }
        }));
    },

    isPaginated: function() {
        return true;
    }
});
