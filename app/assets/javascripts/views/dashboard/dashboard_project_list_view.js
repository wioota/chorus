chorus.views.DashboardProjectList = chorus.views.Base.extend({
    constructorName: "DashboardProjectListView",
    templateName: "dashboard/project_list",

    setup: function() {
    },

    collectionModelContext: function(model) {
        return {
            showUrl: model.showUrl(),
            ownerName: model.owner().displayName(),
            ownerShowUrl: model.owner().showUrl()
        };
    }
});