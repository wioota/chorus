chorus.collections.WorkfileSet = chorus.collections.Base.extend({
    constructorName: "WorkfileSet",
    model:chorus.models.DynamicWorkfile,
    urlTemplate:"workspaces/{{workspaceId}}/workfiles{{#if fileType}}?file_type={{fileType}}{{/if}}",
    showUrlTemplate:"workspaces/{{workspaceId}}/workfiles"
});
