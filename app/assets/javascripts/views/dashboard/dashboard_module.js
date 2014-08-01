chorus.views.DashboardModule = chorus.views.Base.extend({
    constructorName: "DashboardModuleView",
    templateName:"dashboard/module",

    additionalContext: function () {
        return {
            content: this.options.content
        };
    }

});

chorus.views.DashboardModule1 = chorus.views.DashboardModule;
chorus.views.DashboardModule2 = chorus.views.DashboardModule;
chorus.views.DashboardModule3 = chorus.views.DashboardModule;
