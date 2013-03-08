chorus.collections.HdfsDataSourceSet = chorus.collections.Base.extend({
    constructorName: "HdfsDataSourceSet",
    model: chorus.models.HdfsDataSource,
    urlTemplate: "hdfs_data_sources",

    comparator: function(instance) {
        return instance.get("name").toLowerCase();
    }
});
