chorus.models.InstanceOwnership = chorus.models.Base.extend({
    constructorName: "InstanceOwnership",
    urlTemplate: "data_sources/{{instanceId}}/owner",
    parameterWrapper: "owner"
});