chorus.models.Job = chorus.models.Base.extend({
    constructorName: "Job",
    urlTemplate: "workspaces/{{workspace.id}}/jobs/{{id}}",
    showUrlTemplate: "workspaces/{{workspace.id}}/jobs/{{id}}",

    workspace: function() {
        if (!this._workspace && this.get("workspace")) {
            this._workspace = new chorus.models.Workspace(this.get("workspace"));
        }
        return this._workspace;
    },
    
    tasks: function () {
        if (!this._tasks && this.get("tasks")) {
            this._tasks = new chorus.collections.JobTaskSet(this.get("tasks"), {parse: true});
        }
        return this._tasks;
    }
});