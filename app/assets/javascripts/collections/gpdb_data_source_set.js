chorus.collections.GpdbDataSourceSet = chorus.collections.Base.extend({
    constructorName: "GpdbDataSourceSet",
    model: chorus.models.GpdbDataSource,
    urlTemplate: "data_sources/",

    urlParams: function() {
        return _.extend(this._super('urlParams') || {}, {
            accessible: this.attributes.accessible,
            entityType: "gpdb_data_source"
        });
    },

    comparator: function(dataSource) {
        return dataSource.get("name").toLowerCase();
    }
});
