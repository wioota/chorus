chorus.pages.DashboardPage = chorus.pages.Base.extend({
    constructorName: "DashboardPage",

    setup: function () {
        this.mainContent = new chorus.views.ModularDashboard({});
    }
});
