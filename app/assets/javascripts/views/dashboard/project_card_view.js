chorus.views.ProjectCard = chorus.views.Base.extend({
    constructorName: 'ProjectCard',
    templateName: 'dashboard/project_card',

    subviews: {
        '.activity': 'insightView',
        '.status': 'statusView'
    },

    setup: function () {
        this.statusView = new chorus.views.ProjectStatus({model: this.model});

        if (this.model.latestInsight()) {
            this.insightView = new chorus.views.Activity({
                model: this.model.latestInsight(),
                isNotification: false,
                isReadOnly: true,
                unexpandable: true
            });
        }
    },

    postRender: function () { this.styleTooltip(); },

    additionalContext: function () {
        var numberOfInsightsOrNot;

        if (this.model.get('numberOfInsights') > 1) {
            numberOfInsightsOrNot = this.model.get('numberOfInsights') - 1;
        }

        return {
            showUrl: this.model.showUrl(),
            latestInsight: this.model.latestInsight() && new chorus.presenters.Activity(this.model.latestInsight()),
            hiddenInsightCount: numberOfInsightsOrNot,
            allInsightsRoute: this.model.showUrl() + '?filter=insights'
        };
    },

    styleTooltip: function () {
        // reassign the offset function so that when qtip calls it, qtip correctly positions the tooltips
        // with regard to the fixed-height header.
        var viewport = $(window);
        viewport.offset = function () {
            return { left: 0, top: $("#header").height() };
        };

        this.$('.info_icon .icon').qtip({
            hide: {
                delay: 500,
                fixed: true,
                event: 'mouseout'
            },
            position: {
                viewport: viewport,
                my: "bottom left",
                at: "top center"
            },
            style: {
                classes: "tooltip-white tooltip",
                tip: {
                    width: 15,
                    height: 20
                }
            }
        });
    }
});