chorus.views.WorkspaceList = chorus.views.CheckableList.extend({
    eventName: "workspace",

    setup: function(){
        this.options.entityType = "workspace";
        this.options.entityViewType = chorus.views.Workspace;
        this._super("setup", arguments);
    }
});
