chorus.views.DataTabDatasetList = chorus.views.Base.extend({
    constructorName: "DataTabDatasetListView",
    templateName: "data_tab_dataset_list",
    useLoadingSection: true,

    events: {
        "click a.more"  : "fetchMoreDatasets"
    },

    setup: function() {
        this.bindings.add(this.collection, "reset", this.rebuildDatasetViews);
        this.datasetViews = [];
    },

    postRender: function() {
        _.each(this.datasetViews, function(view) {
            this.$("ul").append(view.render().$el);
            view.delegateEvents();
        }, this);
    },

    rebuildDatasetViews: function() {
        _.each(this.datasetViews, function(view) {
            view.teardown();
        });

        this.datasetViews = [];
        this.collection.each(function(model) {
            var datasetView = new chorus.views.DataTabDataset({model: model});
            this.datasetViews.push(datasetView);
            this.registerSubView(datasetView);
        }, this);

        this.render();
    },

    fetchMoreDatasets: function(e) {
        e && e.preventDefault();
        this.trigger("fetch:more");
    },

    additionalContext:function () {
        var ctx = {};
        if (this.collection.pagination) {
            ctx.showMoreLink = this.collection.pagination.page < this.collection.pagination.total;
        }
        return ctx;
    },

    displayLoadingSection: function () {
        return !(this.collection && this.collection.loaded || this.collection.serverErrors);
    }
});