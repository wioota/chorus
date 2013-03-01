chorus.collections.DataSourceSet = chorus.collections.Base.extend({
    urlTemplate: 'data_sources?accessible={{accessible}}',
    constructorName: 'DataSourceSet',
    model: chorus.models.DynamicDataSource,

    comparator: function(dataSource) {
        return dataSource.get("name").toLowerCase();
    }
});
