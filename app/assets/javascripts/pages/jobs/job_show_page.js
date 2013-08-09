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
        this.listenTo(this.model, "invalidated", function () { this.model.fetch(); });
    },

    crumbs: function() {
        return [
            {label: t("breadcrumbs.home"), url: "#/"},
            {label: t("breadcrumbs.workspaces"), url: '#/workspaces'},
            {label: this.workspace.loaded ? this.workspace.displayName() : "...", url: this.workspace.showUrl()},
            {label: t("breadcrumbs.jobs"), url: this.workspace.jobsUrl()},
            {label: this.job.get("name")}
        ];
    },

    jobTaskSelected: function (task) {
        if(this.sidebar) this.sidebar.teardown(true);

        this.sidebar = new chorus.views.JobTaskSidebar({model: task});
        this.renderSubview('sidebar');
    },

    setupMainContent: function () {
        this.workspace = this.job.workspace();
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "jobs"});

        this.collection = this.job.tasks();

        this.subscribePageEvent("job_task:selected", this.jobTaskSelected);

        var headerOptions = {
            title: this.job.get('name'),
            frequency: this.job.frequency() ,
            nextRun: this.job.get("nextRun"),
            lastRun: this.job.get("lastRun")
        };

        if (this.collection.length > 0) {
            this.mainContent = new chorus.views.MainContentList({
                modelClass: "JobTask",
                contentHeader: new chorus.views.StaticTemplate("job_show_content_header", headerOptions),
                collection: this.collection,
                contentDetails: this.contentDetails()
            });
        } else {
            this.mainContent = new chorus.views.MainContentView({
                content: new chorus.views.JobQuickstart({model: this.job}),
                contentHeader: new chorus.views.StaticTemplate("job_show_content_header", headerOptions),
                contentDetails: this.contentDetails()
            });
        }
    },

    contentDetails: function () {
        return new chorus.views.JobContentDetails({model: this.job});
    }
});
