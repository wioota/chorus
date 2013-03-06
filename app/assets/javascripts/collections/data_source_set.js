chorus.collections.DataSourceSet = chorus.collections.Base.extend({
    urlTemplate: 'data_sources',
    constructorName: 'DataSourceSet',
    model: chorus.models.DynamicDataSource,
    urlParams: function() {
        return { all: this.attributes.all };
    },

    comparator: function(dataSource) {
        return dataSource.get("name").toLowerCase();
    }
});
