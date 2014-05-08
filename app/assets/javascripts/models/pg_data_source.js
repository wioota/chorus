chorus.models.PgDataSource = chorus.models.DataSource.extend({
    constructorName: 'PgDataSource',
    entityType: 'pg_data_source',
    showUrlTemplate: "data_sources/{{id}}/schemas",
    parameterWrapper: "data_source",
    defaults: {
        entityType: 'pg_data_source'
    }
});
