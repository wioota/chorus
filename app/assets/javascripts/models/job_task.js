chorus.models.JobTask = chorus.models.Base.extend({
    constructorName: 'JobTask',
    urlTemplate: "workspaces/{{workspace.id}}/jobs/{{job.id}}/job_tasks/{{id}}",
    showUrlTemplate: "workspaces/{{workspace.id}}/jobs/{{job.id}}/tasks/{{id}}"
});