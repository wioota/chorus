chorus.collections.DatabaseSet = chorus.collections.Base.include(
    chorus.Mixins.InstanceCredentials.model
).extend({
    constructorName: "DatabaseSet",
    model:chorus.models.Database,
    urlTemplate: "data_sources/{{instanceId}}/databases",
    showUrlTemplate: "data_sources/{{instanceId}}/databases"
});
