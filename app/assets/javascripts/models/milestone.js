chorus.models.Milestone = chorus.models.Base.extend({
    entityType: "Milestone",
    constructorName: "Milestone",
    urlTemplate: "workspaces/{{workspace.id}}/milestones/{{id}}",

    workspace: function() {
        if (!this._workspace && this.get("workspace")) {
            this._workspace = new chorus.models.Workspace(this.get("workspace"));
        }
        return this._workspace;
    }
});