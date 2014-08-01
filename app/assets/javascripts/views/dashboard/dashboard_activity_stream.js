chorus.views.DashboardActivityStream = chorus.views.MainContentView.extend({
    constructorName: "DashboardActivityStream",

    setup: function () {
        var activities = new chorus.collections.ActivitySet([]);
        activities.per_page = 10;
        activities.fetch();
        this.content = this.activityList = new chorus.views.ActivityList({ collection: activities, additionalClass: "dashboard" });
        this.contentHeader = new chorus.views.ActivityListHeader({
            collection: activities,
            allTitle: t("dashboard.title.activity"),
            insightsTitle: t("dashboard.title.insights")
        });
    }
});
