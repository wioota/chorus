chorus.views.ModularDashboard = chorus.views.Base.extend({
    constructorName: "ModularDashboardView",
    templateName:"dashboard/module_list",

    makeModel: function () {
        this.model = new chorus.models.DashboardConfig({userId: chorus.session.user().id});
    },

    setup: function() {
        this.model.fetch();
    },

    preRender: function() {
        _.each(this.model.get("modules"), function (moduleName, i) {
            this["module"+i] = new chorus.views["Dashboard" + moduleName]({content: moduleName});
        }, this);
    },

    setupSubviews: function () {
        _.each(this.model.get("modules"), function (moduleName, i) {
            this.subviews['.module_'+i] = 'module'+i;
        }, this);
    }
});

