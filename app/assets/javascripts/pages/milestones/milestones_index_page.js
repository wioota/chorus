chorus.pages.MilestonesIndexPage = chorus.pages.Base.extend({
    constructorName: 'MilestonesIndexPage',

    setup: function (workspaceId) {
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "milestones"});
        this.buttonView = new chorus.views.MilestonesIndexPageButtons({model: this.workspace});

        this.collection = new chorus.collections.MilestoneSet([], {workspaceId: workspaceId});
        this.handleFetchErrorsFor(this.collection);
        this.collection.fetch();

        this.mainContent = new chorus.views.MainContentList(this.listConfig());

        this.subscribePageEvent("milestone:selected", this.milestoneSelected);
        this.listenTo(this.collection, "invalidated", function () { this.collection.fetch(); });

        this.requiredResources.add(this.workspace);
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
