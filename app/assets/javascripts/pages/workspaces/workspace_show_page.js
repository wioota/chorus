chorus.pages.WorkspaceShowPage = chorus.pages.Base.extend({
    helpId: "workspace_summary",

    setup: function(workspaceId) {
        this.listenTo(this.model, "loaded", this.decideIfQuickstart);
        this.subNav = new chorus.views.SubNav({workspace: this.model, tab: "summary"});
        this.sidebar = new chorus.views.WorkspaceShowSidebar({model: this.model});

        this.mainContent = new chorus.views.MainContentView({
            model: this.model,
            content: new chorus.views.WorkspaceShow({model: this.model }),
            contentHeader: new chorus.views.WorkspaceSummaryContentHeader({model: this.model})
        });

        this.breadcrumbs.requiredResources.add(this.model);
        this.listenTo(this.model, 'saved', this.render);
    },

    makeModel: function(workspaceId) {
        this.loadWorkspace(workspaceId, {required: true});
        this.model = this.workspace;
    },

    decideIfQuickstart: function() {
        if (this.model.owner().get("id") === chorus.session.user().id) {
            if (!this.quickstartNavigated && (
                this.model.get("hasAddedMember") === false ||
                this.model.get("hasAddedWorkfile") === false ||
                this.model.get("hasAddedSandbox") === false ||
                this.model.get("hasChangedSettings") === false)) {

                chorus.router.navigate("/workspaces/" + this.workspaceId + "/quickstart");
                return;
            }
        }
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: "#/workspaces"},
            {label: this.model && this.model.loaded ? this.model.displayShortName() : "..."}
        ];
    }
});
