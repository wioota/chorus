chorus.collections.JdbcHiveDataSourceSet = chorus.collections.Base.extend({
    constructorName: "JdbcHiveDataSourceSet",
    model: chorus.models.JdbcHiveDataSource,
    urlTemplate: "jdbc_hive_data_sources",

    comparator: function(dataSource) {
        return dataSource.get("name").toLowerCase();
    },

    urlParams: function () {
        var params = {};

        if (this.attributes.succinct) {
            params.succinct = true;
        }

        return params;
    }
});
