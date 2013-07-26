chorus.pages.JobsIndexPage = chorus.pages.Base.extend({
    constructorName: 'JobsIndexPage',

    setup: function (workspaceId) {
        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "jobs"});
        this.buttonView = new chorus.views.JobIndexPageButtons({model: this.workspace});

        this.collection = new chorus.collections.JobSet([], {workspaceId: workspaceId});
        this.collection.sortAsc("name");
        this.collection.fetchAll();

        this.mainContent = new chorus.views.MainContentList(this.listConfig());

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu(this.multiSelectSidebarConfig());

        this.mainContent.contentHeader.bind("choice:sort", function(choice) {
            var field = choice === "alpha" ? "name" : "nextRun";
            this.collection.sortAsc(field);
            this.collection.fetchAll();
        }, this);

        this.subscribePageEvent("job:search", function() {
            chorus.PageEvents.trigger('selectNone');
        });

        this.subscribePageEvent("job:selected", this.jobSelected);

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
    },

    jobSelected: function (job) {
        if(this.sidebar) this.sidebar.teardown(true);

        this.sidebar = new chorus.views.JobSidebar({model: job});
        this.renderSubview('sidebar');
    },

    listConfig: function () {
        return {
            modelClass: "Job",
                collection: this.collection,
            contentDetailsOptions: {
            multiSelect: true,
                buttonView: this.buttonView
        },
            linkMenus: {
                sort: {
                    title: t("job.header.menu.sort.title"),
                        options: [
                        {data: "alpha", text: t("job.header.menu.sort.alphabetically")},
                        {data: "date", text: t("job.header.menu.sort.by_date")}
                    ],
                        event: "sort"
                }
            },
            search: {
                placeholder: t("job.search_placeholder"),
                    eventName: "job:search"
            }
        };
    },

    multiSelectSidebarConfig: function () {
        return {
            selectEvent: "job:checked",
            actions: [
                '<a class="disable_jobs">{{t "job.actions.disable_job"}}</a>',
                '<a class="delete_jobs">{{t "job.actions.delete_job"}}</a>'
            ],
            actionEvents: {
                'click .disable_jobs': _.bind(function() {}, this),
                'click .delete_jobs': _.bind(function() {}, this)
            }
        };
    }
});
