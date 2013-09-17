chorus.views.DashboardProjectList = chorus.views.Base.extend({
    constructorName: "DashboardProjectListView",
    templateName: "dashboard/project_list",

    setup: function () {
        this.projectCards = [];
    },

    preRender: function () {
        _.invoke(this.projectCards, 'teardown');
        this.projectCards = this.collection.map(function (workspace) {
            var card = new chorus.views.ProjectCard({model: workspace});
            this.registerSubView(card);
            return card;
        }, this);
    },

    postRender: function () {
        _.each(this.projectCards, function(view) {
            this.$el.append(view.render().el);
        }, this);

        this.styleTooltip();
    },

    styleTooltip: function () {
        // reassign the offset function so that when qtip calls it, qtip correctly positions the tooltips
        // with regard to the fixed-height header.
        var viewport = $(window);
        viewport.offset = function () {
            return { left: 0, top: $("#header").height() };
        };

        $('.icon-info-sign').qtip({
            position: {
                viewport: viewport,
                my: "bottom right",
                at: "top left"
            },
            style: { classes: "tooltip-white" }
        });
    }
});