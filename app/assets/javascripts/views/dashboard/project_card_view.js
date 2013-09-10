chorus.views.ProjectCard = chorus.views.Base.extend({
    constructorName: 'ProjectCard',
    templateName: 'dashboard/project_card',

    subviews: {
        '.activity': 'insightView'
    },

    setup: function () {
        if (this.model.latestInsight()){
            this.insightView = new chorus.views.Activity({
                model: this.model.latestInsight(),
    //            displayStyle: this.options.displayStyle,
                isNotification: false,
                isReadOnly: true,
                unexpandable: true
            });
        }
    },

    additionalContext: function () {
        var numberOfInsightsOrNot;

        if (this.model.get('numberOfInsights') > 1) {
            numberOfInsightsOrNot = this.model.get('numberOfInsights') - 1;
        }

        return {
            showUrl: this.model.showUrl(),
            ownerName: this.model.owner().displayName(),
            ownerShowUrl: this.model.owner().showUrl(),
            latestInsight: this.model.latestInsight() && new chorus.presenters.Activity(this.model.latestInsight()),
            hiddenInsightCount: numberOfInsightsOrNot,
            allInsightsRoute: this.model.showUrl()+'?filter=insights'
        };
    }
});