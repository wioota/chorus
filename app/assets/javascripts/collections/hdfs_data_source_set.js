chorus.collections.HdfsDataSourceSet = chorus.collections.Base.extend({
    constructorName: "HdfsDataSourceSet",
    model: chorus.models.HdfsDataSource,
    urlTemplate: "hdfs_data_sources",

    comparator: function(instance) {
        return instance.get("name").toLowerCase();
    },

    urlParams: function () {
        var params = {};

        if (this.attributes.succinct) {
            params.succinct = true;
        }

        return params;
    }
});
