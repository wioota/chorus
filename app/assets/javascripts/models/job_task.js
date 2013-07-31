chorus.models.JobTask = chorus.models.Base.extend({
    constructorName: 'JobTask',
    urlTemplate: "workspaces/{{workspace.id}}/jobs/{{job.id}}/job_tasks/{{id}}",
    showUrlTemplate: "workspaces/{{workspace.id}}/jobs/{{job.id}}/tasks/{{id}}",

    job: function () {
        if (!this._job && this.get("job")) {
            this._job = new chorus.models.Job(this.get("job"));
        }
        return this._job;
    }
});