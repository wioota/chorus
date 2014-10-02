    chorus.views.DashboardProjectCardList = chorus.views.DashboardModule.extend({
    constructorName: "DashboardProjectCardList",
    additionalClass: "project_list",

    setup: function () {
        this.fillOutContent('most_active', 'most_active');
    },

    fillOutContent: function(option, state) {
        var workspaceSet = new chorus.collections.WorkspaceSet();

        workspaceSet.attributes.showLatestComments = true;
        workspaceSet.attributes.succinct = true;
        workspaceSet.attributes.active = true;
        if(option) {
            workspaceSet.attributes.getOptions = option;
        }
        workspaceSet.sortAsc("name");
        workspaceSet.fetchAll();

        this.contentHeader = new chorus.views.ProjectListHeader({ collection: workspaceSet, state: state });
        this.content = new chorus.views.DashboardProjectList({ collection: workspaceSet, state: state });
        this.contentHeader.list = this;
        this.contentHeader.projectlist = this.content;
        this.render();
    }
});
