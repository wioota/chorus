chorus.views.DashboardProjectList = chorus.views.Base.extend({
    constructorName: "DashboardProjectListView",
    templateName: "dashboard/project_list",
    noFilter: true,

    setup: function () {
        this.projectCards = [];
        this.listenTo(this.collection, 'filter:members_only', function () { this.triggerRender(false); }, this);
        this.listenTo(this.collection, 'filter:all',          function () { this.triggerRender(true); }, this);
    },

    preRender: function () {
        _.invoke(this.projectCards, 'teardown');
        this.projectCards = this.collection.filter(this.filter, this).map(function (workspace) {
            var card = new chorus.views.ProjectCard({model: workspace});
            this.registerSubView(card);
            return card;
        }, this);
    },

    postRender: function () {
        _.each(this.projectCards, function(view) {
            this.$el.append(view.render().el);
        }, this);
    },

    triggerRender: function (bool) {
        this.noFilter = bool;
        this.render();
    },

    filter: function (project) {
        return this.noFilter || project.get('isMember');
    }
});