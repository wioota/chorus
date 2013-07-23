chorus.pages.JobsIndexPage = chorus.pages.Base.extend({
    constructorName: 'JobsIndexPage',

    setup: function (workspaceId) {
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "jobs"});
        this.buttonView = new chorus.views.JobIndexPageButtons({model: this.workspace});

        this.collection = new chorus.collections.JobSet([], {workspaceId: workspaceId});
        this.collection.fetchAll();

        this.mainContent = new chorus.views.MainContentList({
            modelClass: "Job",
            collection: this.collection,
            contentDetailsOptions: {
                multiSelect: true,
                buttonView: this.buttonView
            }
        });

        this.requiredResources.add(this.workspace);
        this.breadcrumbs.requiredResources.add(this.workspace);
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: '#/workspaces'},
            {label: this.workspace.loaded ? this.workspace.displayName() : "...", url: this.workspace.showUrl()},
            {label: t("breadcrumbs.jobs")}
        ];
    },

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId);
    }
});
