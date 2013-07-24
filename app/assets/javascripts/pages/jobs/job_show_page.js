chorus.pages.JobsShowPage = chorus.pages.Base.extend({
    constructorName: 'JobsShowPage',

    makeModel: function (workspaceId, jobId) {
        this.job = this.model = new chorus.models.Job({id: jobId, workspace: {id: workspaceId}});
        this.loadWorkspace(workspaceId, {fetch: false});
    },

    setup: function () {
        this.handleFetchErrorsFor(this.model);

        this.model.fetch();

        this.requiredResources.add(this.job);
        this.breadcrumbs.requiredResources.add(this.job);

        this.mainContent = new chorus.views.LoadingSection();
        this.listenTo(this.model, "loaded", this.setupMainContent);
        this.listenTo(this.model, "invalidated", function () {
            this.model.fetch();
        });
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: '#/workspaces'},
            {label: this.workspace.loaded ? this.workspace.displayName() : "...", url: this.workspace.showUrl()},
            {label: t("breadcrumbs.jobs")},
            {label: this.job.get("name")}
        ];
    },

    setupMainContent: function () {
        this.workspace = this.job.workspace();
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "jobs"});
        this.buttonView = new chorus.views.JobShowPageButtons({model: this.job});

        this.collection = this.job.tasks();

        this.mainContent = new chorus.views.MainContentList({
            modelClass: "JobTask",
            collection: this.collection,
            contentDetailsOptions: {
                buttonView: this.buttonView
            }
        });
    }
});
