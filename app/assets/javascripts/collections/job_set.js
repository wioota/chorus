chorus.collections.JobSet = chorus.collections.Base.extend({
    constructorName: "JobSet",
    model:chorus.models.Job,
    urlTemplate:"workspaces/{{workspaceId}}/jobs"
});
