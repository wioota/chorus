chorus.views.DashboardProjectList = chorus.views.Base.extend({
    constructorName: "DashboardProjectListView",
    templateName: "dashboard/project_list",

    postRender: function () {
        $('.icon-info-sign').qtip(); //Restyles title text
    },

    collectionModelContext: function(model) {
        var numberOfInsightsOrNot;

        if (model.get('numberOfInsights') > 1) {
            numberOfInsightsOrNot = model.get('numberOfInsights') - 1;
        }

        return {
            showUrl: model.showUrl(),
            ownerName: model.owner().displayName(),
            ownerShowUrl: model.owner().showUrl(),
            latestInsight: model.latestInsight() && new chorus.presenters.Activity(model.latestInsight()),
            hiddenInsightCount: numberOfInsightsOrNot,
            allInsightsRoute: model.showUrl()+'?filter=insights'
        };
    }
});