chorus.views.DashboardProjectCardList = chorus.views.DashboardModule.extend({
    constructorName: "DashboardProjectCardList",
    additionalClass: "project_list",

    setup: function () {
        var workspaceSet = new chorus.collections.WorkspaceSet();
        workspaceSet.attributes.showLatestComments = true;
        workspaceSet.attributes.succinct = true;
        workspaceSet.attributes.active = true;
        workspaceSet.sortAsc("name");
        workspaceSet.fetchAll();

        this.contentHeader = new chorus.views.ProjectListHeader({ collection: workspaceSet });
        this.content = new chorus.views.DashboardProjectList({ collection: workspaceSet });
    }
});
