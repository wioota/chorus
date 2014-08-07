chorus.pages.DashboardPage = chorus.pages.Base.extend({
    constructorName: "DashboardPage",
    hasSubHeader: true,

    setup: function() {
        this.mainContent = new chorus.views.ModularDashboard({});
        this.mainContent.additionalClass = "main_content";
    },

    setupSubHeader: function() {
        var model = new chorus.models.Base({name: t("header.home")});
        this.subHeader = new chorus.views.SubHeader({model: model});
    }
});
