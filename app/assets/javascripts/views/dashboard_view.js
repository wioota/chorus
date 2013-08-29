chorus.views.Dashboard = chorus.views.Base.extend({
    constructorName: "DashboardView",
    templateName:"dashboard/main",
    subviews: {
        '.dashboard_main': "dashboardMain",
        '.data_source_list': "dataSourceList",
        '.workspace_list': "workspaceList",
        '.project_list': "projectList"
    },

    setup: function() {
        this.memberWorkspaces = new chorus.collections.WorkspaceSet(this.collection.where({isMember: true}));
        this.memberWorkspaces.attributes = _.extend({}, this.collection.attributes);
        this.memberWorkspaces.attributes.userId = chorus.session.user().id;
        this.memberWorkspaces.loaded = true;

        this.projectWorkspaces = new chorus.collections.WorkspaceSet(this.collection.where({isProject: true}));
        this.projectWorkspaces.attributes = _.extend({}, this.collection.attributes);
        this.projectWorkspaces.loaded = true;

        this.workspaceList = new chorus.views.MainContentView({
            collection: this.memberWorkspaces,
            contentHeader:chorus.views.StaticTemplate("default_content_header", {title:t("header.my_workspaces")}),
            contentDetails:new chorus.views.StaticTemplate("dashboard/workspace_list_content_details"),
            content:new chorus.views.DashboardWorkspaceList({ collection: this.memberWorkspaces })
        });

        this.projectList = new chorus.views.MainContentView({
            collection: this.projectWorkspaces,
            contentHeader:chorus.views.StaticTemplate("default_content_header", {title:t("header.current_projects")}),
            content:new chorus.views.DashboardProjectList({ collection: this.projectWorkspaces })
        });

        this.dataSourceList = new chorus.views.MainContentView({
            collection: this.options.dataSourceSet,
            contentHeader: chorus.views.StaticTemplate("default_content_header", {title:t("header.browse_data")}),
            contentDetails: new chorus.views.StaticTemplate("dashboard/data_source_list_content_details"),
            content: new chorus.views.DashboardDataSourceList({ collection: this.options.dataSourceSet })
        });

        var activities = new chorus.collections.ActivitySet([]);
        activities.attributes.pageSize = 50;

        activities.fetch();
        this.activityList = new chorus.views.ActivityList({ collection: activities, additionalClass: "dashboard" });
        this.dashboardMain = new chorus.views.MainContentView({
            content: this.activityList,
            contentHeader: new chorus.views.ActivityListHeader({
                collection: activities,
                allTitle: t("dashboard.title.activity"),
                insightsTitle: t("dashboard.title.insights")
            })
        });
    }
});

