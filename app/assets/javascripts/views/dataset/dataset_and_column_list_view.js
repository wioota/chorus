chorus.views.DatasetAndColumnList = chorus.views.Base.extend({
    templateName: "dataset_and_column_list",
    constructorName: 'DatasetAndColumnList',

    subviews: {
        ".database_dataset_list": "datasetList",
        ".database_column_list": "columnList"
    },

    setup: function() {
        this.datasetList = new chorus.views.DatabaseDatasetSidebarList({ schema: this.model });
        this.columnList = new chorus.views.DatabaseColumnSidebarList({ schema: this.model });

        this.subscriptions.push(chorus.PageEvents.subscribe("datasetSelected", function(tableOrView) {
            this.$(".database_column_list").removeClass("hidden");
            this.$(".database_dataset_list").addClass("hidden");
        }, this));

        this.bindings.add(this.columnList, "back", function() {
            this.$("input.search").val("");
            this.$(".database_dataset_list").removeClass("hidden");
            this.$(".database_column_list").addClass("hidden");
            chorus.PageEvents.broadcast("dataset:back");
        });
    }
});
