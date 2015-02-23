chorus.views.DashboardRecentWorkspaces = chorus.views.DashboardModule.extend({
    constructorName: "DashboardRecentWorkspaces",
    templateName:"dashboard/recent_workspaces",

    events:{
        "click #recent_workspaces_main_content .configure": "showOptions",
        "click #recent_workspaces_main_content .clear_list": "clearList",
        "click #recent_workspaces_configuration .cancel": "hideOptions",
        "click #recent_workspaces_configuration .submit": "saveOptions"
    },

    setup: function() {
        this.model = new chorus.models.DashboardData({});
        this.model.urlParams = { entityType: 'recent_workspaces' };
        this.model.fetch({
            success: _.bind(this.fetchComplete, this)
        });
        this.recentWorkspaceModel = new chorus.models.RecentWorkspaces();
    },

    fetchComplete: function() {
        var workspaces = _.map(this.model.get("data"), function(openEvent) {
            openEvent.workspace.lastOpened = openEvent.lastOpened;
            return openEvent.workspace;
        }, this);
        this.resource = this.collection = new chorus.collections.WorkspaceSet(workspaces);
        this.render();
        if (this.$('#recent_workspaces_configuration').is(':visible')) {
			this.$('#recent_workspaces_configuration').fadeOut(89);
        }
    },

    additionalContext: function () {
        return {
            modelLoaded: this.model.get("data") !== undefined,
            hasModels: this.model.get("data") ? this.model.get("data").length > 0 : false
        };
    },

    collectionModelContext: function(model) {
        return {
            iconUrl: model.iconUrl(),
            showUrl: model.showUrl(),
            workspaceShowUrl: model.workspace().showUrl(),
            workspaceIconUrl: model.workspace().defaultIconUrl("small")
        };
    },

    showOptions: function(event) {
        event.preventDefault();
        this.$('#recent_workspaces_configuration').fadeIn(180);

        _.defer(_.bind(function () {
            chorus.styleSelect(this.$(".recent_items_select"));
        }, this));
        this.$(".recent_items_select").val(this.$('#recent_workspaces_main_content li').length);
    },

    hideOptions: function(event) {
        event.preventDefault();
        this.$('#recent_workspaces_configuration').fadeOut(100);
    },

    saveOptions: function(event) {
        event.preventDefault();
        this.recentWorkspaceModel.save({action: "updateOption", optionValue: this.$(".recent_items_select").val()}, {
            success: _.bind(this.setup, this)
        });
    },

    clearList: function(event) {
        event.preventDefault();
        this.recentWorkspaceModel.save({action: "clearList"}, {
            success: _.bind(this.setup, this)
        });
    }
});
