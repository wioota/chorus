chorus.collections.GnipDataSourceSet = chorus.collections.Base.extend({
    constructorName: "GnipDataSourceSet",
    model: chorus.models.GnipDataSource,
    urlTemplate: "gnip_data_sources",

    comparator: function(instance) {
        return instance.get("name").toLowerCase();
    }
});
