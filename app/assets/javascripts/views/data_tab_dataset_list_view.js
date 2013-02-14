chorus.views.DataTabDatasetList = chorus.views.Base.extend({
    constructorName: "DataTabDatasetListView",
    templateName: "data_tab_dataset_list",
    useLoadingSection: true,

    events: {
        "click li a"    : "datasetSelected",
        "click a.more"  : "fetchMoreDatasets"
    },

    setup: function() {
        this.bindings.add(this.collection, "reset", this.render);
    },

    datasetSelected: function (e) {
        e.preventDefault();
        var li = $(e.currentTarget).closest("li"),
            type = li.data("type"),
            name = li.data("name").toString();

        var dataset = this.collection.findWhere({ entitySubtype:type, objectName: name });
        chorus.PageEvents.broadcast("datasetSelected", dataset);
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

    collectionModelContext: function(model) {
        return {
            cid: model.cid,
            name: model.name(),
            type: model.get("entitySubtype"),
            fullName: model.toText(),
            iconUrl: model.iconUrl({size: "small"})
        };
    },

    displayLoadingSection: function () {
        return !(this.collection && this.collection.loaded || this.collection.serverErrors);
    }
});