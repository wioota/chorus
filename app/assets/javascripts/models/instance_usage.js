chorus.models.InstanceUsage = chorus.models.Base.extend({
    constructorName: "InstanceUsage",
    urlTemplate:"data_sources/{{instanceId}}/workspace_detail",

    workspaceCount: function() {
        return this.get("workspaces") && this.get("workspaces").length;
    }
});
