chorus.pages.MilestonesIndexPage = chorus.pages.Base.extend({
    constructorName: 'MilestonesIndexPage',

    setup: function (workspaceId) {
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "milestones"});

        this.collection = new chorus.collections.MilestoneSet([], {workspaceId: workspaceId});
        this.collection.fetch();

        this.mainContent = new chorus.views.MainContentList(this.listConfig());

        this.subscribePageEvent("milestone:selected", this.milestoneSelected);

        this.requiredResources.add(this.workspace);
        this.breadcrumbs.requiredResources.add(this.workspace);
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: '#/workspaces'},
            {label: this.workspace.loaded ? this.workspace.displayName() : "...", url: this.workspace.showUrl()},
            {label: t("breadcrumbs.milestones")}
        ];
    },

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId);
    },

    milestoneSelected: function (milestone) {
        if (this.sidebar) this.sidebar.teardown(true);

        this.sidebar = new chorus.views.MilestoneSidebar({model: milestone});
        this.renderSubview('sidebar');
    },

    listConfig: function () {
        return {
            modelClass: "Milestone",
            collection: this.collection,
            contentDetailsOptions: {
                multiSelect: true,
                buttonView: this.buttonView
            },
            linkMenus: {
            },
            search: {

            }
        };
    }

});
