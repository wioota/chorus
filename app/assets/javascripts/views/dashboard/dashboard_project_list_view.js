chorus.views.DashboardProjectList = chorus.views.Base.extend({
    constructorName: "DashboardProjectListView",
    templateName: "dashboard/project_list",

    postRender: function () {
      $('.icon-info-sign').qtip(); //Restyles title text
    },

    collectionModelContext: function(model) {
        return {
            showUrl: model.showUrl(),
            ownerName: model.owner().displayName(),
            ownerShowUrl: model.owner().showUrl()
        };
    }
});