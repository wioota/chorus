chorus.collections.DatabaseSet = chorus.collections.Base.include(
    chorus.Mixins.DataSourceCredentials.model
).extend({
    constructorName: "DatabaseSet",
    model:chorus.models.Database,
    urlTemplate: "data_sources/{{instanceId}}/databases",
    showUrlTemplate: "data_sources/{{instanceId}}/databases"
});
